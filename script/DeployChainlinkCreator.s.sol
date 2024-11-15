// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {ChainlinkCreator} from "src/ChainlinkCreator.sol";

contract DeployChainlinkCreator is Script {
    address public constant ACCOUNT_IMPLEMENTATION_ADDRESS = 0xa6eEE68A4324F8DA953dA58DbC9C05781EbB04F9;
    address public constant REGISTRY_ADDRESS = 0x14Aef3d49F94E380b7f29897e81F9D092BEEDF4E;

    function run() external returns (ChainlinkCreator) {
        vm.startBroadcast();
        ChainlinkCreator chainlinkCreator = new ChainlinkCreator(
            REGISTRY_ADDRESS,
            ACCOUNT_IMPLEMENTATION_ADDRESS
        );
        vm.stopBroadcast();
        return (chainlinkCreator);
    }
}
