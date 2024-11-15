// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import {IAccountImplementation} from "../src/interfaces/IAccountImplementation.sol";

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
    function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        address user = bytes32ToAddress(log.topics[1]);
        address campaign = bytes32ToAddress(log.topics[2]);
        address account = bytes32ToAddress(log.topics[3]);
        performData = abi.encode(user, campaign, account);
    }

    function performUpkeep(bytes calldata performData) external override {
        (address user, address campaign, address account) = abi.decode(
            performData,
            (address, address, address)
        );
        IAccountImplementation(account).initialize(user);
        IAccountImplementation(account).mintInteractionNFT(campaign);
    }

    function bytes32ToAddress(bytes32 _address) public pure returns (address) {
        return address(uint160(uint256(_address)));
    }
}
