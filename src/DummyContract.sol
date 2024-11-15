// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract DummyContract {
    address public user;
    address public campaign;
    address public account;

    function setUser(address _user) external {
        user = _user;
    }

    function setCampaign(address _campaign) external {
        campaign = _campaign;
    }

    function setAccount(address _account) external {
        account = _account;
    }
}
