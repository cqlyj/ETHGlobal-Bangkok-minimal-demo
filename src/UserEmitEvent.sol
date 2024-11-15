// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Campaign} from "./Campaign.sol";

contract UserEmitEvent {
    event UserEvent(
        address indexed user,
        address indexed campaign,
        uint256 indexed tokenId
    );

    function interactWithCampaign(address campaign) public {
        uint256 tokenId = Campaign(campaign).getTokenId();
        emit UserEvent(msg.sender, campaign, tokenId);
    }
}
