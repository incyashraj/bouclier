// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff013d0000, 1037618708797) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff013d0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff013d0004, 0) }
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0000, 1037618708814) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0004, 0) }
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual logInternal337()onlyOwner {
        _transferOwnership(address(0));
    }modifier logInternal337() { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01510000, 1037618708817) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01510001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01510004, 0) } _; }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual logInternal336(newOwner)onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }modifier logInternal336(address newOwner) { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01500000, 1037618708816) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01500001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01500005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01506000, newOwner) } _; }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014f0000, 1037618708815) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014f6000, newOwner) }
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
