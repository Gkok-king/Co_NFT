// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FoolCoTokenManager is ERC20, Ownable {
    using SafeERC20 for IERC20;

    event TokensBurned(address send, uint amount);

    constructor() ERC20("FoolCo", "FC") Ownable(_msgSender()) {
        _mint(_msgSender(), 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
        emit TokensBurned(_msgSender(), amount);
    }
}
