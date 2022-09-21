import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "dotenv/config"
import { getEnabledCategories } from "trace_events"

const PRIVATE_KEY = process.env.PRIVATE_KEY!
const BOB = process.env.BOB!
const ALICE = process.env.ALICE!

const BSC_TEST_RPC= process.env.BSC_TEST_RPC!

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

  defaultNetwork: "hardhat",

  networks: {
    moonbase: { url: "https://rpc.api.moonbase.moonbeam.network", accounts: [PRIVATE_KEY, BOB, ALICE], chainId: 1287 },
    hardhat: {
      forking: {
        // // Moonbase:
        // url: "https://rpc.api.moonbase.moonbeam.network",
        // blockNumber: 2750000,

        // // BSC
        // url: "https://bsc-dataseed.binance.org/",
        // blockNumber: 21530000,

        // BSC_TEST
        url: BSC_TEST_RPC,
      },
    },
    bsc: { url: "https://bsc-dataseed.binance.org/", accounts: [PRIVATE_KEY, BOB, ALICE], chainId: 56 },
    bsc_test: { url: BSC_TEST_RPC, accounts: [PRIVATE_KEY, BOB, ALICE], chainId: 97 },
  },
  gasReporter: {
    enabled: true,
    noColors: true,
    outputFile: "gas-report.txt",
  },
}

export default config
