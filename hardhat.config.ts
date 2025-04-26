import "@nomicfoundation/hardhat-toolbox";
import "hardhat-noir";
import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  mocha: {
    timeout: 100000000
  },
  solidity: {
    version: "0.8.29",
    settings: { optimizer: { enabled: true, runs: 100000000 } },
  },
  networks: {
    hardhat: {
      forking: process.env.MAINNET_RPC_URL ? {
        url: process.env.MAINNET_RPC_URL,
        blockNumber: 17000000,
      } : undefined,
    },
  },
  noir: {
    version: "1.0.0-beta.3",
    flavor: "ultra_plonk",
  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS) ? true : false,
  }
};

export default config;
