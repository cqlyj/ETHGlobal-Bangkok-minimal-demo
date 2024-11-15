// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import {Registry} from "./Registry.sol";
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

event AccountCreated(address indexed to,address indexed campaign, uint256 tokenId);

interface ILogAutomation {
    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

contract ChainlinkCreator is ILogAutomation {
    Registry public registry;
    address public implementationContractAddress;
    bytes32 public salt = bytes32(0);

    constructor(
        address _registryAddress,
        address _implementationContractAddress
    ) {
        registry = Registry(_registryAddress);
        implementationContractAddress = _implementationContractAddress;
    }

    function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        address user = bytes32ToAddress(log.topics[1]);
        address campaign = bytes32ToAddress(log.topics[2]);
        uint256 tokenId = uint256(log.topics[3]);

        performData = abi.encode(user,campaign, tokenId);
    }

    function performUpkeep(bytes calldata performData) external override {
        // createAccount(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
        (address user,address campaign, uint256 tokenId) = abi.decode(
            performData,
            (address,address, uint256)
        );

        registry.createAccount(
            implementationContractAddress,
            salt,
            block.chainid,
            campaign,
            tokenId
        );

        emit AccountCreated(user,campaign,tokenId);
    }

    function bytes32ToAddress(bytes32 _address) public pure returns (address) {
        return address(uint160(uint256(_address)));
    }
}