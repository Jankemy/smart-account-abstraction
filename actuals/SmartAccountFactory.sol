// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts@4.8.0/utils/Create2.sol";
import "@openzeppelin/contracts@4.8.0/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";

import "./SmartAccount.sol";
import "../interfaces/IOwnerManager.sol";

/**
 * A sample factory contract for SmartAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 */
contract SmartAccountFactory is Ownable {
    SmartAccount public accountImplementation;
    IOwnerManager public ownerManager;

    constructor(IOwnerManager _ownerManager) {
        accountImplementation = new SmartAccount(_ownerManager);
        ownerManager = _ownerManager;
    }

    function setNewImplementation(SmartAccount _newImplementation) external onlyOwner {
        accountImplementation = _newImplementation;
    }

    function setNewOwnerManager(IOwnerManager _newOwnerManager) external onlyOwner {
        ownerManager = _newOwnerManager;
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     */
    function createAccount(uint256 salt) public returns (SmartAccount ret) {
        address addr = getAddress(salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return SmartAccount(payable(addr));
        }
        ret = SmartAccount(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(SmartAccount.initialize, (address(ownerManager)))
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(SmartAccount.initialize, (address(ownerManager)))
                )
            )));
    }
}
