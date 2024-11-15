// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {DummyContract} from "src/DummyContract.sol";

contract DeployDummyContract is Script {
    function run() external returns (DummyContract) {
        vm.startBroadcast();
        DummyContract dummyContract = new DummyContract();
        vm.stopBroadcast();
        return (dummyContract);
    }
}
