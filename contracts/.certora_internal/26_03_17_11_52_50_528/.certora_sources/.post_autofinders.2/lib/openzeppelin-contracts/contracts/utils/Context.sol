// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ff0000, 1037618708991) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ff0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ff0004, 0) }
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02000000, 1037618708992) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02000001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02000004, 0) }
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02010000, 1037618708993) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02010001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02010004, 0) }
        return 0;
    }
}
