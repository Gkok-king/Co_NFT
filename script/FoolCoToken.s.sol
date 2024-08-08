// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import "../src/token/FoolCoToken.sol";

contract FoolCoTokenScript is Script {
    FoolCoToken foolCoToken;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        transfer();
        // mintToken();
        vm.stopBroadcast();
    }

    function deployToken() public {
        foolCoToken = new FoolCoToken();
        console.log("deployed to:", address(foolCoToken));
    }

    function mintToken() public {
        address contractAddress = 0x06400c82ADD45fD6f7c1E330db4FEDA68BeB4ae4;
        foolCoToken = FoolCoToken(contractAddress);
        address aimAddress = 0x06B63492a4dc1Cf670886b2f7Aee03D39cE3361b;
        foolCoToken.approve(aimAddress, 1000);
        foolCoToken.mint(aimAddress, 1000);
        console.log("mintToken success");
    }

    function transfer() public {
        address contractAddress = 0x06400c82ADD45fD6f7c1E330db4FEDA68BeB4ae4;
        foolCoToken = FoolCoToken(contractAddress);
        address aimAddress = 0x06B63492a4dc1Cf670886b2f7Aee03D39cE3361b;
        foolCoToken.transfer(aimAddress, 1000000);
        console.log("transfer success");
    }

    function balanceOf() public {
        address contractAddress = 0x06400c82ADD45fD6f7c1E330db4FEDA68BeB4ae4;
        foolCoToken = FoolCoToken(contractAddress);
        address aimAddress = 0x06B63492a4dc1Cf670886b2f7Aee03D39cE3361b;
        // foolCoToken.approve(aimAddress, 1000);
        uint _balanceOf = foolCoToken.balanceOf(aimAddress);
        console.log("balanceOf", _balanceOf);
    }
}
