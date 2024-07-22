// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTMarketTeach is Ownable(msg.sender), EIP712("NFTMarket", "1") {
    using ECDSA for bytes32;
    address public feeTo;
    uint256 public constant feeBP = 30;
    // 白名单签名者
    address public whiteListSigner;

    // 上架签名地址
    address public listSigner;
    // 上架签名HashType
    bytes32 public constant _LIMIT_ORDER_TYPE_HASH =
        keccak256(
            "LimitOrder(address seller,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
        );
    // 上架结构体
    struct LimitOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadLine;
        bytes signature;
    }

    // 挂单的所有订单
    mapping(bytes32 => SellerOrder) public listingOrders;

    //反向nft token的最后一个订单
    mapping(address => mapping(uint256 => bytes32)) public _lastIds;
    struct SellerOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadLine;
    }

    constructor() {}

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function setListSigner(address _listSigner) public onlyOwner {
        listSigner = _listSigner;
    }

    //费率开关
    function setFeeTo(address to) external onlyOwner {
        require(feeTo != to, "set error");
        feeTo = to;
        emit SetFeeTo(to);
    }

    //查询上架的nft
    function listings(
        address nft,
        uint256 tokenId
    ) external view returns (bytes32) {
        bytes32 id = _lastIds[nft][tokenId];
        return listingOrders[id].seller == address(0) ? bytes32(0x00) : id;
    }

    // 上架
    function list(
        address nft,
        uint256 tokenId,
        address payToken,
        uint price,
        uint256 deadLine
    ) external {
        require(deadLine > block.timestamp, "deadline is in the past");
        require(price > 0, "Price must be greater than zero");
        require(
            payToken == address(0) || IERC20(payToken).totalSupply() > 0,
            "token is error"
        );

        // safe check
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "not Owner");
        require(
            IERC721(nft).getApproved(tokenId) == address(this) ||
                IERC721(nft).isApprovedForAll(msg.sender, address(this)),
            "marekt is not approve"
        );

        SellerOrder memory order = SellerOrder({
            seller: msg.sender,
            nft: nft,
            tokenId: tokenId,
            payToken: payToken,
            price: price,
            deadLine: deadLine
        });

        bytes32 orderId = keccak256(abi.encode(order));
        require(listingOrders[orderId].seller == address(0), " error");
        listingOrders[orderId] = order;

        _lastIds[nft][tokenId] = orderId;

        emit List(nft, tokenId, orderId, msg.sender, payToken, price, deadLine);
    }

    //离线签名上架
    function list(LimitOrder memory _listOrder) public {
        require(_listOrder.deadLine > 0, "deadline is in the past");
        require(_listOrder.price > 0, "Price must be greater than zero");
        require(
            _listOrder.payToken == address(0) ||
                IERC20(_listOrder.payToken).totalSupply() > 0,
            "token is error"
        );

        // safe check
        require(
            IERC721(_listOrder.nft).ownerOf(_listOrder.tokenId) == msg.sender,
            "not Owner"
        );

        bytes32 hashTypeData = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _LIMIT_ORDER_TYPE_HASH,
                    _listOrder.seller,
                    _listOrder.nft,
                    _listOrder.tokenId,
                    _listOrder.price,
                    _listOrder.deadLine
                )
            )
        );
        address signature = ECDSA.recover(hashTypeData, _listOrder.signature);
        // require(signature != _listOrder.seller, "singnature error");

        SellerOrder memory order = SellerOrder({
            seller: _listOrder.seller,
            nft: _listOrder.nft,
            tokenId: _listOrder.tokenId,
            payToken: _listOrder.payToken,
            price: _listOrder.price,
            deadLine: _listOrder.deadLine
        });
        bytes32 orderId = keccak256(abi.encode(order));
        listingOrders[orderId] = order;
        _lastIds[_listOrder.nft][_listOrder.tokenId] = orderId;

        emit List(
            _listOrder.nft,
            _listOrder.tokenId,
            orderId,
            msg.sender,
            _listOrder.payToken,
            _listOrder.price,
            _listOrder.deadLine
        );
    }

    // 取消上架
    function cancel(bytes32 orderId) external {
        address seller = listingOrders[orderId].seller;
        require(msg.sender != address(0), "address error");
        require(msg.sender == seller, "only self can cancel");
        delete listingOrders[orderId];
        emit Cancel(orderId);
    }

    function buy(bytes32 orderId) external {
        // 可能有费率
        _buy(orderId, feeTo);
    }

    function _buy(
        bytes32 orderId,
        bytes calldata signatureForWL
    ) public payable {
        _checkWL(signatureForWL);

        _buy(orderId, address(0));
    }

    function _buy(bytes32 orderId, address feeReceiver) private {
        SellerOrder memory order = listingOrders[orderId];
        require(order.seller != address(0), "address error");
        require(order.deadLine > block.timestamp, "deadline is in the past");

        //防重复
        delete listingOrders[orderId];

        //
        IERC721(order.nft).safeTransferFrom(
            order.seller,
            msg.sender,
            order.tokenId
        );
        // 确定币种
        uint256 fee = feeReceiver == address(0)
            ? 0
            : (order.price * feeBP) / 10000;
        if (order.payToken == address(0)) {
            require(msg.value == order.price + fee, "price error");
        } else {
            require(msg.value == 0, "price error");
        }
        _transferOut(order.payToken, order.seller, order.price - fee);
        if (fee > 0) _transferOut(order.payToken, feeReceiver, fee);
        emit Sold(orderId, order.seller, msg.sender, fee);
    }

    function _transferOut(address token, address to, uint256 amount) private {
        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "transfer error");
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, to, amount);
        }
    }

    bytes32 constant WL_TYPEHASH = keccak256("IsWhiteList(address user)");

    function _checkWL(bytes calldata signature) private view {
        bytes32 wlHash = _hashTypedDataV4(
            keccak256(abi.encode(WL_TYPEHASH, msg.sender))
        );
        address signer = ECDSA.recover(wlHash, signature);
        require(signer == whiteListSigner, "whList error");
    }

    event List(
        address indexed nft,
        uint256 indexed tokenId,
        bytes32 orderId,
        address seller,
        address payToken,
        uint256 price,
        uint256 deadLine
    );

    event NFTBought(
        uint256 indexed tokenId,
        uint256 price,
        address indexed buyer,
        address indexed seller
    );
    event Sold(
        bytes32 indexed orderId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );
    event Cancel(bytes32 orderId);

    event SetFeeTo(address to);
}
