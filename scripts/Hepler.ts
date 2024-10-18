import {ethers, network} from "hardhat";
import {MMM314, MMM314Pledge} from "../typechain-types";
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/signers";

export async function batchTransfer(){
    console.log(network.name)
    console.log("batchTransfer start")
    const accounts = await ethers.getSigners();
    const main = accounts[0];
    for(let i = 1; i <= 20; i++){
        const address = accounts[i];
        console.log(address.address)
        const transaction = await main.sendTransaction({
            to: address.address,
            value: ethers.parseEther("0.03")
        });
        await transaction.wait();
        const mainBalance = await ethers.provider.getBalance(main.address);
        const balance = await ethers.provider.getBalance(address.address);
        console.log("main",ethers.formatEther(mainBalance))
        console.log(address.address,ethers.formatEther(balance))
    }
    console.log("batchTransfer end")
}

export async function buyMMM314(contract:string,mmm314pledge:string){
    console.log(network.name)
    console.log("buyMMM314 start")
    console.log("contract"+contract)
    console.log("mmm314pledge"+mmm314pledge)
    const accounts = await ethers.getSigners();
    let buyAmount = BigInt(0);
    const mmm314 = await getMMM314(contract);
    for(let i = 1; i <= 20; i++){
        // const ethAmount = await mmm314.getAmountOut(ethers.parseEther("220000"),false);
        // console.log("花费金额" + ethers.formatEther(ethAmount))
        // buyAmount += ethAmount;
        const address = accounts[i];
        // const transaction = await address.sendTransaction({
        //     to: contract,
        //     value: ethAmount
        // });
        // await transaction.wait();
        const balance = await mmm314.balanceOf(address);
        if(balance > 0 ){
            console.log("质押金额" + balance)
            const transaction1 = await mmm314.connect(address).transfer(mmm314pledge,balance)
            await transaction1.wait();
        }
    }
    console.log("buyMMM314 end")
}

export async function addLiquidityHandle(contract:string){
    console.log(network.name)
    console.log("addLiquidity start")
    const blockNumber =  await ethers.provider.getBlockNumber();
    console.log("blockNumber",blockNumber);
    const mmm314 = await getMMM314(contract);
    const [ ownerMain ] = await ethers.getSigners();
    const extendTime = BigInt(60) * BigInt(60) * BigInt(8) * BigInt(30) * BigInt(1200)
    const transaction =  await mmm314.connect(ownerMain).addLiquidity(BigInt(blockNumber) + extendTime,{
        value : ethers.parseEther("1")
    });
    await transaction.wait()
    console.log("addLiquidity end")
    await mmm314.connect(ownerMain).renounceOwnership();
    console.log("renounceOwnership end")
}

export async function getMMM314(contract:string) : Promise<MMM314> {
    const MMM314Factory = await ethers.getContractFactory("MMM314");
    return MMM314Factory.attach(contract) as MMM314;
}

export async function extendLiquidityLockHandle(contract:string) {
    console.log(network.name)
    console.log("extendLiquidityLock start")
    const mmm314 = await getMMM314(contract)
    const [ ownerMain ] = await ethers.getSigners();
    const blockNumber =  await ethers.provider.getBlockNumber();
    const extendTime = BigInt(60) * BigInt(60) * BigInt(8) * BigInt(30) * BigInt(1200)
    await mmm314.connect(ownerMain).extendLiquidityLock(BigInt(blockNumber) + extendTime);
    console.log("extendLiquidityLock end")
}

export async function getMMM314Pledge(contract:string): Promise<MMM314Pledge>
{
    const MMM314Factory = await ethers.getContractFactory("MMM314Pledge")
    return MMM314Factory.attach(contract) as MMM314Pledge;
}

export async function pledgeCount(contract:string) {
    const mmm314pledge =  await getMMM314Pledge(contract);
    const count = await mmm314pledge.pledgeCount();
    console.log(count);
}

export async function pledgeWithdraw(contract:string,owner:HardhatEthersSigner) {
    const mmm314pledge =  await getMMM314Pledge(contract);
    const balance = await mmm314pledge.balanceOf(owner.address);
    if(balance > 0){
        const transaction = await mmm314pledge.connect(owner).transfer(owner.address,balance);
        await transaction.wait();
    }
}

export async function pledgeWithdrawAll(contract:string) {
    const accounts = await ethers.getSigners();
    for (let i = 1;i <= 10; i++){
        const owner  = accounts[i];
        await pledgeWithdraw(contract,owner);
    }
}

export async function getMMM314Price(contract:string):Promise<string> {
    const mmm314 = await getMMM314(contract);
    const price = await mmm314.getAmountOut(ethers.parseEther("1"),false);
    return ethers.formatEther(price);
}

