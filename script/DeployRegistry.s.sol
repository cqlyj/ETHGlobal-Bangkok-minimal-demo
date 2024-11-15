// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {Registry} from "src/Registry.sol";

contract DeployRegistry is Script {
    // update this!
    address public constant CHAINLINK_MINTER = 0x2ae675f229efEAe01D4F0C12E5cD5218633600E4;

    function run() external returns (Registry) {
        vm.startBroadcast();
        Registry registry = new Registry(CHAINLINK_MINTER);
        vm.stopBroadcast();
        return (registry);
    }
}
