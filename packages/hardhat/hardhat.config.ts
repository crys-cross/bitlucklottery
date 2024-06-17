import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

// Chain URL
const MAINNET_RPC_URL =
  process.env.MAINNET_RPC_URL ||
  process.env.ALCHEMY_MAINNET_RPC_URL ||
  "https://eth-mainnet.alchemyapi.io/v2/your-api-key";
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const ARBITRUMSEPOLIA_RPC_URL = process.env.MUMBAI_RPC_URL;
const AMOY_RPC_URL = process.env.MUMBAI_RPC_URL;
const PRIVATE_KEY1 = process.env.PRIVATE_KEY1 || "";
const PRIVATE_KEY2 = process.env.PRIVATE_KEY2 || "";

//Optional
const FORKING_BLOCK_NUMBER = process.env.FORKING_BLOCK_NUMBER;

// API Keys
const ETHERSCAN_API_KEY =
  process.env.ETHERSCAN_API_KEY || "Your etherscan API key";
const POLYGONSCAN_API_KEY =
  process.env.POLYGONSCAN_API_KEY || "Your polygonscan API key";
const SNOWTRACE_API_KEY =
  process.env.SNOWTRACE_API_KEY || "Your snowtrace API key";
const FTMSCAN_API_KEY = process.env.FTMSCAN_API_KEY || "Your ftmscan API key";
const REPORT_GAS = process.env.REPORT_GAS || false;
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      { version: "0.8.24" },
      { version: "0.8.8" },
      { version: "0.6.6" },
    ],
  },
  networks: {
    hardhat: {
      // // If you want to do some forking, uncomment this
      // forking: {
      //   url: MAINNET_RPC_URL
      // }
      hardfork: "merge",
      // If you want to do some forking set `enabled` to true
      forking: {
        url: MAINNET_RPC_URL,
        blockNumber: Number(FORKING_BLOCK_NUMBER),
        enabled: false,
      },
      chainId: 31337,
    },
    localhost: {
      chainId: 31337,
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      chainId: 11155111,
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      chainId: 1,
    },
    bnbtest: {
      url: "https://bsc-testnet.blockpi.network/v1/rpc/public" || "",
      accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
      chainId: 4002,
    },
    arbitrum_sepolia: {
      url: ARBITRUMSEPOLIA_RPC_URL || "",
      accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
      chainId: 4002,
    },
    fujitest: {
      url: "https://endpoints.omniatech.io/v1/avax/fuji/public" || "",
      accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
      chainId: 43113,
    },
    amoytest: {
      url: AMOY_RPC_URL || "",
      accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
      chainId: 80001,
    },
    // optimismkovan: {
    //   url: "https://kovan.optimism.io/" || "",
    //   accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
    //   chainId: 69,
    // },
    // blasttest: {
    //   url: "https://data-seed-prebsc-1-s1.binance.org:8545" || "",
    //   accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
    //   chainId: 97,
    // },
    // basetest: {
    //   url: "https://api.baobab.klaytn.net:8651" || "",
    //   accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
    //   chainId: 1001,
    // },
    // metisstardust: {
    //   url: "https://stardust.metis.io/?owner=588" || "",
    //   accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
    //   chainId: 588,
    // },
    // evmostest: {
    //   url: "https://eth.bd.evmos.dev:8545" || "",
    //   accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
    //   chainId: 9000,
    // },
  },
  gasReporter: {
    enabled: true,
    outputFile: "gas-report.txt",
    noColors: true,
    currency: "USD",
    coinmarketcap: COINMARKETCAP_API_KEY,
    token: "ETH",
  },
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY!,
      ftmTestnet: FTMSCAN_API_KEY,
      avalancheFujiTestnet: SNOWTRACE_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
    },
  },
  // namedAccounts: {
  //   deployer: {
  //     default: 0,
  //   },
  //   user: {
  //     default: 1,
  //   },
  // },
  // mocha: {
  //     timeout: 40000, //4000 seconds
  // },
};

export default config;
