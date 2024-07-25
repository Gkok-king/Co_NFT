// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract FoolCoToken is ERC20, ERC20Permit, Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    event TokensBurned(address send, uint amount);

    constructor()
        ERC20("FoolCo", "FC")
        ERC20Permit("GongToken")
        Ownable(_msgSender())
    {
        _mint(_msgSender(), 10000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
        emit TokensBurned(_msgSender(), amount);
    }

    // permit
    function _permit(
        address owner,
        address spender,
        uint256 value,
        bytes memory signature
    ) public returns (bool) {
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)",
                owner,
                spender,
                value,
                this.nonces,
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == owner, "Permit: invalid signature");

        _approve(owner, spender, value);

        return true;
    }
}
