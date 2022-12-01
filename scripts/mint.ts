import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BigNumber } from "ethers"
import { ethers, network } from "hardhat"
import { config } from "../hardhat-helper-config"

export async function mintFiatTokenV2(funder: SignerWithAddress, token: string, to: string, amount: BigNumber) {
  // Fund fiatTokenOwner with gas
  const fiatTokenOwner = await ethers.getImpersonatedSigner(config[network.name].mintAccount)
  await funder.sendTransaction({ to: fiatTokenOwner.address, value: ethers.utils.parseEther("1") })

  // Set minter to fiatTokenOwner
  let fiatToken = await ethers.getContractAt("IFiatTokenV2", token)
  fiatToken = fiatToken.connect(fiatTokenOwner)
  await fiatToken.updateMasterMinter(fiatTokenOwner.address)
  await fiatToken.configureMinter(fiatTokenOwner.address, ethers.constants.MaxUint256)

  // Mint tokens
  await fiatToken.mint(to, amount)
}
