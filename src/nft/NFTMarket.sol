// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import "./FoolCoNFT.sol";
import "../token/FoolCoToken.sol";

// //编写一个简单的 NFT市场合约，使用自己的发行的 Token 来买卖 NFT， 函数的方法有：

// list() : 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFT 市场。
// buyNFT() : 实现购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT。
contract NFTMarket is IERC721Receiver, EIP712 {
    using ECDSA for bytes32;
    FoolCoToken public token;
    FoolCoNFT public nft;

    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(uint256 => Listing) public listings;

    //订单结构体
    struct Order {
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address seller;
    }
    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            "Order(address nftContract,uint256 tokenId,uint256 price,address seller)"
        );

    event NFTListed(
        uint256 indexed tokenId,
        uint256 indexed price,
        address indexed seller
    );
    event NFTBought(
        uint256 indexed tokenId,
        uint256 price,
        address indexed buyer,
        address indexed seller
    );
    event NFTSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    constructor(FoolCoToken _token, FoolCoNFT _nft) EIP712("NFTMarket", "1") {
        token = _token;
        nft = _nft;
    }

    function list(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than zero");

        nft.transferFrom(msg.sender, address(this), tokenId);

        listings[tokenId] = Listing({price: price, seller: msg.sender});

        emit NFTListed(tokenId, price, msg.sender);
    }

    function buyNFT(uint256 tokenId) public {
        Listing memory listing = listings[tokenId];

        require(listing.price > 0, "NFT not listed for sale");

        require(
            token.transferFrom(msg.sender, listing.seller, listing.price),
            "Token transfer failed"
        );

        nft.transferFrom(address(this), msg.sender, tokenId);

        delete listings[tokenId];

        emit NFTBought(tokenId, listing.price, msg.sender, listing.seller);
    }

    // 回调方式来买nft
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // 限制
        require(msg.sender == address(operator), "Invalid token contract");

        uint256 value = abi.decode(data, (uint256));
        Listing memory listing = listings[tokenId];
        // 删除上架
        delete listings[tokenId];

        // 转给买家
        nft.safeTransferFrom(address(this), from, tokenId);

        // 如果支付金额超过价格，退还多余的代币
        if (value > listing.price) {
            uint256 refund = value - listing.price;
            require(token.transfer(from, refund), "Refund failed");
        }

        // 将多的钱转给卖家
        require(
            token.transfer(listing.seller, listing.price),
            "Payment transfer failed"
        );
        emit NFTSold(tokenId, listing.seller, from, listing.price);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _verifyOrder(
        Order memory order,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.nftContract,
                    order.tokenId,
                    order.price,
                    order.seller
                )
            )
        );
        return ECDSA.recover(digest, signature) == order.seller;
    }

    // 离线签名授权
    function permitBuyNFT(
        Order memory order,
        bytes memory signature712,
        bytes memory signature2621
    ) external {
        //验签
        require(_verifyOrder(order, signature712), "Invalid signature712");

        token._permit(
            msg.sender,
            order.nftContract,
            order.price,
            signature2621
        );

        buyNFT(order.tokenId);
    }
}
