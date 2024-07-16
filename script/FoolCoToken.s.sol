// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import "../src/token/FoolCoToken.sol";

contract FoolCoTokenScript is Script {
    FoolCoToken foolCoToken;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        foolCoToken = new FoolCoToken();

        vm.stopBroadcast();

        console.log("deployed to:", address(foolCoToken));
    }
}
