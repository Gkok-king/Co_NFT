// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/nft/AirdopMerkleNFTMarket.sol";
import "../../src/token/FoolCoToken.sol";

contract AirdopMerkleNFTMarketTest is Test {
    AirdopMerkleNFTMarket market;
    FoolCoToken token;
    Account admin = makeAccount("admin");
    address A = makeAddr("0xf69Ca530Cd4849e3d1329FBEC06787a96a3f9A68");

    function setUp() public {
        vm.startPrank(admin);
        bytes32 root = 0x4d391566fe6a949654a1da6b9afda4ecda69d6046bce3694e953c5b64c63ea47;
        token = new FoolCoToken();
        market = new AirdopMerkleNFTMarket(root);
        vm.stopPrank();
    }

    // just mock process ,data is error
    function test_AirdopMerkleNFTMarketTest_muticall() public {
        bytes[] memory data = new bytes[](2);
        // data.push();

        // _permit
        // mock signature
        bytes memory signature = 0x1313454645;
        data[0] = abi.encodeWithSelector(
            market._permit.selector,
            admin.addr,
            A,
            1000,
            signature
        );

        //  claimNFT
        bytes[] memory proof = new bytes[](2);
        proof.push(
            0xd24d002c88a75771fc4516ed00b4f3decb98511eb1f7b968898c2f454e34ba23
        );
        proof.push(
            0x4e48d103859ea17962bdf670d374debec88b8d5f0c1b6933daa9eee9c7f4365b
        );

        data[1] = abi.encodeWithSelector(
            token.claimNFT.selector,
            proof,
            keccak256(abi.encodePacked(A, address(token), uint256(1))),
            address(token) // 假设为 ETH 支付
        );

        market.multicall(data);
    }
}
