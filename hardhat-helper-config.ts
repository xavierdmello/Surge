interface HelperConfig {
  [network: string]: {
    cAsset: string
    cWant: string
    stWant: string
    rewardTokenPath: string[]
    rewardEthPath: string[]
    stBorrowPath: string[]
    compoundPath: string[]
    router: string
    mintAccount: string
  }
}

// Addresses for important contracts on each network
export const config: HelperConfig = {
  hardhat: {
    // Moonriver
    cAsset: "0x39AA39c021dfbaE8faC545936693aC917d5E7563", // cUSDC
    cWant: "0xFAce851a4921ce59e912d19329929CE6da6EB0c7", // cLINK
    stWant: "0x3bfd113ad0329a7994a681236323fb16E16790e3", // wstKSM
    rewardTokenPath: [
      "0xBb8d88bcD9749636BC4D2bE22aaC4Bb3B01A58F1",
      "0x98878B06940aE243284CA214f92Bb71a2b032B8A",
      "0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D",
    ], // MFAM -> WMOVR -> USDC
    rewardEthPath: ["0x98878b06940ae243284ca214f92bb71a2b032b8a", "0xe3f5a90f9cb311505cd691a46596599aa1a0ad7d"], // WMOVR -> USDC
    stBorrowPath: ["0x3bfd113ad0329a7994a681236323fb16e16790e3", "0xFfFFfFff1FcaCBd218EDc0EbA20Fc2308C778080"], // wstKSM -> xcKSM
    compoundPath: [
      "0x3bfd113ad0329a7994a681236323fb16e16790e3",
      "0xFfFFfFff1FcaCBd218EDc0EbA20Fc2308C778080",
      "0x98878b06940ae243284ca214f92bb71a2b032b8a",
      "0xe3f5a90f9cb311505cd691a46596599aa1a0ad7d",
    ], // wstKSM -> xcKSM -> WMOVR -> USDC
    router: "0xAA30eF758139ae4a7f798112902Bf6d65612045f",
    mintAccount: "0xFcb19e6a322b27c06842A71e8c725399f049AE3a",
  },
  moonriver: {
    cAsset: "0xd0670AEe3698F66e2D4dAf071EB9c690d978BFA8", // mUSDC
    cWant: "0xa0D116513Bd0B8f3F14e6Ea41556c6Ec34688e0f", // mxcKSM
    stWant: "0x3bfd113ad0329a7994a681236323fb16E16790e3", // wstKSM
    rewardTokenPath: [
      "0xBb8d88bcD9749636BC4D2bE22aaC4Bb3B01A58F1",
      "0x98878B06940aE243284CA214f92Bb71a2b032B8A",
      "0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D",
    ], // MFAM -> WMOVR -> USDC
    rewardEthPath: ["0x98878b06940ae243284ca214f92bb71a2b032b8a", "0xe3f5a90f9cb311505cd691a46596599aa1a0ad7d"], // WMOVR -> USDC
    stBorrowPath: ["0x3bfd113ad0329a7994a681236323fb16e16790e3", "0xFfFFfFff1FcaCBd218EDc0EbA20Fc2308C778080"], // wstKSM -> xcKSM
    compoundPath: [
      "0x3bfd113ad0329a7994a681236323fb16e16790e3",
      "0xFfFFfFff1FcaCBd218EDc0EbA20Fc2308C778080",
      "0x98878b06940ae243284ca214f92bb71a2b032b8a",
      "0xe3f5a90f9cb311505cd691a46596599aa1a0ad7d",
    ], // wstKSM -> xcKSM -> WMOVR -> USDC
    router: "0xAA30eF758139ae4a7f798112902Bf6d65612045f",
    mintAccount: "0x10c6b61DbF44a083Aec3780aCF769C77BE747E23",
  },
  ethereum: {
    cAsset: "0x39AA39c021dfbaE8faC545936693aC917d5E7563", // cUSDC
    cWant: "0xC11b1268C1A384e55C48c2391d8d480264A3A7F4", // cWBTC
    stWant: "0x3bfd113ad0329a7994a681236323fb16E16790e3", // wstKSM
    rewardTokenPath: [
      "0xBb8d88bcD9749636BC4D2bE22aaC4Bb3B01A58F1",
      "0x98878B06940aE243284CA214f92Bb71a2b032B8A",
      "0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D",
    ], // MFAM -> WMOVR -> USDC
    rewardEthPath: ["", ""], // WMOVR -> USDC
    stBorrowPath: ["", ""], // wstKSM -> xcKSM
    compoundPath: ["", "", "", ""],
    router: "",
    mintAccount: "",
  },
  goerli: {
    cAsset: "0x73506770799Eb04befb5AaE4734e58C2C624F493", // cUSDC
    cWant: "0x0fF50a12759b081Bb657ADaCf712C52bb015F1Cd", // cCOMP
    stWant: "0x3bfd113ad0329a7994a681236323fb16E16790e3", // wstKSM
    rewardTokenPath: [
      "0xBb8d88bcD9749636BC4D2bE22aaC4Bb3B01A58F1",
      "0x98878B06940aE243284CA214f92Bb71a2b032B8A",
      "0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D",
    ], // MFAM -> WMOVR -> USDC
    rewardEthPath: ["", ""], // WMOVR -> USDC
    stBorrowPath: ["", ""], // wstKSM -> xcKSM
    compoundPath: ["", "", "", ""],
    router: "",
    mintAccount: "",
  },
}
