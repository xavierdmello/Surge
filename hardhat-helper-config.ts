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
	hardhat: {
		cAsset: "0x18f324E21846F1C21F4fbF8228705B17897eF15A", // mUSDC
		cBorrow: "0xa28C4680058f4A73f6172A6ed23C9E624E443CFB", // mETH (for the time being)
	},
}
