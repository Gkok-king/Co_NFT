// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import "../src/nft/FoolCoNFT.sol";

contract FoolCoTokenScript is Script {
    FoolCoNFT foolCoNFT;

    function run() external {
        // deployConstractor();
        mint();
    }

    function deployConstractor() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // console.log("deployerAddress to:", deployerPrivateKey);
        // // 使用私钥地址启动广播模式
        // address deployerAddress = vm.addr(deployerPrivateKey);
        // uint256 deployerBalance = deployerAddress.balance;
        // console.log("deployerAddress to:", deployerAddress);
        // console.log("deployerBalance to:", deployerBalance);
        vm.startBroadcast(deployerPrivateKey);

        foolCoNFT = new FoolCoNFT();

        vm.stopBroadcast();

        console.log("deployed to:", address(foolCoNFT));
    }

    function mint() public {
        // 从环境变量中读取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address myAddress = 0xd51b4c5483513CF83071fb2E0dF7dbf30c4AC503;
        address contractAddress = 0x3C83cd7Fd45874E641167Af2cF1006F714a241Ed;
        // 创建合约实例
        FoolCoNFT myContract = FoolCoNFT(contractAddress);

        // 使用私钥启动广播模式
        vm.startBroadcast(deployerPrivateKey);

        // 调用合约的 view 方法
        myContract.mint(
            myAddress,
            "QmTKU3bxyqqYccTwmVJ83uU3pwthJtUnVomuRXNPV9Skoi"
        );

        // 停止广播模式
        vm.stopBroadcast();
    }
}
