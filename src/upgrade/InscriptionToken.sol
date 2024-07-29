// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InscriptionToken is ERC20, Ownable {
    address public factory;
    uint public perMint;
    uint public price;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        uint _perMint
    ) ERC20(_name, _symbol) Ownable(_msgSender()) {
        perMint = _perMint;
        _mint(msg.sender, _totalSupply);
    }

    function initialize(
        uint _totalSupply,
        uint _perMint,
        uint _price
    ) external {
        require(factory == address(0), "Already initialized");
        _mint(msg.sender, _totalSupply);
        // 可以使用sslot 来修改name和 _symbol
        factory = msg.sender;
        perMint = _perMint;
        price = _price;
    }

    function mint(address to) external onlyOwner {
        _mint(to, perMint);
    }
}
