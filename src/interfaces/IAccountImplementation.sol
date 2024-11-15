// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IAccountImplementation {
    function setApprovedMinter(address minter) external;

    function initialize(address to) external;

    function mintInteractionNFT(address campaign) external;
}
