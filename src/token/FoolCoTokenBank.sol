// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FoolCoTokenBank {
    ERC20Permit public token;

    // 存款记录map
    mapping(address => uint256) tokenBalances;

    receive() external payable {}

    fallback() external payable {}

    constructor(address tokenAddress) {
        token = ERC20Permit(tokenAddress);
    }

    // 定义错误
    error balancesError(address Address);
    error inputError(address Address);

    // 提款函数
    function withdraw(uint value) public {
        if (value <= 0) {
            revert inputError(msg.sender);
        }
        if (tokenBalances[msg.sender] < value) {
            revert balancesError(msg.sender);
        }
        tokenBalances[msg.sender] -= value;
        require(token.transfer(msg.sender, value), "Transfer failed");
    }

    // 存款
    function deposit(uint value) public {
        if (value <= 0) {
            revert inputError(msg.sender);
        }
        require(
            token.transferFrom(msg.sender, address(this), value),
            "TransferFrom failed"
        );
        tokenBalances[msg.sender] += value;
    }

    // 查看存款
    function balance() public view returns (uint) {
        return tokenBalances[msg.sender];
    }

    // 离线签名授权 存款
    function permitDeposit(
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (value <= 0) {
            revert inputError(msg.sender);
        }
        token.permit(msg.sender, address(this), value, deadline, v, r, s);
        // token.transfer(address(this), value);
        deposit(value);
    }
}
