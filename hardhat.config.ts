import {HardhatUserConfig} from "hardhat/config";
import {getNetwork} from '@ethersproject/networks'
import "hardhat-abi-exporter";
import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import '@typechain/hardhat'
import '@nomicfoundation/hardhat-ethers'
import '@nomicfoundation/hardhat-chai-matchers'
import 'dotenv/config'
import "@nomicfoundation/hardhat-verify";


const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x1111111111111111111111111111111111111111111111111111111111111111"
const PRIVATE_KEY_ARR = JSON.parse(process.env.PRIVATE_KEY_ARR || "") || [""];

const config: HardhatUserConfig = {
    defaultNetwork: 'hardhat', //fat,hardhat,sepolia
    networks: {
        hardhat: {
            chainId: 1337,
            allowUnlimitedContractSize: false,
            hardfork: 'berlin',
            mining: {
                auto: true,
                interval: 50000,
            },
            accounts: {
                mnemonic: "test test test test test test test test test test test junk",
                count: 400 // 这里设置生成账户的数量
            }
        },
        bnbtest: {
            url: 'https://bsc-testnet.nodereal.io/v1/6e5dbb7a28984b99b06e0062e3cd14ed',
            chainId: 97,
            accounts: PRIVATE_KEY_ARR
        },
        bnbmain: {
            url: 'https://bsc-pokt.nodies.app',
            chainId: getNetwork('bnb').chainId,
            accounts: {
                mnemonic: "furnace urban bless grass globe clerk monster zebra pottery comic estate flavor",
                count: 21
            }
        },
    },
    etherscan: {
        apiKey: "E512UG8BRFYAGAFGV1IXES9Y93QTXU4JJD"
    },
    paths: {
        sources: './contracts/',
        tests: './test',
        cache: './cache',
        artifacts: './artifacts',
    },
    abiExporter: {
        path: './abi',
        runOnCompile: true,
        clear: true,
        spacing: 2
    },
    solidity: {
        compilers: [
            {
                version: '0.8.24',
                settings: {optimizer: {enabled: true, runs: 200}},
            }
        ],
    },
    gasReporter: {
        enabled: true,
        excludeContracts: ['test*', '@openzeppelin*'],
    },
    contractSizer: {
        alphaSort: true,
        runOnCompile: true,
        disambiguatePaths: false,
        // only: ['AuctionUpgradeable', 'DutchAuctionUpgradeable', 'EnglishAuctionUpgradeable', 'FixedPriceSellUpgradeable'],
    },
    typechain: {
        outDir: 'typechain-types',
        target: 'ethers-v6',
        alwaysGenerateOverloads: false, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
        externalArtifacts: ['externalArtifacts/*.json'], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
        dontOverrideCompile: false // defaults to false
    },
};

export default config;
