// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import "../../src/upgrade/FactoryV1.sol";
import "../../src/upgrade/InscriptionToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FactoryV1Script is Script {
    FactoryV1 factoryV1;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with the account:", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);
        // address _implementation = 0xa8672dfDb0d5A672CC599C3E8D77F8E807cEc6d6; // Replace with your token address
        FactoryV1 _implementation = new FactoryV1(); // Replace with your token address
        console.log("TokenFactoryV1 deployed to:", address(_implementation));

        // Encode the initializer function call
        bytes memory data = abi.encodeCall(
            _implementation.initialize,
            deployerAddress
        );

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(address(_implementation), data);

        vm.stopBroadcast();
        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));
    }
}
