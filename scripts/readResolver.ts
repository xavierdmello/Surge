import {ethers} from "hardhat"

async function main() {
    const resolver = await ethers.getContractAt("BorrowOptimizerResolver", "0xc75a97b7AdeA6045e6e006f20b7b7E670556EE08")
    console.log(await resolver.callStatic.borrowTargetMiss())
}

main().then((result) => {
    process.exit(0)
})