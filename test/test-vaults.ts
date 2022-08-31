import { assert, expect } from "chai"
import { config } from "../hardhat-helper-config"
import { CErc20, Comptroller, ERC20, PriceOracle, SLidoCompVault } from "../typechain-types"
import { ethers, network } from "hardhat"
import { BigNumber } from "ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"

describe("Vaults", () => {

	describe("SLidoCompVault", () => {
        const DEPOSIT_AMOUNT = BigNumber.from(1).mul(BigNumber.from(10).pow(BigNumber.from(18)))

		let asset: ERC20
		let borrow: ERC20
		let cAsset: CErc20
		let cBorrow: CErc20
		let priceOracle: PriceOracle
		let comptroller: Comptroller
		let vault: SLidoCompVault
        let account: SignerWithAddress

		beforeEach(async () => {
            account = (await ethers.getSigners())[0]
			cAsset = await ethers.getContractAt("CErc20", config[network.name].cAsset)
			cBorrow = await ethers.getContractAt("CErc20", config[network.name].cBorrow)
			vault = await (
				await ethers.getContractFactory("SLidoCompVault")
			).deploy(cAsset.address, cBorrow.address, "SLidoCompVault", "SLCV")
            asset = await ethers.getContractAt("ERC20", await cAsset.underlying())
            borrow = await ethers.getContractAt("ERC20", await cBorrow.underlying())
            comptroller = await ethers.getContractAt("Comptroller", await cAsset.comptroller())
            priceOracle = await ethers.getContractAt("PriceOracle", await comptroller.oracle())
		})

        it("Should deploy & have correct underlying tokens", async () => {
            assert.equal(await vault.asset(), asset.address)
            assert.equal(await vault.borrow(), borrow.address)
        })

        it("Should take deposits", async () => {
            await asset.approve(vault.address, DEPOSIT_AMOUNT)
            await vault.deposit(DEPOSIT_AMOUNT,account.address )

            console.log((await vault.depositLiquidity()).toString())
            console.log((await vault.totalSupply()).toString())
            const tx = await vault.totalAssets()
            const tx2 = tx.wait(1)
            console.log(tx.data)

        })
	})
})
