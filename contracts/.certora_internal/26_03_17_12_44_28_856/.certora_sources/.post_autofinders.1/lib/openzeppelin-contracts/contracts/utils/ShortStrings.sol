// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.5.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.20;

import {StorageSlot} from "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01490000, 1037618708809) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01490001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01490005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01496000, str) }
        bytes memory bstr = bytes(str);
        if (bstr.length > 0x1f) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014a0000, 1037618708810) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014a0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014a6000, sstr) }
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(0x20);
        assembly ("memory-safe") {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014c0000, 1037618708812) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014c6000, sstr) }
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 0x1f) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014d0000, 1037618708813) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014d0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014d0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014d6001, store.slot) }
        if (bytes(value).length < 0x20) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {toShortStringWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014b0000, 1037618708811) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014b0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014b0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014b6001, store.slot) }
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using
     * {toShortStringWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0000, 1037618708814) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff014e6001, store.slot) }
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}
