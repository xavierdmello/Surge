import { assert, expect } from "chai"
import { config } from "../hardhat-helper-config"
import { CErc20, Comptroller, ERC20, PriceOracle, SrLdoErc20Comp, FaucetToken } from "../typechain-types"
import { ethers, network } from "hardhat"
import { BigNumber } from "ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Log, TransactionReceipt } from "@ethersproject/providers"

describe("Core", () => {
  describe("SrLdoErc20Comp", () => {
    const DEPOSIT_AMOUNT = BigNumber.from(1).mul(BigNumber.from(10).pow(BigNumber.from(18)))

    let asset: FaucetToken
    let borrow: ERC20
    let cAsset: CErc20
    let cBorrow: CErc20
    let priceOracle: PriceOracle
    let comptroller: Comptroller
    let vault: SrLdoErc20Comp
    let account: SignerWithAddress

    beforeEach(async () => {
      account = (await ethers.getSigners())[0]
      cAsset = await ethers.getContractAt("CErc20", config[network.name].cAsset)
      cBorrow = await ethers.getContractAt("CErc20", config[network.name].cBorrow)
      vault = await (
        await ethers.getContractFactory("SrLdoErc20Comp")
      ).deploy(cAsset.address, cBorrow.address, "Surge Vault", "srLdoErc20Comp")
      await vault.deployed()
      asset = await ethers.getContractAt("FaucetToken", await cAsset.underlying())
      borrow = await ethers.getContractAt("ERC20", await cBorrow.underlying())
      comptroller = await ethers.getContractAt("Comptroller", await cAsset.comptroller())
      priceOracle = await ethers.getContractAt("PriceOracle", await comptroller.oracle())

      // Mint USDC
      if (network.name == "hardhat") {
        await asset.allocateTo(account.address, DEPOSIT_AMOUNT)
      }
    })

    it("Should deploy & have correct underlying tokens", async () => {
      assert.equal(await vault.asset(), asset.address)
      assert.equal(await vault.borrow(), borrow.address)
    })

    it("Should take deposits", async () => {
      let tx = await asset.approve(vault.address, DEPOSIT_AMOUNT)
      await tx.wait(1)

      tx = await vault.deposit(DEPOSIT_AMOUNT)
      await tx.wait(1)

      expect(
        (await vault.balanceOf(account.address)).mul(await vault.exchangeRate()).div(ethers.utils.parseEther("1"))
      ).to.equal(await cAsset.balanceOf(vault.address))
    }).timeout(100000)

    it("Should take multiple deposits from different accounts", async () => {
      // TODO: Make hardcoded 18 decimals dynamic
      const accounts = await ethers.getSigners()
      const bob = accounts[1]
      const alice = accounts[2]
      const BOB_DEPOSIT_AMOUNT = BigNumber.from(2).mul(BigNumber.from(10).pow(BigNumber.from(18)))
      const ALICE_DEPOSIT_AMOUNT = BigNumber.from(3).mul(BigNumber.from(10).pow(BigNumber.from(18)))

      // Mint USDC
      if (network.name == "hardhat") {
        await asset.allocateTo(bob.address, BOB_DEPOSIT_AMOUNT)
        await asset.allocateTo(alice.address, ALICE_DEPOSIT_AMOUNT)
      }
      console.log("First!!")

      // Deposit
      let tx = await asset.approve(vault.address, DEPOSIT_AMOUNT)
      tx.wait(1)
      console.log("Allowance: " + (await asset.allowance(account.address, vault.address)))
      tx = await vault.deposit(DEPOSIT_AMOUNT)
      tx.wait(1)
      console.log("FIRST DONE!")
      asset = asset.connect(bob)
      vault = vault.connect(bob)
      tx = await asset.approve(vault.address, BOB_DEPOSIT_AMOUNT)
      tx.wait(1)
      tx = await vault.deposit(BOB_DEPOSIT_AMOUNT)
      tx.wait(1)
      console.log("SECOND DONE!")
      asset = asset.connect(alice)
      vault = vault.connect(alice)
      tx = await asset.approve(vault.address, ALICE_DEPOSIT_AMOUNT)
      tx.wait(1)
      tx = await vault.deposit(ALICE_DEPOSIT_AMOUNT)
      tx.wait(1)
      console.log("THIRD DONE!")

      // Expect the borrow amount to be slightly higher than the total supply.
      // While the vault is aiming to be spot on each time it deposits,
      // there will still be a little intrest earned from compound.
      // TODO: Add price oracle calculation into the mix
      const borrowTargetMantissa = await vault.borrowTargetMantissa()
      const totalDeposits = DEPOSIT_AMOUNT.add(BOB_DEPOSIT_AMOUNT).add(ALICE_DEPOSIT_AMOUNT)
      expect(await borrow.balanceOf(vault.address)).to.be.closeTo(
        totalDeposits.mul(borrowTargetMantissa).div(ethers.utils.parseEther("1")),
        BigNumber.from(10).pow(BigNumber.from(Math.round((await borrow.decimals()) * 0.7)))
      )

      // Make sure total shares * exchangeRate = total cTokens
      expect(
        (await vault.totalSupply()).mul(await vault.exchangeRate()).div(ethers.utils.parseEther("1"))
      ).to.be.closeTo(await cAsset.balanceOf(vault.address), BigNumber.from(1))
    }).timeout(200000)

    it("Should take multiple deposits from different and same accounts", async () => {})
  })
})
