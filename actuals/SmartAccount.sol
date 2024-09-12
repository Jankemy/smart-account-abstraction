// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts@4.8.0/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts@4.8.0/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts@4.8.0/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IOwnerManager.sol";
import "../samples/callback/TokenCallbackHandler.sol";

/**
  *  minimal Smart account.
  *  this is sample minimal account.
  *  has execute, eth handling methods
  *  has a single signer that can send requests.
  */
contract SmartAccount is TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;

    function owner() public view returns (address) {
        return _ownerManager.getSmartWalletOwner();
    }

    IOwnerManager private _ownerManager;

    event SimpleAccountInitialized(IOwnerManager indexed anOwnerManager);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// OwnerManager contract address
    function ownerManager() public view virtual returns (IOwnerManager) {
        return _ownerManager;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IOwnerManager anOwnerManager) {
        _ownerManager = anOwnerManager;
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == owner(), "only owner");
    }

    /**
     * execute a transaction (called directly from owner)
     */
    function execute(address dest, uint256 value, bytes calldata func) external onlyOwner {
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     * @dev to reduce gas consumption for trivial case (no value), use a zero-length array to mean zero value
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external onlyOwner {
        require(dest.length == func.length && (value.length == 0 || value.length == func.length), "wrong array lengths");
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
            }
        }
    }

    /**
     * @dev The _ownerManager member is immutable, to reduce gas consumption. To upgrade OwnerManager,
     * a new implementation of SmartAccount must be deployed with the new OwnerManager address, then upgrading
      * the implementation by calling `upgradeTo()`
     */
    function initialize(address anOwnerManager) public virtual initializer {
        _initialize(anOwnerManager);
    }

    function _initialize(address anOwnerManager) internal virtual {
        _ownerManager = IOwnerManager(anOwnerManager);
        emit SimpleAccountInitialized(_ownerManager);
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        _onlyOwner();
        (newImplementation);
    }
}

