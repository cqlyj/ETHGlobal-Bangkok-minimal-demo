// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import {AccountImplementation} from "./AccountImplementation.sol";

struct Log {
    uint256 index; // Index of the log in the block
    uint256 timestamp; // Timestamp of the block containing the log
    bytes32 txHash; // Hash of the transaction containing the log
    uint256 blockNumber; // Number of the block containing the log
    bytes32 blockHash; // Hash of the block containing the log
    address source; // Address of the contract that emitted the log
    bytes32[] topics; // Indexed topics of the log
    bytes data; // Data of the log
}

interface ILogAutomation {
    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

contract ChainlinkMinter is ILogAutomation {
    AccountImplementation public accountImplementation;

    constructor(address _accountImplementationAddress) {
        accountImplementation = AccountImplementation(
            payable(_accountImplementationAddress)
        );
    }

    function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        address user = bytes32ToAddress(log.topics[1]);
        address campaign = bytes32ToAddress(log.topics[2]);
        performData = abi.encode(user, campaign);
    }

    function performUpkeep(bytes calldata performData) external override {
        (address user, address campaign) = abi.decode(
            performData,
            (address, address)
        );
        accountImplementation.initialize(user);
        accountImplementation.mintInteractionNFT(campaign);
    }

    function bytes32ToAddress(bytes32 _address) public pure returns (address) {
        return address(uint160(uint256(_address)));
    }
}
