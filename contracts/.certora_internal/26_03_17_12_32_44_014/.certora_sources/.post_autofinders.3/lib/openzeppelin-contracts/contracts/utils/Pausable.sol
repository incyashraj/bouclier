// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020a0000, 1037618709002) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020a0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020a0004, 0) }
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020e0000, 1037618709006) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020e0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020e0004, 0) }
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020f0000, 1037618709007) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020f0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020f0004, 0) }
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual logInternal528()whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }modifier logInternal528() { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02100000, 1037618709008) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02100001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02100004, 0) } _; }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual logInternal529()whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }modifier logInternal529() { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02110000, 1037618709009) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02110001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02110004, 0) } _; }
}
