import { assert, expect } from "chai"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { ethers, network } from "hardhat"
import { config } from "../hardhat-helper-config"
import { FakeContract, smock } from "@defi-wonderland/smock"

describe("Borrow Optimizer", function () {
  async function deployFixture() {
    const BorrowOptimizer = await ethers.getContractFactory("BorrowOptimizerTest")
    const [owner, bob, alice] = await ethers.getSigners()
    const cfg = config[network.name]
    const borrowOptimizer = await BorrowOptimizer.deploy(cfg.cAsset, cfg.cWant, "Borrow Optimizer Test", "BOT")
    await borrowOptimizer.deployed()
    return { BorrowOptimizer, borrowOptimizer, owner, bob, alice, cfg }
  }

  describe("Deployment", function () {
    it("Should deploy", async function () {
      const { borrowOptimizer, cfg } = await loadFixture(deployFixture)

      // Check immutable variables that should return if everything deployed correctly
      assert.equal(await borrowOptimizer.cAsset(), cfg.cAsset)
      assert.equal(await borrowOptimizer.cWant(), cfg.cWant)
    })

    it("Should have the right owner", async function () {
      const { borrowOptimizer, owner } = await loadFixture(deployFixture)

      assert.equal(await borrowOptimizer.owner(), owner.address)
    })
  })

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
        let { borrowOptimizer, owner } = await loadFixture(deployFixture)
        await borrowOptimizer.deposit()
    })
  })
})
