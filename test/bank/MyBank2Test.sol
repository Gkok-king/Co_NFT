// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {MyBank2} from "../../src/bank/MyBank2.sol";

contract MyBank2Test is Test {
    MyBank2 myBank2;
    Account u1 = makeAccount("u1");
    Account u2 = makeAccount("u2");
    Account u3 = makeAccount("u3");
    Account u4 = makeAccount("u4");

    function setUp() public {
        myBank2 = new MyBank2();
    }

    function test_MyBank2Test_deposit() public {
        vm.startPrank(u4.addr);
        vm.deal(u4.addr, 4 ether);
        myBank2.deposit{value: 4 ether}();
        vm.stopPrank();
        vm.startPrank(u1.addr);
        vm.deal(u1.addr, 1 ether);
        myBank2.deposit{value: 1 ether}();
        vm.stopPrank();
        vm.startPrank(u2.addr);
        vm.deal(u2.addr, 2 ether);
        myBank2.deposit{value: 2 ether}();
        vm.stopPrank();
        vm.startPrank(u3.addr);
        vm.deal(u3.addr, 3 ether);
        myBank2.deposit{value: 3 ether}();
        vm.stopPrank();

        address[] memory list = myBank2.getTop(2);
        address a0 = list[0];
        console.log("success", list.length);
        console.log("a0:", a0);
    }
}
