// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IOwnerManager {
    
    function getSmartWalletOwner() external view returns (address);
    function setSmartWalletOwner(address swOwner) external returns (bool success);
}
