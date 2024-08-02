// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../../src/upgrade/FactoryV2.sol";

contract FactoryV2Script is Script {
    address public proxy = 0x90635Ff2Ff7E64872848612ad6B943b04B089Db0;
    address public erc20Token = 0x65869BaA9336F8968704F2dd60C40959a7bD202b;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with the account:", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);

        Upgrades.upgradeProxy(
            address(proxy),
            "TokenFactoryV2.sol:TokenFactoryV2",
            "",
            deployerAddress
        );
        // console.log("TokenFactoryV1 deployed to:", address(factoryv2));

        vm.stopBroadcast();
    }
}
