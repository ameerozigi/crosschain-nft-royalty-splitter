// SPDX-License-Identifier: MIT
import { ethers } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const hre: HardhatRuntimeEnvironment = (globalThis as any).hre;

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const RoyaltySplitter = await hre.ethers.getContractFactory("RoyaltySplitter");
  const splitter = await RoyaltySplitter.deploy(deployer.address);
  await splitter.waitForDeployment();
  console.log("RoyaltySplitter deployed to:", await splitter.getAddress());

  const CrossChainRoyaltySplitter = await hre.ethers.getContractFactory("CrossChainRoyaltySplitter");
  const cc = await CrossChainRoyaltySplitter.deploy(deployer.address);
  await cc.waitForDeployment();
  console.log("CrossChainRoyaltySplitter deployed to:", await cc.getAddress());

  console.log("Deployment complete.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});