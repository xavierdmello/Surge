import { assert, expect } from "chai"
import { CErc20, ERC20, SrLdoErc20Comp, PriceOracle, Moontroller } from "../typechain-types"
import { config } from "../hardhat-helper-config"
import { ethers, network } from "hardhat"
import { mine } from "@nomicfoundation/hardhat-network-helpers"
import { ERC20MintMod } from "../typechain-types/contracts/ERC20MintMod"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { verify } from "../scripts/verify"
import { text } from "stream/consumers"

let vault: SrLdoErc20Comp
let asset: ERC20MintMod
let borrow: ERC20
let cAsset: CErc20
let cBorrow: CErc20
let priceOracle: PriceOracle
let comptroller: Moontroller
let account: SignerWithAddress
let bob: SignerWithAddress
let alice: SignerWithAddress

const B = BigInt
const DEPOSIT_AMOUNT = B(1) * B(10) ** B(6)
const BOB_DEPOSIT_AMOUNT = B(2) * B(10) ** B(6)
const ALICE_DEPOSIT_AMOUNT = B(3) * B(10) ** B(6)

// "Hack" to deploy contracts only once
describe("Deploy", () => {
  it("Should deploy vault", async () => {
    vault = await (
      await ethers.getContractFactory("SrLdoErc20Comp")
    ).deploy(
      config[network.name].cAsset,
      config[network.name].cBorrow,
      config[network.name].stBorrow,
      config[network.name].rewardTokenPath,
      config[network.name].rewardEthPath,
      config[network.name].stBorrowPath,
      config[network.name].router,
      "Surge Vault",
      "srLdoErc20Comp"
    )
    cAsset = await ethers.getContractAt("CErc20", config[network.name].cAsset)
    cBorrow = await ethers.getContractAt("CErc20", config[network.name].cBorrow)
    asset = await ethers.getContractAt("ERC20MintMod", await cAsset.underlying())
    borrow = await ethers.getContractAt("ERC20", await cBorrow.underlying())
    comptroller = await ethers.getContractAt("Moontroller", await cAsset.comptroller())
    priceOracle = await ethers.getContractAt("PriceOracle", await comptroller.oracle())

    const accounts = await ethers.getSigners()
    account = accounts[0]
    bob = accounts[1]
    alice = accounts[2]

    console.log("Waiting for confirmations...")
    await vault.deployTransaction.wait(2)
    console.log("Starting verification...")

    // Verify contract
    await verify(vault.address, [
      config[network.name].cAsset,
      config[network.name].cBorrow,
      config[network.name].stBorrow,
      config[network.name].rewardTokenPath,
      config[network.name].rewardEthPath,
      config[network.name].stBorrowPath,
      config[network.name].router,
      "Surge Vault",
      "srLdoErc20Comp",
    ])
  }).timeout(500000)
})
;(network.name == "hardhat" ? describe : describe.skip)("Mint", () => {
  // Multichain tokens only (sorry!)
  it("Should mint tokens", async () => {
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [config[network.name].mintAccount],
    })
    const imposter = await ethers.getSigner(config[network.name].mintAccount)
    asset = asset.connect(imposter)
    await asset.mint(account.address, DEPOSIT_AMOUNT * B(20))
    await asset.mint(bob.address, DEPOSIT_AMOUNT * B(20))
    await asset.mint(alice.address, DEPOSIT_AMOUNT * B(20))
    asset = asset.connect(account)
  })
})

describe("Core", () => {
  beforeEach(async () => {})

  it("Should deposit tokens ", async () => {
    await asset.approve(vault.address, DEPOSIT_AMOUNT)
    await vault.deposit(DEPOSIT_AMOUNT)

    console.log("Account shares balance: " + (await vault.balanceOf(account.address)))
    console.log("cAsset Balance of vault: " + (await cAsset.balanceOf(vault.address)))
    console.log("borrow Balance of vault: " + (await borrow.balanceOf(vault.address)))

    await network.provider.send("evm_increaseTime", [3600 * 3600 * 10])
    await mine(100000)

    await vault.claimMoonwellRewards()

    console.log("cAsset Balance of vault: " + (await cAsset.balanceOf(vault.address)))

    await vault.rebalance()
    console.log("borrow Balance of vault: " + (await borrow.balanceOf(vault.address)))
  })
})
