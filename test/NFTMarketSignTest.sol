// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../src/nft/FoolCoNFT.sol";
import "../src/nft/NFTMarket.sol";
import "../src/token/FoolCoToken.sol";
import {Test, console} from "forge-std/Test.sol";

// 实现只有离线授权的白名单地址才可以购买 NFT （用自己的名称发行 NFT，再上架） 。
// 白名单具体实现逻辑为：项目方给白名单地址签名，白名单用户拿到签名信息后，传给 permitBuy() 函数，
// 在permitBuy()中判断时候是经过许可的白名单用户，如果是，才可以进行后续购买，否则 revert 。
contract NFTMarketTest is Test {
    struct Order {
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address seller;
    }

    FoolCoToken public token;
    FoolCoNFT public nft;
    NFTMarket public nftMarket;
    Order public order;
    address seller = makeAddr("seller");
    address white2 = makeAddr("white2");
    address white3 = makeAddr("white3");

    function setUp() public {
        token = new FoolCoToken();
        nft = new FoolCoNFT();
        nftMarket = new NFTMarket(token, nft);
    }

    function test_permitBuy() public {
        order = Order({
            nftContract: address(nft),
            tokenId: 0,
            price: 10,
            seller: seller
        });
        // NFTMarket.permitBuyNFT(order, signature712, signature2621);
    }

    //  初始化白名单
    function initWhiteList() public {}
}
