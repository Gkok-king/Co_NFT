// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/staking/StakePool.sol";
import "../src/token/FoolCoToken.sol";
import "../src/token/EsFoolCoToken.sol";

contract EsFoolCoTokenTest is Test {
    FoolCoToken public token;
    EsFoolCoToken public esToken;
    StakePool public stakePool;

    address admin = makeAddr("admin");
    address A = makeAddr("A");
    address B = makeAddr("B");

    function setUp() public {
        vm.startPrank(admin);
        token = new FoolCoToken();
        esToken = new EsFoolCoToken(token);
        stakePool = new StakePool(token, esToken, 1);
        token.approve(address(stakePool), token.totalSupply());
        esToken.setTakePool(address(stakePool));
        // token.approve(address(idoSale), idoSale.tokenTotalAmount());
        // token.transfer(address(idoSale), idoSale.tokenTotalAmount());
        vm.stopPrank();
    }

    function test_EsFoolCoTokenTest_mint() public {
        vm.startPrank(admin);
        token.approve(A, 1000);
        token.transfer(A, 1000);
        vm.stopPrank();

        vm.startPrank(A);
        uint amount = 100;
        // 记得A要授权给stakePool
        token.approve(address(stakePool), amount);
        // token.allowance(A, address(stakePool));
        vm.expectEmit(true, true, false, false);
        emit stakeEvent(A, amount);
        stakePool.stake(amount);
        vm.stopPrank();
    }

    event stakeEvent(address indexed user, uint256 amount);
    event unStakeEvent(address indexed user, uint256 amount);
    event claimEvent(address indexed user, uint256 amount);
}
