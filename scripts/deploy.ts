import {ethers, network, run} from "hardhat";
import { promisify } from 'util';

const sleep = promisify(setTimeout);

async function main() {
  console.log("network.name :" + network.name)
  const [ownerMain] = await ethers.getSigners();
  console.log(`ownerMain ${ownerMain.address}`);
  const MMM314Pledge = await ethers.deployContract("MMM314Pledge");
  await MMM314Pledge.waitForDeployment();
  console.log(`MMM314Pledge合约地址 ${MMM314Pledge.target}`);
  await sleep(18000);
  const MMM314 = await ethers.deployContract("MMM314", [
    MMM314Pledge.target,
    ownerMain
  ]);
  await MMM314.waitForDeployment();
  console.log(`MMM314合约地址 ${MMM314.target}`);
  await sleep(18000);
  await MMM314Pledge.connect(ownerMain).setTokenContract(MMM314.target);
  await sleep(18000);
  await run(`verify:verify`, {
    address: MMM314.target,
    constructorArguments: [
        MMM314Pledge.target,
        ownerMain.address
    ],
  });
  console.log(`验证合约`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
