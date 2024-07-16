// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/token/FoolCoToken.sol";
import "../src/token/FoolCoTokenBank.sol";

contract FoolCoTokenBankTest is Test {
    FoolCoToken public token;
    FoolCoTokenBank public tokenBank;
    uint256 privateKey;
    address A;

    function setUp() public {
        //根据私钥创建账户
        privateKey = 0x59c6995e998f97a5a0044966f094538e98192afceee2a5d756e69d6a2ab31ff6;
        A = vm.addr(privateKey);
        vm.startPrank(A);
        token = new FoolCoToken();

        tokenBank = new FoolCoTokenBank(address(token));

        // token.approve(address(A), 100);
        // token.transfer(address(A), 100);
        // token.approve(address(tokenBank), 100);
        // token.transfer(address(tokenBank), 100);
        vm.stopPrank();
    }

    //测试tokenBank 的 存款的逻辑
    function test_permitDeposit() public {
        console.log("this start, A address:", address(A));
        vm.startPrank(A);
        uint256 value = 10;
        uint256 nonce = token.nonces(A);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                A,
                address(tokenBank),
                value,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        console.log("tokenBank------:", address(tokenBank));
        // 签名存钱
        tokenBank.permitDeposit(value, deadline, v, r, s);
        uint256 amount = tokenBank.balance();
        console.log("Balance fetched: ", amount);
        vm.stopPrank();
        // 检查是否存入
        assertEq(amount, value);
    }
}
