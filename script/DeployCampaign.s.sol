// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {Campaign} from "src/Campaign.sol";

contract DeployCampaign is Script {
    function run() external returns (Campaign) {
        vm.startBroadcast();
        Campaign campaign = new Campaign();
        vm.stopBroadcast();
        return (campaign);
    }
}
