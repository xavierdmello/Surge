import { assert, expect } from "chai"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { ethers, network } from "hardhat"
import { config } from "../hardhat-helper-config"
import { mintFiatTokenV2 } from "../scripts/mint"
import { CompoundLens__factory } from "../typechain-types/factories/contracts/lenders/compound/Lens/CompoundLens.sol"
import { verify } from "../scripts/verify"

describe("Borrow Optimizer", function () {
  async function deployFixture() {
    const BorrowOptimizer = await ethers.getContractFactory("BorrowOptimizerTest")
    const [owner, bob, alice] = await ethers.getSigners()
    const cfg = config[network.name]

    const cAsset = await ethers.getContractAt("ICErc20", cfg.cAsset)
    const asset = await ethers.getContractAt("contracts/tokens/ERC20.sol:ERC20", await cAsset.underlying())
    const cWant = await ethers.getContractAt("ICErc20", cfg.cWant)
    const want = await ethers.getContractAt("contracts/tokens/ERC20.sol:ERC20", await cWant.underlying())
    const args = [cfg.cAsset, cfg.cWant, "Borrow Optimizer Test", "BOT"]
    const borrowOptimizer = await BorrowOptimizer.deploy(cfg.cAsset, cfg.cWant, "Borrow Optimizer Test", "BOT")
    await borrowOptimizer.deployTransaction.wait(10)
    verify(borrowOptimizer.address, args)

    await asset.approve(borrowOptimizer.address, ethers.constants.MaxUint256)
    return { BorrowOptimizer, borrowOptimizer, owner, bob, alice, cfg, cAsset, asset, want, cWant }
  }

  describe("Deployment", function () {
    it("Should deploy", async function () {
      const BorrowOptimizer = await ethers.getContractFactory("BorrowOptimizerTest")
      const [owner, bob, alice] = await ethers.getSigners()
      const cfg = config[network.name]

      const cAsset = await ethers.getContractAt("ICErc20", cfg.cAsset)
      const asset = await ethers.getContractAt("contracts/tokens/ERC20.sol:ERC20", await cAsset.underlying())
      const cWant = await ethers.getContractAt("ICErc20", cfg.cWant)
      const want = await ethers.getContractAt("contracts/tokens/ERC20.sol:ERC20", await cWant.underlying())
      const args = [cfg.cAsset, cfg.cWant, "Borrow Optimizer Test", "BOT"]
      const borrowOptimizer = await BorrowOptimizer.deploy(cfg.cAsset, cfg.cWant, "Borrow Optimizer Test", "BOT")
      await borrowOptimizer.deployTransaction.wait(5)
      await verify(borrowOptimizer.address, args)

      await asset.approve(borrowOptimizer.address, ethers.constants.MaxUint256)

      const BorrowOptimizerResolver = await ethers.getContractFactory("BorrowOptimizerResolver")
      const borrowOptimizerResolver = await BorrowOptimizerResolver.deploy(borrowOptimizer.address, 1)
      await borrowOptimizerResolver.deployTransaction.wait(5)
      await verify(borrowOptimizerResolver.address, [borrowOptimizer.address, 1])
    }).timeout(800000)

    it("Should have the right owner", async function () {
      const { borrowOptimizer, owner } = await loadFixture(deployFixture)

      assert.equal(await borrowOptimizer.owner(), owner.address)
    })
  }).timeout(800000)

  describe("Security", function () {
    it("Should not let non-owners call onlyOwner functions", async function () {
      let { borrowOptimizer, bob } = await loadFixture(deployFixture)
      await expect(borrowOptimizer.setSafetyMargin(20)).not.to.be.reverted
      borrowOptimizer = borrowOptimizer.connect(bob)
      await expect(borrowOptimizer.setSafetyMargin(20)).to.be.revertedWith("Ownable: caller is not the owner")
    })
  })

  describe("Deposits", function () {
    it("Should receive deposits", async function () {
      let { borrowOptimizer, owner, cAsset, asset, want } = await loadFixture(deployFixture)
      await mintFiatTokenV2(owner, asset.address, owner.address, ethers.utils.parseUnits("10", 6))
      await borrowOptimizer.deposit(BigInt(1e6), owner.address)

      console.log(`Vault Shares: ${await borrowOptimizer.balanceOf(owner.address)}`)

      let exchangeRate = await borrowOptimizer.exchangeRate()
      let lendBalance = await borrowOptimizer.callStatic.lendBalance()
      let borrowBalance = await borrowOptimizer.callStatic.borrowBalance()
      let borrowBalanceInLend = borrowBalance.mul(ethers.utils.parseUnits("1", await asset.decimals())).div(exchangeRate)

      console.log(`Lend: ${lendBalance}`)
      console.log(`Borrow: ${borrowBalanceInLend}`)
      console.log(`LTV: ${(await borrowOptimizer.ltv()).div(ethers.utils.parseUnits("1", 16))}%`)
      console.log(`Borrow Target: ${(await borrowOptimizer.borrowTargetMantissa()).div(ethers.utils.parseUnits("1", 16))}%`)
      console.log(`Borrow Target (Tokens): ${await borrowOptimizer.callStatic.borrowTarget()}`)
      console.log(`Borrow Balance: ${borrowBalance}`)
      console.log(await want.balanceOf(borrowOptimizer.address))
      console.log(`Exchange Rate: ${exchangeRate}`)
      console.log(`Total Assets: ${await borrowOptimizer.callStatic.totalAssets()}`)

      let debt = await borrowOptimizer.callStatic.debt()
      let sv = await borrowOptimizer.stakedValueInAsset()

      console.log(`Staked value in assset: ${sv}`)
      console.log(`Debt: ${debt}`)
      console.log(`Decficit: ${debt.sub(sv)}`)
    })
  })
})
