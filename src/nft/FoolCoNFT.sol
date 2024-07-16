// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FoolCoNFT is ERC721, ERC721URIStorage, Ownable {
    // 自定义错误
    error TokenNonexistent(uint256 tokenId);
    error ZeroAddress();

    // toekn的Id的计数
    uint256 private tokenIdCounter;
    // ntf的数量
    uint256 private totalSupply;
    // token的id 和地址
    mapping(uint256 => string) private tokenURIs;

    event Mint(address indexed to, uint256 indexed tokenId, string tokenURI);

    constructor() ERC721("foolCo", "FC") Ownable(msg.sender) {
        totalSupply = 0;
    }

    // 铸造nft
    function mint(address to, string memory _tokenURI) public onlyOwner {
        uint256 tokenId = tokenIdCounter;
        tokenIdCounter += 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        emit Mint(to, tokenId, _tokenURI);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert TokenNonexistent(tokenId);
        }
        //元数组的
        string memory _tokenURI = tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
