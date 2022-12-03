import {ethers} from "hardhat"

async function main() {
    const bo = await ethers.getContractAt("BorrowOptimizer", "0x9E732e0102eD4006F4fa10C96aA4c97A52A23ed0")
    console.log(await bo.callStatic.previewBorrowTarget(100))
}

main().then((result) => {
    process.exit(0)
})