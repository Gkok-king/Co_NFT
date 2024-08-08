// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./NFTMarketTeach.sol";

import "@openzeppelin/contracts/utils/Multicall.sol";

contract AirdopMerkleNFTMarket is NFTMarketTeach, Multicall {
    bytes32 public merkleRoot;

    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }

    // 领取NFT
    function claimNFT(
        bytes32[] calldata merkleProof,
        bytes32 orderId,
        address tokenAddress
    ) public {
        require(
            verify(merkleProof, keccak256(abi.encodePacked(msg.sender))),
            "Invalid proof."
        );
        require(listingOrders[orderId].nft != address(0), "nft not found");

        // 可以转出
        // _buy(orderId, tokenAddress);
    }

    //验证merkle 节点
    function verify(
        bytes32[] memory proof,
        bytes32 leaf
    ) public view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the stored root
        return computedHash == merkleRoot;
    }
}
