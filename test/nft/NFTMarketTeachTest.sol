// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../../src/nft/FoolCoNFT.sol";
import "../../src/nft/NFTMarketTeach.sol";
import "../../src/token/FoolCoToken.sol";

contract NFTMarketTeachTest is Test {
    FoolCoToken public token;
    FoolCoNFT public nft;
    NFTMarketTeach public market;
    uint256 privateKey;
    address seller;
    // address seller = makeAddr("seller");
    NFTMarketTeach.LimitOrder public limitOrder;

    event List(
        address indexed nft,
        uint256 indexed tokenId,
        bytes32 orderId,
        address seller,
        address payToken,
        uint256 price,
        uint256 deadLine
    );

    function setUp() public {
        //根据私钥创建账户
        privateKey = 0x59c6995e998f97a5a0044966f094538e98192afceee2a5d756e69d6a2ab31ff6;
        seller = vm.addr(privateKey);

        token = new FoolCoToken();
        nft = new FoolCoNFT();
        market = new NFTMarketTeach();
        market.setListSigner(seller);

        nft.mint(seller, "URI");
        uint256 tokenId = nft.balanceOf(seller);
        console.log("tokenId", tokenId);
        // vm.startPrank(A);
        // vm.stopPrank();
    }

    //测试
    function test_NFTMarketTeach_list() public {
        uint256 deadline = 1;
        bytes32 hashTypeData = keccak256(
            abi.encode(
                market._LIMIT_ORDER_TYPE_HASH,
                seller,
                address(nft),
                0,
                address(token),
                5,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                market.DOMAIN_SEPARATOR(),
                hashTypeData
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        bytes memory _signature = abi.encodePacked(r, s, v);

        limitOrder = NFTMarketTeach.LimitOrder({
            seller: seller,
            nft: address(nft),
            tokenId: 0,
            payToken: address(token),
            price: 5,
            deadLine: deadline,
            signature: _signature
        });
        vm.startPrank(seller);
        market.list(limitOrder);
        // vm.expectEmit(true, true, false, false);
        // emit List(address(nft), 0, "21", seller, address(token), 5, deadline);
        vm.stopPrank();
    }
}
