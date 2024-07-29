// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// 实现⼀个可升级的工厂合约，工厂合约有两个方法：
// deployInscription(string symbol, uint totalSupply, uint perMint) ，
// 该方法用来创建 ERC20 token，（模拟铭文的 deploy）， symbol 表示 Token 的名称，totalSupply 表示可发行的数量，perMint 用来控制每次发行的数量，用于控制mintInscription函数每次发行的数量
// mintInscription(address tokenAddr) 用来发行 ERC20 token，每次调用一次，发行perMint指定的数量。
// 要求：
// • 合约的第⼀版本用普通的 new 的方式发行 ERC20 token 。
// • 第⼆版本，deployInscription 加入一个价格参数 price  deployInscription(string symbol, uint totalSupply, uint perMint, uint price) ,
//  price 表示发行每个 token 需要支付的费用，
//  并且 第⼆版本使用最小代理的方式以更节约 gas 的方式来创建 ERC20 token，
//  需要同时修改 mintInscription 的实现以便收取每次发行的费用。

import "./InscriptionToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FactoryV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address public tokenImplementation;
    event InscriptionDeployed(
        address tokenAddr,
        string symbol,
        uint totalSupply,
        uint perMint
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function deployInscription(
        string memory name,
        string memory symbol,
        uint totalSupply,
        uint perMint
    ) external returns (address) {
        InscriptionToken token = new InscriptionToken(
            name,
            symbol,
            totalSupply,
            perMint
        );
        emit InscriptionDeployed(address(token), symbol, totalSupply, perMint);
        return address(token);
    }

    function mintInscription(address tokenAddr) external {
        InscriptionToken token = InscriptionToken(tokenAddr);
        token.mint(msg.sender);
    }
}