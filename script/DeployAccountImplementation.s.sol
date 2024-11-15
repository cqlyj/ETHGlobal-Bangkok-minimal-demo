// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {AccountImplementation} from "src/AccountImplementation.sol";

contract DeployAccountImplementation is Script {
    function run() external returns (AccountImplementation) {
        vm.startBroadcast();
        AccountImplementation accountImplementation = new AccountImplementation();
        vm.stopBroadcast();
        return (accountImplementation);
    }
}
