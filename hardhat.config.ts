import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import { HardhatUserConfig } from "hardhat/config";

import dotenv from "dotenv";
dotenv.config();

const {
  TESTNET_PRIVATE_KEY,
  ALCHEMY_RINKEBY_API_KEY,
  ETHERSCAN_API_KEY,
} = process.env;

const config: HardhatUserConfig & { etherscan: { apiKey?: string } } = {
  solidity: {
    version: "0.8.7",
    settings: {
      // https://blog.soliditylang.org/2020/11/04/solidity-ama-1-recap/
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_RINKEBY_API_KEY}`,
      accounts: [TESTNET_PRIVATE_KEY || ""],
    },
    hardhat: {
      chainId: 31337
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};

export default config;