// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";

import "../interfaces/IOwnerManager.sol";

/**
 * OwnerManager contract for smart account
 */
contract OwnerManager is IOwnerManager, Ownable {

    constructor(address swOwner) {
        require(swOwner != address(0));
        SmartWalletOwner = swOwner;
    }

    address private SmartWalletOwner;

    function getSmartWalletOwner() public view returns (address) {
        return SmartWalletOwner;
    }

    function setSmartWalletOwner(address swOwner) external onlyOwner returns  (bool success) {
        require(swOwner != address(0) && swOwner != SmartWalletOwner);
        SmartWalletOwner = swOwner;
        success = SmartWalletOwner == swOwner;
    }
}
