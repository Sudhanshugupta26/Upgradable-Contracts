// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NotUUPS {
    uint256 public value;
}

contract DeployAndUpgradeTest is Test {
    DeployBox public deployer;
    UpgradeBox public upgrader;
    address public OWNER = makeAddr("owner");

    address public proxy;

    function setUp() public {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();
        proxy = deployer.run(); // points to BoxV1 currently.
    }

    function testProxyStartsAsBoxV1() public {
        vm.expectRevert();
        BoxV2(proxy).setNumber(7);
    }

    function testUpgrades() public {
        BoxV2 box2 = new BoxV2();
        upgrader.upgradeBox(proxy, address(box2));

        uint256 expectedValue = 2;
        assertEq(expectedValue, BoxV2(proxy).version());

        BoxV2(proxy).setNumber(8);
        assertEq(8, BoxV2(proxy).getNumber());
    }

    function testDeployBoxDirectPath() public {
        address deployedProxy = deployer.deployBox();
        assertEq(1, BoxV1(deployedProxy).version());
    }

    function testInitializeV1ThroughProxySetsOwnerAndCannotReinitialize() public {
        BoxV1(proxy).initialize();
        assertEq(BoxV1(proxy).owner(), address(this));

        vm.expectRevert();
        BoxV1(proxy).initialize();
    }

    function testV1ImplementationInitializeIsDisabled() public {
        BoxV1 implementation = new BoxV1();

        vm.expectRevert();
        implementation.initialize();
    }

    function testInitializeV2ThroughFreshProxy() public {
        BoxV2 implementation = new BoxV2();
        ERC1967Proxy localProxy = new ERC1967Proxy(address(implementation), "");

        BoxV2 proxiedV2 = BoxV2(address(localProxy));
        proxiedV2.initialize();

        assertEq(proxiedV2.owner(), address(this));
        assertEq(2, proxiedV2.version());
    }

    function testUpgradeAgainFromV2() public {
        BoxV2 firstImpl = new BoxV2();
        upgrader.upgradeBox(proxy, address(firstImpl));

        BoxV2 secondImpl = new BoxV2();
        BoxV2(proxy).upgradeToAndCall(address(secondImpl), "");

        assertEq(2, BoxV2(proxy).version());
    }

    function testBoxV1DefaultNumberIsZero() public view {
        assertEq(0, BoxV1(proxy).getNumber());
    }

    function testBoxV1ProxiableUUIDOnImplementation() public {
        BoxV1 implementation = new BoxV1();
        bytes32 expectedSlot =
            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        assertEq(expectedSlot, implementation.proxiableUUID());
    }

    function testBoxV1ProxiableUUIDRevertsThroughProxy() public {
        vm.expectRevert();
        BoxV1(proxy).proxiableUUID();
    }

    function testBoxV1UpgradeToAndCallRevertsOnImplementation() public {
        BoxV1 implementation = new BoxV1();
        BoxV2 newImplementation = new BoxV2();

        vm.expectRevert();
        implementation.upgradeToAndCall(address(newImplementation), "");
    }

    function testUpgradeBoxReturnsProxyAddress() public {
        BoxV2 newImplementation = new BoxV2();
        address returnedProxy = upgrader.upgradeBox(proxy, address(newImplementation));
        assertEq(proxy, returnedProxy);
    }

    function testUpgradeBoxRevertsForNonUUPSImplementation() public {
        NotUUPS badImplementation = new NotUUPS();
        vm.expectRevert();
        upgrader.upgradeBox(proxy, address(badImplementation));
    }
}
