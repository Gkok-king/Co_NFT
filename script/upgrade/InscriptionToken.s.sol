// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import "/src/upgrade/InscriptionToken.sol";

contract InscriptionTokenScript is Script {
    InscriptionToken ins;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ins = new InscriptionToken();

        vm.stopBroadcast();

        console.log("deployed to:", address(ins));
    }
}
