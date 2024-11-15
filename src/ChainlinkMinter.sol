// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import {IAccountImplementation} from "../src/interfaces/IAccountImplementation.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {DummyContract} from "./DummyContract.sol";

contract ChainlinkMinter is AutomationCompatibleInterface {
    bool public s_accountCreated;
    DummyContract public dummyContract;

    constructor(address _dummyContract) {
        s_accountCreated = false;
        dummyContract = DummyContract(_dummyContract);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        if (s_accountCreated) {
            upkeepNeeded = true;
        } else {
            upkeepNeeded = false;
        }
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        address user = dummyContract.user();
        address campaign = dummyContract.campaign();
        address account = dummyContract.account();
        IAccountImplementation(account).initialize(user);
        IAccountImplementation(account).mintInteractionNFT(campaign);
        s_accountCreated = false;
    }

    function setAccountCreated(bool created) external {
        s_accountCreated = created;
    }
}
