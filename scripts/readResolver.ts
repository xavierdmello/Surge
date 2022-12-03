import {ethers} from "hardhat"

async function main() {
    const resolver = await ethers.getContractAt("BorrowOptimizerResolver", "0xBfA4994c5412f05021b3Cef6a2108cf8Bb4f9c19")
    console.log(await resolver.callStatic.currentLtv())
    console.log(await resolver.callStatic.shouldRebalance())
}

main().then((result) => {
    process.exit(0)
})