import { expect } from "chai";
import {ethers, network} from "hardhat";
import { EventLog} from 'ethers'

// import "hardhat/console.sol";
import type {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/signers";
import {
    MMM314, MMM314Pledge
} from '../typechain-types'
import {addLiquidityHandle, batchTransfer, buyMMM314} from "../scripts/Hepler";


describe("MMM314",  ()=>{
    let ownerMain: HardhatEthersSigner
    let owner1: HardhatEthersSigner
    let owner2: HardhatEthersSigner
    let owner3: HardhatEthersSigner
    let owner4: HardhatEthersSigner
    let owner5: HardhatEthersSigner
    let owner6: HardhatEthersSigner
    let owner7: HardhatEthersSigner
    let MMM314: MMM314
    let MMM314Pledge: MMM314Pledge
    let totalSupply: bigint
    let thisTokenBalance: bigint

    before(async () =>{
        // console.log(12313123123123);
         [ownerMain,owner1, owner2, owner3, owner4,owner5,owner6,owner7] = await ethers.getSigners();
         const MMM314Factory = await ethers.getContractFactory("MMM314",ownerMain);
         const MMM314PledgeFactory = await ethers.getContractFactory("MMM314Pledge",ownerMain);
         MMM314Pledge = await MMM314PledgeFactory.deploy();
         await MMM314Pledge.waitForDeployment();
         MMM314 = await MMM314Factory.deploy(MMM314Pledge.target,ownerMain);
         await MMM314.waitForDeployment();
         await MMM314Pledge.connect(ownerMain).setTokenContract(MMM314.target);
         totalSupply = await MMM314.totalSupply();
         console.log("totalSupply"+ethers.formatUnits(totalSupply));
         thisTokenBalance = await MMM314.balanceOf(MMM314.target);
    })

    // describe("检查参数", async () => {
    //     it("质押地址", async () => {
    //         const pledgeAddress = await MMM314.pledgeAddress()
    //         console.log("pledgeAddress",pledgeAddress)
    //         console.log("MMM314Pledge",MMM314Pledge.target)
    //         expect(pledgeAddress).to.equal(MMM314Pledge.target)
    //     });
    //     it("官方地址", async () => {
    //         const officialAddress = await MMM314.officialAddress()
    //         console.log("officialAddress",officialAddress)
    //         console.log("ownerMain.address",ownerMain.address)
    //         expect(officialAddress).to.equal(ownerMain.address)
    //     });
    //     it("余额判断",async () => {
    //         const balance = await MMM314.balanceOf(ownerMain.address)
    //         const balanceThis = await MMM314.balanceOf(MMM314.target)
    //         const mainBalance = (totalSupply * BigInt(1) / BigInt(10));
    //         const thisBalance = (totalSupply * BigInt(9) / BigInt(10));
    //         console.log("mainBalance",mainBalance);
    //         console.log("balance",balance);
    //         expect(balance).to.equal(mainBalance);
    //         expect(balanceThis).to.equal(thisBalance);
    //     })
    // })

    describe("测试addLiquidity", async () => {
        it("添加流动性", async () => {
            // const blockNumber =  await ethers.provider.getBlockNumber();
            // console.log("blockNumber",blockNumber);
            // await MMM314.connect(ownerMain).addLiquidity(blockNumber + 2,{
            //     value : ethers.parseEther("1")
            // });
            // const balance = await ethers.provider.getBalance(MMM314.target)
            // console.log("balance",balance);
            // expect(balance).to.equal(ethers.parseEther("1"));
            await addLiquidityHandle(MMM314.target.toString());
            // await batchTransfer();
            // await buyMMM314(MMM314.target.toString(),MMM314Pledge.target.toString());
        });
        // it("测试reserves", async () => {
        //     const reserves = await MMM314.connect(ownerMain).getReserves();
        //     console.log("reserves",reserves);
        //     expect(reserves[0]).to.equal(ethers.parseEther("1"));
        //     const thisBalance = (totalSupply * BigInt(9) / BigInt(10));
        //     expect(reserves[1]).to.equal(thisBalance);
        // });
        // it("测试getAmountOut", async () => {
        //     const tokenAmount = await MMM314.getAmountOut(10,true);
        //     console.log("tokenAmount",ethers.formatEther(tokenAmount));
        //     const ethAmount = await MMM314.getAmountOut(10,false);
        //     console.log("thisTokenBalance",ethers.formatEther(thisTokenBalance));
        //     console.log("ethAmount",ethers.formatEther(ethAmount));
        // })
        // it("测试不能大于10%主币池子",async()=>{
        //     const balance = await ethers.provider.getBalance(MMM314.target);
        //     console.log("balance",ethers.formatEther(balance))
        //     const transaction = await owner1.sendTransaction({
        //         to:MMM314.target,
        //         value:ethers.parseEther("0.11")
        //     })
        //     await transaction.wait();
        //     console.log(transaction)
        // })
        // it("测试购买不能超过1亿枚",async()=>{
        //     const transaction = await owner1.sendTransaction({
        //         to:MMM314.target,
        //         value:ethers.parseEther("0.1")
        //     })
        // })
        it("测试购买",async()=>{
            const tokenAmount = await MMM314.connect(ownerMain).getAmountOut(ethers.parseEther("0"),true);
            const transaction = await owner1.sendTransaction({
                to:MMM314.target,
                value:0
            })
            const transactionReceipt = await transaction.wait();
            const balance = await MMM314.balanceOf(owner1.address);
            const mmm314Balance = await MMM314.balanceOf(MMM314.target);
            let  outAmount:bigint = BigInt(0);
            let  swapAmount = BigInt(0);
            transactionReceipt?.logs.forEach((log)=>{
                const logEvent = MMM314.interface.parseLog(log);
                if(logEvent?.name === "Swap"){
                    // logEvent?.args?.forEach((arg)=>{
                    //     console.log(arg)
                    // })
                    outAmount += logEvent.args[2]
                    swapAmount = logEvent.args[4]

                }
                if(logEvent?.name === "Transfer"){
                    outAmount += logEvent.args[2]
                }
            })
            console.log("swapAmount",swapAmount)
            console.log("outAmount",outAmount)
            console.log("balance",balance)
            console.log("tokenAmount",tokenAmount)
            expect(balance).to.equal(swapAmount);
            // expect(tokenAmount).to.equal(swapAmount);
            // expect(mmm314Balance + outAmount).to.equal(totalSupply * BigInt(9) /BigInt(10));

        })

        // it("测试质押小于2.1w",async()=>{
        //     const transaction = await MMM314.connect(owner1).transfer(MMM314Pledge.target,ethers.parseEther("9000"))
        //     // const transactionContractReceipt  = await transaction.wait();
        //     // transactionContractReceipt?.logs.forEach((event) =>{
        //     //     console.log(event)
        //     // })
        // })

        // it("测试质押",async()=>{
        //     const transaction = await MMM314.connect(owner1).transfer(MMM314Pledge.target,ethers.parseEther("21000"))
        //     const transactionContractReceipt  = await transaction.wait();
        //     transactionContractReceipt?.logs.forEach((eventLog) =>{
        //         if(eventLog instanceof EventLog){
        //             console.log(eventLog.fragment.name)
        //             // console.log(eventLog.args)
        //         }else{
        //             const data = MMM314Pledge.interface.parseLog(eventLog);
        //             console.log(data?.name)
        //             // console.log(data?.args)
        //         }
        //     })
        //     console.log("totalDividends",await MMM314Pledge.totalDividends())
        //     console.log("owner1Dividends",await MMM314Pledge.ownerDividends(owner1.address))
        //     console.log("pledgeTrigger",await MMM314.pledgeTrigger())
        //     expect(await MMM314Pledge.balanceOf(owner1.address)).to.equal(ethers.parseEther("21000"));
        //     expect(await MMM314Pledge.totalSupply()).to.equal(ethers.parseEther("21000"));
        // })
        //
        // it("测试重复质押",async()=>{
        //     const transaction = await owner2.sendTransaction({
        //         to:MMM314.target,
        //         value:ethers.parseEther("0.01")
        //     })
        //     const transactionReceipt = await transaction.wait();
        //     transactionReceipt?.logs.forEach((log)=>{
        //         let logEvent = MMM314.interface.parseLog(log);
        //         if(!logEvent){
        //             logEvent = MMM314Pledge.interface.parseLog(log);
        //         }
        //         console.log(logEvent?.name)
        //         console.log(logEvent?.args)
        //     })
        //     console.log("getDividend",await MMM314Pledge.getDividend(owner1))
        //     console.log("totalDividends",await MMM314Pledge.totalDividends())
        //     const transactionContract = await MMM314.connect(owner2).transfer(MMM314Pledge.target,ethers.parseEther("100000"))
        //     await transactionContract.wait();
        //     console.log("owner1Dividends",await MMM314Pledge.ownerDividends(owner1.address))
        //     console.log("owner1balance",await MMM314Pledge.balanceOf(owner1.address))
        //     console.log("owner1MMM314balance",await MMM314.balanceOf(owner1.address))
        //     const transactionContract2 = await MMM314.connect(owner1).transfer(MMM314Pledge.target,ethers.parseEther("21000"))
        //     const contractTransactionReceipt = await transactionContract2.wait();
        //     contractTransactionReceipt?.logs.forEach((log)=>{
        //         let logEvent = MMM314.interface.parseLog(log);
        //         if(!logEvent){
        //             logEvent = MMM314Pledge.interface.parseLog(log);
        //         }
        //         console.log(logEvent?.name)
        //         console.log(logEvent?.args)
        //     })
        //     const transaction2 = await owner3.sendTransaction({
        //         to:MMM314.target,
        //         value:ethers.parseEther("0.01")
        //     })
        //     const transactionReceipt2 = await transaction.wait();
        //     console.log("owner1balance",await MMM314Pledge.balanceOf(owner1.address))
        //     console.log("owner2balance",await MMM314Pledge.balanceOf(owner2.address))
        //     console.log("totalSupply",await MMM314Pledge.totalSupply())
        //     console.log("pledgeCount",await MMM314Pledge.pledgeCount())
        //     console.log("totalDividends",await MMM314Pledge.totalDividends())
        //     console.log("owner1Dividends",await MMM314Pledge.ownerDividends(owner1.address))
        //     console.log("owner2Dividends",await MMM314Pledge.ownerDividends(owner2.address))
        //     console.log("MMM314Pledge",await MMM314.balanceOf(MMM314Pledge.target))
        // })
        // it("售出测试",async()=>{
        //     console.log("owner1balance",await MMM314Pledge.balanceOf(owner1.address))
        //     // console.log("owner2balance",await MMM314Pledge.balanceOf(owner2.address))
        //     await network.provider.send("evm_increaseTime",[3660])
        //     const transaction = await MMM314.connect(owner1).transfer(MMM314.target,1)
        //     const transactionReceipt = await transaction.wait();
        //     // transactionReceipt?.logs.forEach((log)=>{
        //     //     // let logEvent = MMM314.interface.parseLog(log);
        //     //     // if(!logEvent){
        //     //     //     logEvent = MMM314Pledge.interface.parseLog(log);
        //     //     // }
        //     //     // console.log(logEvent?.name)
        //     //     // console.log(logEvent?.args)
        //     // })
        //     console.log("owner1balance",await MMM314Pledge.balanceOf(owner1.address))
        //     // console.log("owner2balance",await MMM314Pledge.balanceOf(owner2.address))
        // })

        // it("测试提取",async()=>{
        //     console.log("owner2PledgeBalance",await MMM314Pledge.balanceOf(owner2.address))
        //     console.log("MMM314PledgeTotalSupply",await MMM314Pledge.totalSupply())
        //     const owner2balance =  await MMM314.balanceOf(owner2.address);
        //     console.log("owner2balance",owner2balance)
        //     await MMM314Pledge.connect(owner2).transfer(owner2,ethers.parseEther("21000"))
        //     let ownerFee = ethers.parseEther("21000") * await MMM314Pledge.withdrawalFee() / await MMM314Pledge.BASE_FEE();
        //     ownerFee = ethers.parseEther("21000") - ownerFee;
        //     expect(owner2balance + ownerFee).to.equal(await MMM314.balanceOf(owner2.address))
        //     console.log("MMM314PledgeTotalSupply",await MMM314Pledge.totalSupply())
        //     console.log("MMM314PledgeInactivatedTotalSupply",await MMM314Pledge.inactivatedTotalSupply())
        //     console.log("owner2PledgeBalance",ethers.formatEther(await MMM314Pledge.balanceOf(owner2.address)))
        //     console.log("owner2balance",await MMM314.balanceOf(owner2.address))
        //     console.log("pledgeCount",await MMM314Pledge.pledgeCount())
        //     console.log("totalDividends",await MMM314Pledge.totalDividends())
        //     console.log("owner2Dividends",await MMM314Pledge.ownerDividends(owner2.address))
        //     await MMM314Pledge.connect(owner2).transfer(owner2,ethers.parseEther("80000"))
        //     console.log("owner2balance",await MMM314.balanceOf(owner2.address))
        //     console.log("MMM314PledgeTotalSupply",await MMM314Pledge.totalSupply())
        //     console.log("owner2PledgeBalance",ethers.formatEther(await MMM314Pledge.balanceOf(owner2.address)))
        //     console.log("owner2PledgeInactivatedBalanceOf",ethers.formatEther(await MMM314Pledge.inactivatedBalanceOf(owner2.address)))
        //     console.log("MMM314PledgeInactivatedTotalSupply",await MMM314Pledge.inactivatedTotalSupply())
        //
        //     const transactionContract = await MMM314.connect(owner2).transfer(MMM314Pledge.target,ethers.parseEther("20000"))
        //     await transactionContract.wait();
        //     console.log("pledgeCount",await MMM314Pledge.pledgeCount())
        //     console.log("MMM314PledgeTotalSupply",await MMM314Pledge.totalSupply())
        //     console.log("owner2PledgeBalance",await MMM314Pledge.balanceOf(owner2.address))
        //     console.log("owner2PledgeInactivatedBalanceOf",await MMM314Pledge.inactivatedBalanceOf(owner2.address))
        //     console.log("MMM314PledgeInactivatedTotalSupply",await MMM314Pledge.inactivatedTotalSupply())
        // })
        // it("官方分红",async()=>{
        //     // const transaction = await ownerMain.sendTransaction({
        //     //     to:MMM314.target,
        //     //     value:ethers.parseEther("0.001")
        //     // })
        //     // await transaction.wait();
        //     const balance = await MMM314.balanceOf(ownerMain);
        //     console.log("totalDividends",await MMM314Pledge.totalDividends())
        //     console.log("ownerMainbalance",await MMM314.balanceOf(ownerMain))
        //     await MMM314.connect(ownerMain).approve(MMM314Pledge.target,balance)
        //     await MMM314Pledge.connect(ownerMain).ownerAddDividends(balance - ethers.parseEther("10000"))
        //     console.log("ownerMainbalance",await MMM314.balanceOf(ownerMain))
        //     console.log("totalDividends",await MMM314Pledge.totalDividends())
        // })
        //
        // it("测试提取",async()=>{
        //     const blockNumber =  await ethers.provider.getBlockNumber();
        //     await MMM314.connect(ownerMain).extendLiquidityLock(blockNumber + 1000000000000)
        // })
        //
        // it("提取流动性",async()=>{
        //     const balance = await ethers.provider.getBalance(ownerMain.address);
        //     console.log(ethers.formatEther(balance))
        //     const mmm314Balance = await ethers.provider.getBalance(MMM314.target);
        //     console.log(ethers.formatEther(mmm314Balance))
        //     await MMM314.connect(ownerMain).removeLiquidity()
        //     const balance1 = await ethers.provider.getBalance(ownerMain.address);
        //     console.log(ethers.formatEther(balance1))
        //     const mmm314Balance1 = await ethers.provider.getBalance(MMM314.target);
        //     console.log(ethers.formatEther(mmm314Balance1))
        // })
        // it("空投测试",async()=>{
        //     await MMM314.connect(ownerMain).addAirdrop(ethers.parseEther("1000"),1,true);
        //     const airdropAddress = await MMM314.airdropAddress();
        //     await MMM314.connect(owner7).transfer(airdropAddress,0);
        //     const balance = await MMM314.balanceOf(owner7);
        //     expect(balance).to.equal(ethers.parseEther("1000"));
        //     await MMM314.connect(owner2).transfer(airdropAddress,0);
        // })
    })
})