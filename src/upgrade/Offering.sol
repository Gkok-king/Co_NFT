// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//铭文 存储数据 相当于代理合约
contract Offering {
    // 常量来表示插槽位置
    bytes32 private constant IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("offering.storage.slot")));
    bytes32 private constant ADMIN_SLOT =
        bytes32(uint256(keccak256("offering.storage.slot")) - 1);

    constructor(address _implementation, address _admin) {
        bytes32 _implementationSlot = IMPLEMENTATION_SLOT;
        bytes32 _adminSlot = ADMIN_SLOT;
        assembly {
            // 将值存储到指定插槽
            sstore(_implementationSlot, _implementation)
            sstore(_adminSlot, _admin)
        }
    }

    fallback() external payable {
        // bytes32 _implementationSlot;
        // assembly {
        //     impl := _implementationSlot
        // }
        // impl.delegateCall(abi.encodeWithSignature("increment()")  );
    }

    function upgradeTo(address newImplementation) external {
        address admin;
        assembly {
            admin := sload(newImplementation)
        }
        require(msg.sender == admin, "Only admin can upgrade");
    }

    receive() external payable {}
}
