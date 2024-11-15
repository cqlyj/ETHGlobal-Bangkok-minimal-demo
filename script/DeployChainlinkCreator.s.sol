// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {ChainlinkCreator} from "src/ChainlinkCreator.sol";

contract DeployChainlinkCreator is Script {
    address public constant ACCOUNT_IMPLEMENTATION_ADDRESS = 0xa6eEE68A4324F8DA953dA58DbC9C05781EbB04F9;
    address public constant REGISTRY_ADDRESS = 0x0094535d9E395a92dD4e49A18DA4827B90D4AaDD;

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
