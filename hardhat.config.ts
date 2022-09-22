import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "dotenv/config"
import { getEnabledCategories } from "trace_events"

const PRIVATE_KEY = process.env.PRIVATE_KEY!
const BOB = process.env.BOB!
const ALICE = process.env.ALICE!

const BSC_TEST_RPC = process.env.BSC_TEST_RPC!
const GOERLI_RPC = process.env.GOERLI_RPC!

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

        // // BSC_TEST
        // url: BSC_TEST_RPC,

        // Goerli
        url: GOERLI_RPC,
        blockNumber: 7639220,

      },
      
    },
    bsc: { url: "https://bsc-dataseed.binance.org/", accounts: [PRIVATE_KEY, BOB, ALICE], chainId: 56 },
    bsc_test: { url: BSC_TEST_RPC, accounts: [PRIVATE_KEY, BOB, ALICE], chainId: 97 },
    goerli: { url: GOERLI_RPC, accounts: [PRIVATE_KEY, BOB, ALICE], chainId: 5 },
  },
  gasReporter: {
    enabled: false,
    noColors: true,
    outputFile: "gas-report.txt",
  },
}

export default config
