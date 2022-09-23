import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "dotenv/config"
import { getEnabledCategories } from "trace_events"

// Coinmarketcap API key (for gas reporter)
const CMC_KEY = process.env.CMC_KEY!

const PRIVATE_KEY = process.env.PRIVATE_KEY!
const BOB = process.env.BOB!
const ALICE = process.env.ALICE!
const MOONRIVER_RPC = process.env.MOONRIVER_RPC!

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
      forking: { url: MOONRIVER_RPC, blockNumber: 2623000 },
    },
    moonbeam: { url: "https://rpc.api.moonbeam.network", accounts: [PRIVATE_KEY, BOB, ALICE], chainId: 1284 },
    moonriver: {
      url: MOONRIVER_RPC,
      accounts: [PRIVATE_KEY, BOB, ALICE],
      chainId: 1285,
    },
  },
  gasReporter: {
    enabled: false,
    noColors: true,
    outputFile: "gas-report.txt",
    currency: "USD",
    gasPriceApi: "https://api-moonriver.moonscan.io/api?module=proxy&action=eth_gasPrice",
    coinmarketcap: CMC_KEY,
    token: "MOVR",
  },
}

export default config
