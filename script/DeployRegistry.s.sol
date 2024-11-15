// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {Registry} from "src/Registry.sol";

contract DeployRegistry is Script {
    // update this!
    address public constant CHAINLINK_MINTER = 0xc4AF4399Cc447f8eAfdb8F08E8fF74F8d5157f81;

    function run() external returns (Registry) {
        vm.startBroadcast();
        Registry registry = new Registry(CHAINLINK_MINTER);
        vm.stopBroadcast();
        return (registry);
    }
}
