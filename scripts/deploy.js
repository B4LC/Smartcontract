const { ethers } = require("hardhat");

async function main() {
  const TradeFinance = await ethers.getContractFactory("TradeFinance");
  const tradeFinance = await TradeFinance.deploy();
  await tradeFinance.deployed();
  console.log("Contract address:", tradeFinance.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
