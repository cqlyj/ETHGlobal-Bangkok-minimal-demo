// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Campaign is ERC721URIStorage, Ownable {
    using Strings for uint256;
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct CampaignInfo {
        uint256 timeInterval; // time interval for the campaign,
        uint256 startTime; // start time of the campaign
        uint256 nftCount; // number of NFTs to be distributed
        string description; // reference to IPFS link
        string[] uniqueLinks; // links valid for taking into account the reward
        string imageURI; // image for the campaign
        uint256 rewardParticipants; // number of participants to be rewarded,
        uint256 rewardAmount; // total reward amount
        string tokenURI; // token URI
        CampaignStatus active; // if the campaign is active
    }

    enum CampaignStatus {
        ACTIVE,
        INACTIVE,
        COMPLETED
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 private s_tokenId;
    uint256 private s_minimalRewardAmount;
    uint256 private constant MINIMAL_TIME_INTERVAL = 1 days;
    uint256 private constant TIME_BEFORE_START = 1 days;
    mapping(address campaignOwner => CampaignInfo[])
        private s_creatorsToCampaigns;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Campaign__timeIntervalTooShort();
    error Campaign__rewardAmountTooLow();
    error Campaign__rewardParticipantsGreaterThanNftCount();
    error Campaign__NotEnoughTimePassed();
    error Campaign__TransferFailed();
    error Campaign__AlreadyCompleted();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event CampaignCreated(
        address to,
        uint256 timeInterval,
        uint256 startTime,
        uint256 nftCount,
        string description,
        string[] uniqueLinks,
        string imageURI,
        uint256 rewardParticipants,
        uint256 rewardAmount,
        string tokenURI
    );

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier timeIntervalEnough(uint256 timeInterval) {
        if (timeInterval < MINIMAL_TIME_INTERVAL) {
            revert Campaign__timeIntervalTooShort();
        }
        _;
    }

    modifier rewardAmountEnough(uint256 rewardAmount) {
        if (rewardAmount < s_minimalRewardAmount) {
            revert Campaign__rewardAmountTooLow();
        }
        _;
    }

    modifier participantsLessThanNftCount(
        uint256 nftCount,
        uint256 rewardParticipants
    ) {
        if (rewardParticipants > nftCount) {
            revert Campaign__rewardParticipantsGreaterThanNftCount();
        }
        _;
    }

    modifier enoughTimePassedBeforeStart(uint256 startTime) {
        if (block.timestamp < startTime) {
            revert Campaign__NotEnoughTimePassed();
        }
        _;
    }

    modifier campaignNotCompleted(CampaignStatus active) {
        if (active == CampaignStatus.COMPLETED) {
            revert Campaign__AlreadyCompleted();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTORS
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("campaign", "CP") Ownable(msg.sender) {
        s_tokenId = 0;
        s_minimalRewardAmount = 1e17; // 0.1 ETH
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // This will create a campaign and when time passes, creator can activate the campaign or revert it
    function createCampaign(
        address to,
        uint256 timeInterval,
        uint256 nftCount,
        string memory description,
        string[] memory uniqueLinks,
        string memory imageURI,
        uint256 rewardParticipants
    )
        external
        payable
        timeIntervalEnough(timeInterval)
        rewardAmountEnough(msg.value)
        participantsLessThanNftCount(nftCount, rewardParticipants)
    {
        string memory links = "[";
        for (uint256 i = 0; i < uniqueLinks.length; i++) {
            links = string(abi.encodePacked(links, '"', uniqueLinks[i], '"'));
            if (i < uniqueLinks.length - 1) {
                links = string(abi.encodePacked(links, ", "));
            }
        }
        links = string(abi.encodePacked(links, "]"));

        string memory json = string(
            abi.encodePacked(
                "{",
                '"timeInterval": "',
                (block.timestamp + TIME_BEFORE_START).toString(),
                '", ',
                '"startTime": "',
                block.timestamp.toString(),
                '", ',
                '"nftCount": "',
                nftCount.toString(),
                '", ',
                '"description": "',
                description,
                '", ',
                '"uniqueLinks": ',
                links,
                ", ",
                '"imageURI": "',
                imageURI,
                '", ',
                '"rewardParticipants": "',
                rewardParticipants.toString(),
                '", ',
                '"rewardAmount": "',
                msg.value.toString(),
                '"',
                "}"
            )
        );

        string memory tokenURI = string(
            abi.encodePacked(_baseURI(), Base64.encode(bytes(json)))
        );

        s_creatorsToCampaigns[to].push(
            CampaignInfo(
                timeInterval,
                block.timestamp + TIME_BEFORE_START,
                nftCount,
                description,
                uniqueLinks,
                imageURI,
                rewardParticipants,
                msg.value,
                tokenURI,
                CampaignStatus.INACTIVE
            )
        );

        emit CampaignCreated(
            to,
            timeInterval,
            block.timestamp + TIME_BEFORE_START,
            nftCount,
            description,
            uniqueLinks,
            imageURI,
            rewardParticipants,
            msg.value,
            tokenURI
        );
    }

    // only the 1 day constant time passed can determine if the campaign is active
    // to prevent the creator from wrongly activating the campaign or stick too much reward
    function updateCampaignStatus(
        uint256 index,
        bool active
    )
        external
        enoughTimePassedBeforeStart(
            s_creatorsToCampaigns[msg.sender][index].startTime
        )
        campaignNotCompleted(s_creatorsToCampaigns[msg.sender][index].active)
    {
        // if the campaign is active, mint the NFT
        if (active == true) {
            s_creatorsToCampaigns[msg.sender][index].active = CampaignStatus
                .ACTIVE;
            _safeMint(msg.sender, s_tokenId);
            _setTokenURI(
                s_tokenId,
                s_creatorsToCampaigns[msg.sender][index].tokenURI
            );
            s_tokenId++;
        } else {
            // if the campaign is not active, return the reward
            // mark the campaign as completed so that the creator can't claim the reward again
            uint256 rewardAmount = s_creatorsToCampaigns[msg.sender][index]
                .rewardAmount;
            (bool success, ) = msg.sender.call{value: rewardAmount}("");
            if (!success) {
                revert Campaign__TransferFailed();
            }
            s_creatorsToCampaigns[msg.sender][index].active = CampaignStatus
                .COMPLETED;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setMinimalRewardAmount(
        uint256 minimalRewardAmount
    ) external onlyOwner {
        s_minimalRewardAmount = minimalRewardAmount;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getTokenId() external view returns (uint256) {
        return s_tokenId;
    }

    function getMinimalRewardAmount() external view returns (uint256) {
        return s_minimalRewardAmount;
    }

    function getCreatorsCampaigns(
        address creator
    ) external view returns (CampaignInfo[] memory) {
        return s_creatorsToCampaigns[creator];
    }
}
