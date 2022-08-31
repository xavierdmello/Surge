import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "dotenv/config"

const PRIVATE_KEY = process.env.PRIVATE_KEY!

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.10",

		settings: {
			optimizer: {
				enabled: true,
				runs: 500,
			},
		},
	},

	defaultNetwork: "moonbase",

	networks: {
		moonbase: { url: "https://moonbase-alpha.public.blastapi.io", accounts: [PRIVATE_KEY], chainId: 1287 },
	},
}

export default config
