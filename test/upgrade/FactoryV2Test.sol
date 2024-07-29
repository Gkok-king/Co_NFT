// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import "../../src/upgrade/FactoryV2.sol";
import "../../src/upgrade/InscriptionToken.sol";

contract FactoryV2Test is Test {
    FactoryV2 public factoryV2;
    InscriptionToken ins;

    address admin = makeAddr("admin");
    address A = makeAddr("A");
    address B = makeAddr("B");

    function setUp() public {
        vm.startPrank(admin);
        factoryV2 = new FactoryV2();
        vm.stopPrank();
    }

    //
    function test_FactoryV2Test_deploy() public {
        // A deploy
        vm.startPrank(A);
        address _address = factoryV2.deployInscription(
            "AToken",
            "AT",
            1000,
            1,
            1 ether
        );
        ins = InscriptionToken(_address);
        vm.stopPrank();

        // B deploy
        vm.deal(B, 0.5 ether);
        vm.startPrank(B);
        address _address2 = factoryV2.deployInscription(
            "BToken",
            "BT",
            1000,
            1,
            1 ether
        );
        InscriptionToken ins2 = InscriptionToken(_address2);
        vm.stopPrank();

        assertNotEq(address(ins), address(ins2));
    }

    function test_FactoryV2Test_mint() public {
        // A deploy
        vm.startPrank(A);
        address _address = factoryV2.deployInscription(
            "BToken",
            "BT",
            1000,
            1,
            1 ether
        );
        ins = InscriptionToken(_address);
        vm.stopPrank();

        // B 错误mint
        vm.deal(B, 0.5 ether);
        vm.startPrank(B);
        vm.expectRevert("Incorrect Ether value");
        factoryV2.mintInscription{value: 0.5 ether}(address(ins));
        vm.stopPrank();
    }
}
