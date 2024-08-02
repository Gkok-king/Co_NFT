// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import "../src/upgrade/FactoryV1.sol";

contract FactoryV1Test is Test {
    FactoryV1 public factoryV1;

    address admin = makeAddr("admin");
    address A = makeAddr("A");
    address B = makeAddr("B");

    function setUp() public {
        vm.startPrank(admin);
        factoryV1 = new FactoryV1();
        vm.stopPrank();
    }

    function test_FactoryV1Test_deploy() public {
        vm.startPrank(A);
        address a1 = factoryV1.deployInscription("AToken", "AT", 1000, 1);
        vm.stopPrank();
        vm.startPrank(B);
        address a2 = factoryV1.deployInscription("AToken", "AT", 1000, 1);
        vm.stopPrank();
        assertNotEq(a1, a2);
    }
}
