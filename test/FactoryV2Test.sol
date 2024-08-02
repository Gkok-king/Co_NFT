// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import "../src/upgrade/FactoryV2.sol";

contract FactoryV2Test is Test {
    FactoryV2 public factoryV2;

    address admin = makeAddr("admin");
    address A = makeAddr("A");
    address B = makeAddr("B");

    function setUp() public {
        vm.startPrank(admin);
        factoryV2 = new FactoryV2();
        vm.stopPrank();
    }

    function test_FactoryV2Test_deploy() public {
        vm.startPrank(A);
        // factoryV2.deployInscription("AA", 1000, 1, 1);
        vm.stopPrank();
    }
}
