const hre = require("hardhat");

async function main() {
  const FlashLoan = await hre.ethers.getContractFactory("FlashLoan");
  const flashLoan = await FlashLoan.deploy(
    "0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A"
  );

  await flashLoan.waitForDeployment();

  console.log("Flash loan contract: ", await flashLoan.getAddress());
}
// 0x11262D852026D30678A96d5252B4F62b2a4e44Cf

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
