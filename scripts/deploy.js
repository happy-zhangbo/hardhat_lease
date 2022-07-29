// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const fs = require('fs');
const hre = require("hardhat");

function copyFile(src, dist) {
  fs.writeFileSync(dist, fs.readFileSync(src));
}

async function main() {
  const NFTs = await ethers.getContractFactory("GameItems");
  gameItems = await NFTs.deploy();
  console.log(`NFTs：${gameItems.address}`);
  copyFile('./artifacts/contracts/GameNFTs/GameItems.sol/GameItems.json', './src/abi/GameItems.json');
  let content = `VUE_APP_NFT_CONTRACT=${gameItems.address}\n`;

  const Gold = await ethers.getContractFactory("GoldToken");
  goldCoin = await Gold.deploy("Gold","G");
  console.log(`Gold Coin: ${goldCoin.address}`);
  copyFile('./artifacts/contracts/GoldCoin/GoldToken.sol/GoldToken.json', './src/abi/GoldToken.json');
  content += `VUE_APP_GOLD_CONTRACT=${goldCoin.address}\n`;

  const LeaseNFT = await ethers.getContractFactory("LeaseNFT");
  leaseNft = await LeaseNFT.deploy(gameItems.address, goldCoin.address);
  console.log(`LeaseNFT: ${leaseNft.address}`);
  copyFile('./artifacts/contracts/LeaseNFT.sol/LeaseNFT.json', './src/abi/LeaseNFT.json');
  content += `VUE_APP_LEASE_CONTRACT=${leaseNft.address}`;
  copyFile('./artifacts/contracts/LeaseAgreement.sol/LeaseAgreement.json', './src/abi/LeaseAgreement.json');
  
  try {
    fs.writeFileSync('.env', content)
    //文件写入成功。
  } catch (err) {
    console.error(err)
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
