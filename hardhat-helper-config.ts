// Addresses for important contracts on each network
interface HelperConfig {
  [network: string]: {
    cAsset: string
    cBorrow: string
  }
}

export const config: HelperConfig = {
  moonbase: {
    cAsset: "0x18f324E21846F1C21F4fbF8228705B17897eF15A", // mUSDC
    cBorrow: "0xa28C4680058f4A73f6172A6ed23C9E624E443CFB", // mETH (for the time being)
  },
  bsc_test: {
    cAsset: "0xD5C4C2e2facBEB59D0216D0595d63FcDc6F9A1a7", // vUSDC
    cBorrow: "0x74469281310195A04840Daf6EdF576F559a3dE80", // vSXP (for the time being)
  },
  hardhat: {
    // Moonbase:
    // cAsset: "0x18f324E21846F1C21F4fbF8228705B17897eF15A", // mUSDC
    // cBorrow: "0xa28C4680058f4A73f6172A6ed23C9E624E443CFB", // mETH (for the time being)

    // BSC Testnet:
    cAsset: "0xD5C4C2e2facBEB59D0216D0595d63FcDc6F9A1a7", // vUSDC
    cBorrow: "0x74469281310195A04840Daf6EdF576F559a3dE80", // vSXP (for the time being)
  },
}
