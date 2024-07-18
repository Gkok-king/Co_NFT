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

    uint256 private buyerPrivateKey =
        uint256(keccak256(abi.encodePacked("buyer")));
    uint256 private sellerPrivateKey =
        uint256(keccak256(abi.encodePacked("seller")));
    uint256 private hostPrivateKey =
        uint256(keccak256(abi.encodePacked("hoster")));

    address buyer = vm.addr(buyerPrivateKey);
    address seller = vm.addr(sellerPrivateKey);
    address host = vm.addr(hostPrivateKey);

    bytes signature712;
    bytes signature2621;

    function setUp() public {
        price = 10;
        token = new FoolCoToken();
        nft = new FoolCoNFT();
        market = new NFTMarket(token, nft);

        //给seller 创造个nft
        nft.mint(seller, "UrI");

        token.transfer(buyer, 100);
        //如果2612签名这步就不写了，
        token.approve(address(market), 100);

        vm.startPrank(seller);
        nft.approve(address(market), 0);
        //上架
        market.list(0, price);
        vm.stopPrank();
    }

    // 测试白名单
    function test_permitBuy() public {
        bytes32 domainSeparator = market.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(market.ORDER_TYPEHASH(), nft, 0, price, seller)
        );
        bytes32 hashValue = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(hostPrivateKey, hashValue);

        // 还要token的签名 这个先不测
        // bytes32 signature2621 = createSignature2621();

        market.permitBuyNFT(0, address(nft), v, r, s);
    }

    function createSignature712() public returns (bytes32) {}

    // //  创造一个createSignature2621 的签名
    // function createSignature2621(
    //     address _buy,
    //     address _seller,
    //     uint256 _price,
    //     uint256 _privateKey
    // ) public returns (bytes32) {
    //     uint256 nonce = token.nonces(_buy);
    //     uint256 deadline = block.timestamp + 1 hours;
    //     bytes32 permitStructHash = keccak256(
    //         abi.encode(
    //             keccak256(
    //                 "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    //             ),
    //             _buy,
    //             _seller,
    //             _price,
    //             nonce,
    //             deadline
    //         )
    //     );
    //     bytes32 permitHash = token._hashTypedDataV4(permitStructHash);
    //     (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(_privateKey, permitHash);
    //     return abi.encodePacked(r2, s2, v2);
    // }
}
