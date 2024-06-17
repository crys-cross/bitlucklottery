import { ethers } from "hardhat";

export interface NetworkConfigItem {
  name?: string; // network name here
  vrfCoordinatorV2?: string; // vrf arguments starts here, change coordinator address based one the network
  keyHash?: string; // change based on the network
  subscriptionId?: string; // change based on the network
  callbackGasLimit?: string; // change based on the network
  lotteryEntranceFee?: string; // app payment fee, change this base on user/dev preference
  ethUsdPriceFeed?: string; // pricefeed based on the network
}

export interface networkConfigInfo {
  [key: number]: NetworkConfigItem;
}

export const networkConfig: networkConfigInfo = {
  // Price Feed Address, values can be obtained at https://docs.chain.link/docs/reference-contracts
  // Default one is ETH/USD contract on Kovan
  // dafault: {
  //     name: "hardhat",
  //     ethUsdPriceFeed: "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e",
  //     // vrfCoordinatorV2: "0x6168499c0cFfCaCD319c818142124B7A15E857ab",
  //     // entranceFee: ethers.utils.parseEther("0.01"),
  //     gasLane: "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
  //     // subscriptionId: "6727",
  //     callbackGasLimit: "500000", // 500,000 gas
  //     mintFee: "10000000000000000", // 0.01 ETH
  //     // interval: "30",
  // },
  31337: {
    name: "hardhat",
    vrfCoordinatorV2: "",
    keyHash: "",
    subscriptionId: "",
    callbackGasLimit: "",
    lotteryEntranceFee: "10000000000000000", // 0.01 ETH
    ethUsdPriceFeed: "",
  },
  11155111: {
    name: "sepolia",
    vrfCoordinatorV2: "",
    keyHash: "",
    subscriptionId: "",
    callbackGasLimit: "",
    lotteryEntranceFee: ethers.parseEther("0.01").toString(),
    ethUsdPriceFeed: "",
  },
};
