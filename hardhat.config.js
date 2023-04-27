/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("ethers");

module.exports = {
  solidity: "0.8.17",
  paths: {
    artifacts: "./src/artifacts",
  },
};
