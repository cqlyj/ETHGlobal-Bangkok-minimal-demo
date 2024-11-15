// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {ChainlinkMinter} from "src/ChainlinkMinter.sol";

contract DeployChainlinkMinter is Script {
    address public constant ACCOUNT_IMPLEMENTATION_ADDRESS = 0xa6eEE68A4324F8DA953dA58DbC9C05781EbB04F9;

    function run() external returns (ChainlinkMinter) {
        vm.startBroadcast();
        ChainlinkMinter chainlinkMinter = new ChainlinkMinter(
            ACCOUNT_IMPLEMENTATION_ADDRESS
        );
        vm.stopBroadcast();
        return (chainlinkMinter);
    }
}
