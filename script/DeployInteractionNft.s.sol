// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {InteractionNft} from "src/InteractionNft.sol";

contract DeployInteractionNft is Script {
    function run() external returns (InteractionNft) {
        vm.startBroadcast();
        InteractionNft interactionNft = new InteractionNft();
        vm.stopBroadcast();
        return (interactionNft);
    }
}
