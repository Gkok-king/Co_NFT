// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "src/upgrade/FactoryV1.sol";
import "src/upgrade/FactoryV2.sol";
import "src/upgrade/InscriptionToken.sol";

contract FactoryV1Test is Test {
    ERC1967Proxy proxy;
    FactoryV1 public factoryV1;
    FactoryV2 public factoryV2;

    address admin = makeAddr("admin");
    address A = makeAddr("A");
    address B = makeAddr("B");

    function setUp() public {
        vm.startPrank(admin);
        FactoryV1 impl = new FactoryV1();
        factoryV2 = new FactoryV2();
        vm.stopPrank();

        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(impl.initialize, admin)
        );
        factoryV1 = FactoryV1(address(proxy));
    }

    function test_FactoryV1Test_deploy() public {
        uint256 perMint = 10;
        vm.startPrank(A);
        address a1 = factoryV1.deployInscription("AToken", "AT", 1000, perMint);
        factoryV1.mintInscription(a1);

        // 部署 mint 一个
        uint256 _banlance = InscriptionToken(a1).balanceOf(A);
        vm.stopPrank();
        assertEq(perMint, _banlance);
    }

    //测试升级
    function test_FactoryV1Test_upgrade() public {
        vm.startPrank(A);
        uint256 perMint = 1;
        address a1 = factoryV1.deployInscription("AToken", "AT", 1000, perMint);
        factoryV1.mintInscription(a1);
        vm.stopPrank();

        //升级合约
        Upgrades.upgradeProxy(
            address(proxy),
            "FactoryV2.sol:FactoryV2",
            "",
            admin
        );
        vm.startPrank(A);
        vm.expectRevert("Incorrect Ether value");
        factoryV1.mintInscription(a1);
        vm.stopPrank();
    }
}
