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
    NFTMarket public market;
    Order public order;
    uint public price;
    address seller = makeAddr("seller");
    address buy;
    uint256 privateKey;
    bytes signature712;
    bytes signature2621;

    function setUp() public {
        privateKey = 0x59c6995e998f97a5a0044966f094538e98192afceee2a5d756e69d6a2ab31ff6;
        buy = vm.addr(privateKey);
        price = 10;
        token = new FoolCoToken();
        nft = new FoolCoNFT();
        market = new NFTMarket(token, nft);
        nft.mint(seller, "UrI");

        token.transfer(address(buy), 100);
        nft.approve(address(market), 0);
        //上架
        market.list(0, price);
    }

    function test_permitBuy() public {
        signature712 = createSignature712();
        order = Order({
            nftContract: address(nft),
            tokenId: 0,
            price: price,
            seller: seller
        });
        signature2621 = createSignature2621(buy, seller, price, privateKey);

        NFTMarket.permitBuyNFT(order, signature712, signature2621);
    }

    function createSignature712() public returns (bytes32) {}

    //  创造一个createSignature2621 的签名
    function createSignature2621(
        address _buy,
        address _seller,
        uint256 _price,
        uint256 _privateKey
    ) public returns (bytes32) {
        uint256 nonce = token.nonces(_buy);
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 permitStructHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                _buy,
                _seller,
                _price,
                nonce,
                deadline
            )
        );
        bytes32 permitHash = token._hashTypedDataV4(permitStructHash);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(_privateKey, permitHash);
        return abi.encodePacked(r2, s2, v2);
    }
}
