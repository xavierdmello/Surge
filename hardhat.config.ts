import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "dotenv/config"
import { getEnabledCategories } from "trace_events"

const PRIVATE_KEY = process.env.PRIVATE_KEY!
const BOB = process.env.BOB!
const ALICE = process.env.ALICE!

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
		moonbase: { url: "https://rpc.api.moonbase.moonbeam.network", accounts: [PRIVATE_KEY, BOB, ALICE], chainId: 1287 },
		hardhat: {
			forking: {
				url: "https://rpc.api.moonbase.moonbeam.network",
				blockNumber: 2750000,
			},
		},
	},
	gasReporter: {
		enabled: true,
		noColors: true,
		outputFile: "gas-report.txt",
	},
}

export default config
