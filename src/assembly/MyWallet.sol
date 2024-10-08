// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MyWallet {
    string public name;
    mapping(address => bool) approved;
    address private _owner;

    modifier auth() {
        require(msg.sender == owner(), "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        setOwner(msg.sender);
    }

    function owner() public view returns (address ownerAddress) {
        assembly {
            ownerAddress := sload(_owner.slot)
        }
    }

    function setOwner(address _addr) internal {
        assembly {
            sstore(_owner.slot, _addr)
        }
    }

    function transferOwernship(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        require(owner() != _addr, "New owner is the same as the old owner");
        setOwner(_addr);
    }
}
