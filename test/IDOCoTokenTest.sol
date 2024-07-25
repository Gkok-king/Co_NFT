// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/sale/IDOSale.sol";
import "../src/token/FoolCoToken.sol";

contract IDOCoTokenTest is Test {
    FoolCoToken public token;
    IDOSale public idoSale;
    address admin;

    address A;
    address B;

    function setUp() public {
        A = makeAddr("A");
        admin = makeAddr("admin");
        vm.startPrank(admin);
        token = new FoolCoToken();
        idoSale = new IDOSale(10 ether, 20 ether, 30 days, address(token));

        token.approve(address(idoSale), idoSale.tokenTotalAmount());
        token.transfer(address(idoSale), idoSale.tokenTotalAmount());
        vm.stopPrank();
    }

    function test_IDOCoToken_withdraw() public {
        vm.deal(A, 5 ether);
        vm.startPrank(A);
        vm.expectEmit(true, true, false, false);
        emit withdrawEvent(A, 1 ether);
        idoSale.withdraw{value: 1 ether}();
        vm.stopPrank();
    }

    function test_IDOCoToken_withdraw_date() public {
        vm.deal(A, 5 ether);
        vm.warp(block.timestamp + 32 days);
        vm.startPrank(A);
        vm.expectRevert("too late ");
        idoSale.withdraw{value: 1 ether}();
        vm.stopPrank();
    }

    function test_IDOCoToken_withdraw_max() public {
        vm.deal(A, 50 ether);
        vm.startPrank(A);
        vm.expectRevert("Exceeds maximum funding goal");
        idoSale.withdraw{value: 50 ether}();
        vm.stopPrank();
    }

    function test_IDOCoToken_withdraw_min() public {
        vm.deal(A, 1 ether);
        vm.startPrank(A);
        vm.expectRevert("amount is too less");
        idoSale.withdraw{value: 0.001 ether}();
        vm.stopPrank();
    }

    function test_IDOCoToken_refund() public {
        vm.deal(A, 1 ether);
        vm.startPrank(A);
        idoSale.withdraw{value: 0.5 ether}();
        vm.warp(block.timestamp + 31 days);
        vm.expectEmit(true, true, false, false);
        emit refundEvent(A, 0.5 ether);
        idoSale.refund();
        vm.stopPrank();
    }

    function test_IDOCoToken_refund_amount() public {
        vm.deal(A, 1 ether);
        vm.startPrank(A);
        vm.warp(block.timestamp + 31 days);
        vm.expectRevert("No funds to refund");
        idoSale.refund();
        vm.stopPrank();
    }

    function test_IDOCoToken_claim() public {
        vm.deal(A, 10 ether);
        vm.deal(B, 10 ether);
        vm.prank(B);
        idoSale.withdraw{value: 10 ether}();
        vm.startPrank(A);
        idoSale.withdraw{value: 5 ether}();
        vm.warp(block.timestamp + 31 days);

        // console.log(token.balanceOf(address(idoSale)));
        // vm.expectEmit(true, true, false, false);
        // emit claimEvent(A, 10000000000000000000);
        // console.log("d==========>", idoSale.getSomeOne());
        // console.log("d==========>", idoSale.getTokenTotalAmount());
        idoSale.claim();
        vm.stopPrank();
    }

    event withdrawEvent(address indexed, uint256 indexed);
    event claimEvent(address indexed, uint256 indexed);
    event refundEvent(address indexed, uint256 indexed);
}
