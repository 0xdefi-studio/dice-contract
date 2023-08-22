import { HardhatUserConfig } from "hardhat/config";
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import { resolve } from "path";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const HARDHAT_CHAIN_ID = process.env.HARDHAT_CHAIN_ID
    ? parseInt(process.env.HARDHAT_CHAIN_ID)
    : 31337;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },
  networks: {
    hardhat: {
    },
    localhost: {
      chainId: HARDHAT_CHAIN_ID,
      url: "http://127.0.0.1:8545",
      accounts: ["0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"]
   },
    mantle: {
      url: "https://rpc.mantle.xyz/",
      accounts: {
        path: "m/44'/60'/0'/0",
        // mainnet: 2
        // testnet: 0
        initialIndex: 2,
        mnemonic: process.env.MANTLE_MNEMONIC,
      },
    },
    goerli: {
      chainId: 5,
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_API_KEY}`,
      accounts: {
          mnemonic: process.env.MANTLE_MNEMONIC,
      },
  },
  },
};

export default config;
