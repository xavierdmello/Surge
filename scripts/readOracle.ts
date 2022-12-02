import { ethers } from "hardhat"

async function main() {
  const oracle = await ethers.getContractAt("IPriceOracle", "0x892bE716Dcf0A6199677F355f45ba8CC123BAF60")
  console.log(await oracle.price("USDC"))
}

main().then((result) => {
  process.exit(0)
})
