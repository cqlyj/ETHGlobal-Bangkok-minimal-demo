// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract InteractionNft is ERC721URIStorage {
    using Strings for address;
    using Strings for uint256;

    struct LinkedCampaign {
        address campaignAddress;
        uint256 shares;
        uint256 likes;
    }

    mapping(uint256 interactionNftId => LinkedCampaign)
        private s_interactionIdToLinkedCampaigns;
    uint256 private s_tokenId;

    event InteractionNFTMinted(
        uint256 indexed interactionNFTId,
        address indexed campaignAddress
    );

    constructor() ERC721("InteractionNFT", "INFT") {}

    function mintLinkedNFT(
        address to,
        address campaignAddress
    ) internal returns (uint256 interactionNFTId) {
        _safeMint(to, s_tokenId);
        s_interactionIdToLinkedCampaigns[s_tokenId] = LinkedCampaign({
            campaignAddress: campaignAddress,
            shares: 0,
            likes: 0
        });

        // store a tokenURI to reference additional metadata
        string memory tokenURI = generateTokenURI(
            LinkedCampaign({
                campaignAddress: campaignAddress,
                shares: 0,
                likes: 0
            })
        );
        _setTokenURI(interactionNFTId, tokenURI);

        s_tokenId++;
        emit InteractionNFTMinted(s_tokenId, campaignAddress);
    }

    function generateTokenURI(
        LinkedCampaign memory linkedCampaign
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"name": "InteractionNFT",',
                                '"description": "An NFT linked to a campaign interaction.",',
                                '"attributes": [',
                                '{"trait_type": "CampaignNFT", "value": "',
                                linkedCampaign.campaignAddress.toHexString(),
                                '"},',
                                '{"trait_type": "Shares", "value": "',
                                linkedCampaign.shares.toString(),
                                '"},',
                                '{"trait_type": "Shares", "value": "',
                                linkedCampaign.likes.toString(),
                                '"},',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }
}
