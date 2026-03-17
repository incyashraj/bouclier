// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.6.0) (utils/Strings.sol)

pragma solidity ^0.8.24;

import {Math} from "./math/Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {SignedMath} from "./math/SignedMath.sol";
import {Bytes} from "./Bytes.sol";

/**
 * @dev String operations.
 */
library Strings {
    using SafeCast for *;

    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;
    uint256 private constant SPECIAL_CHARS_LOOKUP =
        0xffffffff | // first 32 bits corresponding to the control characters (U+0000 to U+001F)
            (1 << 0x22) | // double quote
            (1 << 0x5c); // backslash

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev The string being parsed contains characters that are not in scope of the given base.
     */
    error StringsInvalidChar();

    /**
     * @dev The string being parsed is not a properly formatted address.
     */
    error StringsInvalidAddressFormat();

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00870000, 1037618708615) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00870001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00870005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00876000, value) }
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            assembly ("memory-safe") {
                ptr := add(add(buffer, 0x20), length)
            }
            while (true) {
                ptr--;
                assembly ("memory-safe") {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b3,value)}
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00880000, 1037618708616) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00880001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00880005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00886000, value) }
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008a0000, 1037618708618) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008a0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008a6000, value) }
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008b0000, 1037618708619) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008b0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008b0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008b6001, length) }
        uint256 localValue = value;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000008d,localValue)}
        bytes memory buffer = new bytes(2 * length + 2);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001008e,0)}
        buffer[0] = "0";bytes1 certora_local167 = buffer[0];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a7,certora_local167)}
        buffer[1] = "x";bytes1 certora_local168 = buffer[1];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a8,certora_local168)}
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];bytes1 certora_local172 = buffer[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ac,certora_local172)}
            localValue >>= 4;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ad,localValue)}
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00890000, 1037618708617) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00890001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00890005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00896000, addr) }
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its checksummed ASCII `string` hexadecimal
     * representation, according to EIP-55.
     */
    function toChecksumHexString(address addr) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008c0000, 1037618708620) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008c6000, addr) }
        bytes memory buffer = bytes(toHexString(addr));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001008f,0)}

        // hash the hex part of buffer (skip length + 2 bytes, length 40)
        uint256 hashValue;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000090,hashValue)}
        assembly ("memory-safe") {
            hashValue := shr(96, keccak256(add(buffer, 0x22), 40))
        }

        for (uint256 i = 41; i > 1; --i) {
            // possible values for buffer[i] are 48 (0) to 57 (9) and 97 (a) to 102 (f)
            if (hashValue & 0xf > 7 && uint8(buffer[i]) > 96) {
                // case shift by xoring with 0x20
                buffer[i] ^= 0x20;
            }
            hashValue >>= 4;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ae,hashValue)}
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `bytes` buffer to its ASCII `string` hexadecimal representation.
     */
    function toHexString(bytes memory input) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008d0000, 1037618708621) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008d6000, input) }
        unchecked {
            bytes memory buffer = new bytes(2 * input.length + 2);
            buffer[0] = "0";
            buffer[1] = "x";
            for (uint256 i = 0; i < input.length; ++i) {
                uint8 v = uint8(input[i]);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000af,v)}
                buffer[2 * i + 2] = HEX_DIGITS[v >> 4];bytes1 certora_local180 = buffer[2 * i + 2];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b4,certora_local180)}
                buffer[2 * i + 3] = HEX_DIGITS[v & 0xf];bytes1 certora_local181 = buffer[2 * i + 3];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b5,certora_local181)}
            }
            return string(buffer);
        }
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008e0000, 1037618708622) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008e0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008e0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008e6001, b) }
        return Bytes.equal(bytes(a), bytes(b));
    }

    /**
     * @dev Parse a decimal string and returns the value as a `uint256`.
     *
     * Requirements:
     * - The string must be formatted as `[0-9]*`
     * - The result must fit into an `uint256` type
     */
    function parseUint(string memory input) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008f0000, 1037618708623) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff008f6000, input) }
        return parseUint(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseUint-string} that parses a substring of `input` located between position `begin` (included) and
     * `end` (excluded).
     *
     * Requirements:
     * - The substring must be formatted as `[0-9]*`
     * - The result must fit into an `uint256` type
     */
    function parseUint(string memory input, uint256 begin, uint256 end) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00900000, 1037618708624) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00900001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00900005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00906002, end) }
        (bool success, uint256 value) = tryParseUint(input, begin, end);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010091,0)}
        if (!success) revert StringsInvalidChar();
        return value;
    }

    /**
     * @dev Variant of {parseUint-string} that returns false if the parsing fails because of an invalid character.
     *
     * NOTE: This function will revert if the result does not fit in a `uint256`.
     */
    function tryParseUint(string memory input) internal pure returns (bool success, uint256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00910000, 1037618708625) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00910001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00910005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00916000, input) }
        return _tryParseUintUncheckedBounds(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseUint-string-uint256-uint256} that returns false if the parsing fails because of an invalid
     * character.
     *
     * NOTE: This function will revert if the result does not fit in a `uint256`.
     */
    function tryParseUint(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, uint256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00920000, 1037618708626) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00920001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00920005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00926002, end) }
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseUintUncheckedBounds(input, begin, end);
    }

    /**
     * @dev Implementation of {tryParseUint-string-uint256-uint256} that does not check bounds. Caller should make sure that
     * `begin <= end <= input.length`. Other inputs would result in undefined behavior.
     */
    function _tryParseUintUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, uint256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00930000, 1037618708627) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00930001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00930005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00936002, end) }
        bytes memory buffer = bytes(input);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010092,0)}

        uint256 result = 0;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000093,result)}
        for (uint256 i = begin; i < end; ++i) {
            uint8 chr = _tryParseChr(bytes1(_unsafeReadBytesOffset(buffer, i)));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a9,chr)}
            if (chr > 9) return (false, 0);
            result *= 10;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b0,result)}
            result += chr;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b1,result)}
        }
        return (true, result);
    }

    /**
     * @dev Parse a decimal string and returns the value as a `int256`.
     *
     * Requirements:
     * - The string must be formatted as `[-+]?[0-9]*`
     * - The result must fit in an `int256` type.
     */
    function parseInt(string memory input) internal pure returns (int256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00940000, 1037618708628) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00940001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00940005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00946000, input) }
        return parseInt(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseInt-string} that parses a substring of `input` located between position `begin` (included) and
     * `end` (excluded).
     *
     * Requirements:
     * - The substring must be formatted as `[-+]?[0-9]*`
     * - The result must fit in an `int256` type.
     */
    function parseInt(string memory input, uint256 begin, uint256 end) internal pure returns (int256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00950000, 1037618708629) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00950001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00950005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00956002, end) }
        (bool success, int256 value) = tryParseInt(input, begin, end);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010094,0)}
        if (!success) revert StringsInvalidChar();
        return value;
    }

    /**
     * @dev Variant of {parseInt-string} that returns false if the parsing fails because of an invalid character or if
     * the result does not fit in a `int256`.
     *
     * NOTE: This function will revert if the absolute value of the result does not fit in a `uint256`.
     */
    function tryParseInt(string memory input) internal pure returns (bool success, int256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00960000, 1037618708630) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00960001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00960005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00966000, input) }
        return _tryParseIntUncheckedBounds(input, 0, bytes(input).length);
    }

    uint256 private constant ABS_MIN_INT256 = 2 ** 255;

    /**
     * @dev Variant of {parseInt-string-uint256-uint256} that returns false if the parsing fails because of an invalid
     * character or if the result does not fit in a `int256`.
     *
     * NOTE: This function will revert if the absolute value of the result does not fit in a `uint256`.
     */
    function tryParseInt(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, int256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a30000, 1037618708643) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a30001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a30005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a36002, end) }
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseIntUncheckedBounds(input, begin, end);
    }

    /**
     * @dev Implementation of {tryParseInt-string-uint256-uint256} that does not check bounds. Caller should make sure that
     * `begin <= end <= input.length`. Other inputs would result in undefined behavior.
     */
    function _tryParseIntUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, int256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a20000, 1037618708642) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a20001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a20005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a26002, end) }
        bytes memory buffer = bytes(input);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010095,0)}

        // Check presence of a negative sign.
        bytes1 sign = begin == end ? bytes1(0) : bytes1(_unsafeReadBytesOffset(buffer, begin));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000096,sign)} // don't do out-of-bound (possibly unsafe) read if sub-string is empty
        bool positiveSign = sign == bytes1("+");assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000097,positiveSign)}
        bool negativeSign = sign == bytes1("-");assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000098,negativeSign)}
        uint256 offset = (positiveSign || negativeSign).toUint();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000099,offset)}

        (bool absSuccess, uint256 absValue) = tryParseUint(input, begin + offset, end);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001009a,0)}

        if (absSuccess && absValue < ABS_MIN_INT256) {
            return (true, negativeSign ? -int256(absValue) : int256(absValue));
        } else if (absSuccess && negativeSign && absValue == ABS_MIN_INT256) {
            return (true, type(int256).min);
        } else return (false, 0);
    }

    /**
     * @dev Parse a hexadecimal string (with or without "0x" prefix), and returns the value as a `uint256`.
     *
     * Requirements:
     * - The string must be formatted as `(0x)?[0-9a-fA-F]*`
     * - The result must fit in an `uint256` type.
     */
    function parseHexUint(string memory input) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a10000, 1037618708641) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a16000, input) }
        return parseHexUint(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseHexUint-string} that parses a substring of `input` located between position `begin` (included) and
     * `end` (excluded).
     *
     * Requirements:
     * - The substring must be formatted as `(0x)?[0-9a-fA-F]*`
     * - The result must fit in an `uint256` type.
     */
    function parseHexUint(string memory input, uint256 begin, uint256 end) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a40000, 1037618708644) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a40001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a40005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a46002, end) }
        (bool success, uint256 value) = tryParseHexUint(input, begin, end);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001009b,0)}
        if (!success) revert StringsInvalidChar();
        return value;
    }

    /**
     * @dev Variant of {parseHexUint-string} that returns false if the parsing fails because of an invalid character.
     *
     * NOTE: This function will revert if the result does not fit in a `uint256`.
     */
    function tryParseHexUint(string memory input) internal pure returns (bool success, uint256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a50000, 1037618708645) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a56000, input) }
        return _tryParseHexUintUncheckedBounds(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseHexUint-string-uint256-uint256} that returns false if the parsing fails because of an
     * invalid character.
     *
     * NOTE: This function will revert if the result does not fit in a `uint256`.
     */
    function tryParseHexUint(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, uint256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00990000, 1037618708633) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00990001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00990005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00996002, end) }
        if (end > bytes(input).length || begin > end) return (false, 0);
        return _tryParseHexUintUncheckedBounds(input, begin, end);
    }

    /**
     * @dev Implementation of {tryParseHexUint-string-uint256-uint256} that does not check bounds. Caller should make sure that
     * `begin <= end <= input.length`. Other inputs would result in undefined behavior.
     */
    function _tryParseHexUintUncheckedBounds(
        string memory input,
        uint256 begin,
        uint256 end
    ) private pure returns (bool success, uint256 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009a0000, 1037618708634) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009a0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009a0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009a6002, end) }
        bytes memory buffer = bytes(input);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001009c,0)}

        // skip 0x prefix if present
        bool hasPrefix = (end > begin + 1) && bytes2(_unsafeReadBytesOffset(buffer, begin)) == bytes2("0x");assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000009d,hasPrefix)} // don't do out-of-bound (possibly unsafe) read if sub-string is empty
        uint256 offset = hasPrefix.toUint() * 2;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000009e,offset)}

        uint256 result = 0;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000009f,result)}
        for (uint256 i = begin + offset; i < end; ++i) {
            uint8 chr = _tryParseChr(bytes1(_unsafeReadBytesOffset(buffer, i)));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000aa,chr)}
            if (chr > 15) return (false, 0);
            result *= 16;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000b2,result)}
            unchecked {
                // Multiplying by 16 is equivalent to a shift of 4 bits (with additional overflow check).
                // This guarantees that adding a value < 16 will not cause an overflow, hence the unchecked.
                result += chr;
            }
        }
        return (true, result);
    }

    /**
     * @dev Parse a hexadecimal string (with or without "0x" prefix), and returns the value as an `address`.
     *
     * Requirements:
     * - The string must be formatted as `(0x)?[0-9a-fA-F]{40}`
     */
    function parseAddress(string memory input) internal pure returns (address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009b0000, 1037618708635) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009b0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009b0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009b6000, input) }
        return parseAddress(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseAddress-string} that parses a substring of `input` located between position `begin` (included) and
     * `end` (excluded).
     *
     * Requirements:
     * - The substring must be formatted as `(0x)?[0-9a-fA-F]{40}`
     */
    function parseAddress(string memory input, uint256 begin, uint256 end) internal pure returns (address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00970000, 1037618708631) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00970001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00970005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00976002, end) }
        (bool success, address value) = tryParseAddress(input, begin, end);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100a0,0)}
        if (!success) revert StringsInvalidAddressFormat();
        return value;
    }

    /**
     * @dev Variant of {parseAddress-string} that returns false if the parsing fails because the input is not a properly
     * formatted address. See {parseAddress-string} requirements.
     */
    function tryParseAddress(string memory input) internal pure returns (bool success, address value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00980000, 1037618708632) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00980001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00980005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00986000, input) }
        return tryParseAddress(input, 0, bytes(input).length);
    }

    /**
     * @dev Variant of {parseAddress-string-uint256-uint256} that returns false if the parsing fails because input is not a properly
     * formatted address. See {parseAddress-string-uint256-uint256} requirements.
     */
    function tryParseAddress(
        string memory input,
        uint256 begin,
        uint256 end
    ) internal pure returns (bool success, address value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009e0000, 1037618708638) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009e0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009e0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009e6002, end) }
        if (end > bytes(input).length || begin > end) return (false, address(0));

        bool hasPrefix = (end > begin + 1) && bytes2(_unsafeReadBytesOffset(bytes(input), begin)) == bytes2("0x");assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a1,hasPrefix)} // don't do out-of-bound (possibly unsafe) read if sub-string is empty
        uint256 expectedLength = 40 + hasPrefix.toUint() * 2;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a2,expectedLength)}

        // check that input is the correct length
        if (end - begin == expectedLength) {
            // length guarantees that this does not overflow, and value is at most type(uint160).max
            (bool s, uint256 v) = _tryParseHexUintUncheckedBounds(input, begin, end);
            return (s, address(uint160(v)));
        } else {
            return (false, address(0));
        }
    }

    function _tryParseChr(bytes1 chr) private pure returns (uint8) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009f0000, 1037618708639) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009f6000, chr) }
        uint8 value = uint8(chr);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a3,value)}

        // Try to parse `chr`:
        // - Case 1: [0-9]
        // - Case 2: [a-f]
        // - Case 3: [A-F]
        // - otherwise not supported
        unchecked {
            if (value > 47 && value < 58) value -= 48;
            else if (value > 96 && value < 103) value -= 87;
            else if (value > 64 && value < 71) value -= 55;
            else return type(uint8).max;
        }

        return value;
    }

    /**
     * @dev Escape special characters in JSON strings. This can be useful to prevent JSON injection in NFT metadata.
     *
     * WARNING: This function should only be used in double quoted JSON strings. Single quotes are not escaped.
     *
     * NOTE: This function escapes backslashes (including those in \uXXXX sequences) and the characters in ranges
     * defined in section 2.5 of RFC-4627 (U+0000 to U+001F, U+0022 and U+005C). All control characters in U+0000
     * to U+001F are escaped (\b, \t, \n, \f, \r use short form; others use \u00XX). ECMAScript's `JSON.parse` does
     * recover escaped unicode characters that are not in this range, but other tooling may provide different results.
     */
    function escapeJSON(string memory input) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a00000, 1037618708640) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00a06000, input) }
        bytes memory buffer = bytes(input);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100a4,0)}

        // Put output at the FMP. Memory will be reserved later when we figure out the actual length of the escaped
        // string. All write are done using _unsafeWriteBytesOffset, which avoid the (expensive) length checks for
        // each character written.
        bytes memory output;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000100a5,0)}
        assembly ("memory-safe") {
            output := mload(0x40)
        }
        uint256 outputLength = 0;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000a6,outputLength)}

        for (uint256 i = 0; i < buffer.length; ++i) {
            uint8 char = uint8(bytes1(_unsafeReadBytesOffset(buffer, i)));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ab,char)}
            if (((SPECIAL_CHARS_LOOKUP & (1 << char)) != 0)) {
                _unsafeWriteBytesOffset(output, outputLength++, "\\");
                if (char == 0x08) _unsafeWriteBytesOffset(output, outputLength++, "b");
                else if (char == 0x09) _unsafeWriteBytesOffset(output, outputLength++, "t");
                else if (char == 0x0a) _unsafeWriteBytesOffset(output, outputLength++, "n");
                else if (char == 0x0c) _unsafeWriteBytesOffset(output, outputLength++, "f");
                else if (char == 0x0d) _unsafeWriteBytesOffset(output, outputLength++, "r");
                else if (char == 0x5c) _unsafeWriteBytesOffset(output, outputLength++, "\\");
                else if (char == 0x22) {
                    // solhint-disable-next-line quotes
                    _unsafeWriteBytesOffset(output, outputLength++, '"');
                } else {
                    // U+0000 to U+001F without short form: output \u00XX
                    _unsafeWriteBytesOffset(output, outputLength++, "u");
                    _unsafeWriteBytesOffset(output, outputLength++, "0");
                    _unsafeWriteBytesOffset(output, outputLength++, "0");
                    _unsafeWriteBytesOffset(output, outputLength++, HEX_DIGITS[char >> 4]);
                    _unsafeWriteBytesOffset(output, outputLength++, HEX_DIGITS[char & 0x0f]);
                }
            } else {
                _unsafeWriteBytesOffset(output, outputLength++, bytes1(char));
            }
        }
        // write the actual length and reserve memory
        assembly ("memory-safe") {
            mstore(output, outputLength)
            mstore(0x40, add(output, add(outputLength, 0x20)))
        }

        return string(output);
    }

    /**
     * @dev Reads a bytes32 from a bytes array without bounds checking.
     *
     * NOTE: making this function internal would mean it could be used with memory unsafe offset, and marking the
     * assembly block as such would prevent some optimizations.
     */
    function _unsafeReadBytesOffset(bytes memory buffer, uint256 offset) private pure returns (bytes32 value) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009c0000, 1037618708636) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009c0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009c0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009c6001, offset) }
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            value := mload(add(add(buffer, 0x20), offset))
        }
    }

    /**
     * @dev Write a bytes1 to a bytes array without bounds checking.
     *
     * NOTE: making this function internal would mean it could be used with memory unsafe offset, and marking the
     * assembly block as such would prevent some optimizations.
     */
    function _unsafeWriteBytesOffset(bytes memory buffer, uint256 offset, bytes1 value) private pure {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009d0000, 1037618708637) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009d0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009d0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff009d6002, value) }
        // This is not memory safe in the general case, but all calls to this private function are within bounds.
        assembly ("memory-safe") {
            mstore8(add(add(buffer, 0x20), offset), shr(248, value))
        }
    }
}
