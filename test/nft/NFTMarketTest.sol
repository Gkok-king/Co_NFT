// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../../src/nft/FoolCoNFT.sol";
import "../../src/nft/NFTMarket.sol";
import "../../src/token/FoolCoToken.sol";
import {Test, console} from "forge-std/Test.sol";

// 1 上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
// 2 购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
// 3 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
// 「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
contract NFTMarketTest is Test {
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
    FoolCoToken public foolCoToken;
    FoolCoNFT public foolCoNFT;
    NFTMarket public nftMarket;
    address tokenOwner = makeAddr("tokenOwner");
    address nftOwner = makeAddr("nftOwner");
    address marketOwner = makeAddr("marketOwner");
    address A = makeAddr("A");
    address B = makeAddr("B");

    function setUp() public {
        initFoolCoToken();
        initFoolCoNFT();
        initNFTMarket(foolCoToken, foolCoNFT);
    }

    //初始化FoolCoToken
    function initFoolCoToken() public {
        vm.startPrank(tokenOwner);
        foolCoToken = new FoolCoToken();
        vm.stopPrank();
    }

    // 初始化FoolCoNFT
    function initFoolCoNFT() public {
        vm.startPrank(nftOwner);
        foolCoNFT = new FoolCoNFT();
        foolCoNFT.mint(nftOwner, "0x10xxxxxxxxxxA");
        vm.stopPrank();
    }

    // 初始化NFTMarket
    function initNFTMarket(FoolCoToken token, FoolCoNFT nft) public {
        vm.startPrank(marketOwner);
        nftMarket = new NFTMarket(token, nft);
        vm.stopPrank();
    }

    //测试上架成功 及成功的事件
    function test_list_Succ() public {
        //初始化
        setUp();
        // 给nftOwner 授权，然后给一些token

        vm.startPrank(nftOwner);
        foolCoNFT.approve(address(nftMarket), 0);
        vm.expectEmit(true, true, true, false);
        emit NFTListed(0, 100, nftOwner);
        nftMarket.list(0, 100);
        vm.stopPrank();
    }

    //测试上架失败  断言错误信息
    function test_list_fail() public {
        //初始化
        setUp();
        vm.prank(A);
        vm.expectRevert("Not the owner");
        nftMarket.list(0, 0);
    }

    // 测试购买成功
    function test_buy_success() public {
        setUp();

        // 上架NFT
        vm.startPrank(nftOwner);
        foolCoNFT.approve(address(nftMarket), 0);
        nftMarket.list(0, 100);
        vm.stopPrank();

        // 给buyer一些token并授权
        vm.startPrank(tokenOwner);
        foolCoToken.transfer(A, 200);
        vm.stopPrank();

        vm.startPrank(A);
        foolCoToken.approve(address(nftMarket), 100);
        vm.expectEmit(true, true, true, false);
        emit NFTBought(0, 100, A, nftOwner);
        nftMarket.buyNFT(0);
        vm.stopPrank();
    }

    // 测试自己购买自己的NFT
    function test_buy_own_nft() public {
        setUp();
        vm.startPrank(tokenOwner);
        foolCoToken.approve(nftOwner, 100);

        //  nftOwner 作为买家，需要将持有的Token授权给Market
        foolCoToken.transfer(nftOwner, 100);
        vm.stopPrank();

        // 铸造一个NFT给用户
        vm.prank(nftOwner);
        foolCoNFT.mint(nftOwner, "tokenURI");

        // 用户将持有的Token授权给Market
        vm.prank(nftOwner);
        foolCoToken.approve(address(nftMarket), 100);

        // 用户将NFT上架到市场
        vm.prank(nftOwner);
        foolCoNFT.approve(address(nftMarket), 0);

        vm.prank(nftOwner);
        nftMarket.list(0, 100);

        // 用户尝试购买自己的NFT
        vm.startPrank(nftOwner);

        nftMarket.buyNFT(0);
        vm.stopPrank();
        // 检查用户的NFT所有权和代币余额
        assertEq(
            foolCoNFT.ownerOf(0),
            nftOwner,
            "User should still own the NFT"
        );
    }

    // 测试NFT被重复购买
    function test_buy_nft_twice() public {
        setUp();

        // 上架NFT
        vm.startPrank(nftOwner);
        foolCoNFT.approve(address(nftMarket), 0);
        nftMarket.list(0, 100);
        vm.stopPrank();

        // A购买NFT
        vm.startPrank(tokenOwner);
        foolCoToken.transfer(A, 200);
        vm.stopPrank();

        vm.startPrank(A);
        foolCoToken.approve(address(nftMarket), 100);
        nftMarket.buyNFT(0);
        vm.stopPrank();

        // B尝试购买已经被购买的NFT
        vm.startPrank(tokenOwner);
        foolCoToken.transfer(B, 200);
        vm.stopPrank();

        vm.startPrank(B);
        foolCoToken.approve(address(nftMarket), 100);
        vm.expectRevert("NFT not listed for sale");
        nftMarket.buyNFT(0);
        vm.stopPrank();
    }

    // 测试支付Token过多的情况
    function test_buy_overpay() public {
        setUp();
        // 上架NFT
        vm.startPrank(nftOwner);
        foolCoNFT.approve(address(nftMarket), 0);
        nftMarket.list(0, 100);
        vm.stopPrank();

        // A尝试支付过多的Token
        vm.startPrank(tokenOwner);
        foolCoToken.transfer(A, 200);
        vm.stopPrank();

        vm.startPrank(A);
        foolCoToken.approve(address(nftMarket), 200);
        nftMarket.buyNFT(0);
        vm.stopPrank();
    }

    // 测试支付Token过少的情况
    function test_buy_underpay() public {
        setUp();

        vm.startPrank(tokenOwner);
        foolCoToken.approve(A, 50);
        vm.stopPrank();
        // 上架NFT
        vm.startPrank(nftOwner);
        foolCoNFT.approve(address(nftMarket), 0);
        nftMarket.list(0, 100);
        vm.stopPrank();

        // A尝试支付过少的Token
        vm.startPrank(tokenOwner);
        foolCoToken.transfer(A, 50);
        vm.stopPrank();

        vm.startPrank(A);
        foolCoToken.approve(address(nftMarket), 100);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)",
                address(A),
                50,
                100
            )
        );

        nftMarket.buyNFT(0);
        vm.stopPrank();
    }

    // 模糊测试上架
    function test_fuzz_list(uint256 price) public {
        // 限制价格范围在0.01到10000 Token之间
        price = bound(price, 1, 10000);

        // 初始化
        setUp();
        vm.startPrank(nftOwner);
        foolCoNFT.approve(address(nftMarket), 0);
        vm.expectEmit(true, true, true, false);
        emit NFTListed(0, price, nftOwner);
        nftMarket.list(0, price);
        vm.stopPrank();
    }

    // 模糊测试购买NFT
    function test_fuzz_buy(address buyer) public {
        // 过滤掉0地址
        vm.assume(buyer != address(0));

        // 初始化
        setUp();
        // 给nftOwner授权，然后给一些token
        vm.startPrank(tokenOwner);
        foolCoToken.approve(nftOwner, 1000);
        foolCoToken.transfer(nftOwner, 1000);
        vm.stopPrank();

        vm.startPrank(nftOwner);
        foolCoNFT.approve(address(nftMarket), 0);
        nftMarket.list(0, 100);
        vm.stopPrank();

        // 给buyer一些token
        vm.startPrank(tokenOwner);
        foolCoToken.transfer(buyer, 200);
        vm.stopPrank();

        vm.startPrank(buyer);
        console.log(address(nftMarket));
        foolCoToken.approve(address(nftMarket), 100);
        vm.expectEmit(true, true, true, false);
        emit NFTBought(0, 100, buyer, nftOwner);
        nftMarket.buyNFT(0);
        vm.stopPrank();
    }
}
