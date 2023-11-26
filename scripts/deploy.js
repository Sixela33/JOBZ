// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const tokenAddress = "0x1234567890123456789012345678901234567890";

  const jobz = await hre.ethers.deployContract("JOBZ", [tokenAddress], {});

  await jobz.waitForDeployment();

  console.log(`Contrato JOBZ desplegado en: ${jobz.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});