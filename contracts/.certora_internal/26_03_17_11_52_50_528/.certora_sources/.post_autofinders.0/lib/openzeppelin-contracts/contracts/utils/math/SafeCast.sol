// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.6.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX/bool casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in a uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in a uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev A uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b70000, 1037618708663) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b76000, value) }
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b80000, 1037618708664) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b80005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b86000, value) }
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ba0000, 1037618708666) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ba0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ba0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ba6000, value) }
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb0000, 1037618708667) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb6000, value) }
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b90000, 1037618708665) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b90001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b90005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b96000, value) }
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bc0000, 1037618708668) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bc0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bc0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bc6000, value) }
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd0000, 1037618708669) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd6000, value) }
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be0000, 1037618708670) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be6000, value) }
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bf0000, 1037618708671) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bf0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bf0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bf6000, value) }
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c00000, 1037618708672) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c06000, value) }
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c10000, 1037618708673) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c16000, value) }
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c20000, 1037618708674) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c20005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c26000, value) }
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c30000, 1037618708675) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c30005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c36000, value) }
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c40000, 1037618708676) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c40005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c46000, value) }
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c50000, 1037618708677) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c56000, value) }
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c60000, 1037618708678) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c60005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c66000, value) }
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f00000, 1037618708720) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f06000, value) }
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ef0000, 1037618708719) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ef0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ef0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ef6000, value) }
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ee0000, 1037618708718) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ee0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ee0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ee6000, value) }
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f10000, 1037618708721) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f16000, value) }
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f20000, 1037618708722) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f20005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f26000, value) }
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f30000, 1037618708723) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f30005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f36000, value) }
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f40000, 1037618708724) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f40005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f46000, value) }
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f50000, 1037618708725) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f56000, value) }
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f60000, 1037618708726) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f60005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f66000, value) }
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f70000, 1037618708727) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00f76000, value) }
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d50000, 1037618708693) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d56000, value) }
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d60000, 1037618708694) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d60005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d66000, value) }
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d70000, 1037618708695) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d76000, value) }
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ce0000, 1037618708686) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ce0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ce0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ce6000, value) }
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cf0000, 1037618708687) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cf0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cf0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cf6000, value) }
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d00000, 1037618708688) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d06000, value) }
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d10000, 1037618708689) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d16000, value) }
        downcasted = int248(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d2,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d20000, 1037618708690) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d20005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d26000, value) }
        downcasted = int240(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d3,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d30000, 1037618708691) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d30005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d36000, value) }
        downcasted = int232(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d4,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d40000, 1037618708692) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d40005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d46000, value) }
        downcasted = int224(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d5,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c70000, 1037618708679) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c76000, value) }
        downcasted = int216(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d6,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c80000, 1037618708680) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c80005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c86000, value) }
        downcasted = int208(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d7,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c90000, 1037618708681) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c90001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c90005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00c96000, value) }
        downcasted = int200(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d8,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ca0000, 1037618708682) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ca0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ca0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ca6000, value) }
        downcasted = int192(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000d9,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cb0000, 1037618708683) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cb0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cb0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cb6000, value) }
        downcasted = int184(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000da,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cc0000, 1037618708684) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cc0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cc0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cc6000, value) }
        downcasted = int176(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000db,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cd0000, 1037618708685) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cd0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cd0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00cd6000, value) }
        downcasted = int168(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000dc,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d80000, 1037618708696) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d80005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d86000, value) }
        downcasted = int160(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000dd,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d90000, 1037618708697) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d90001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d90005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00d96000, value) }
        downcasted = int152(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000de,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00da0000, 1037618708698) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00da0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00da0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00da6000, value) }
        downcasted = int144(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000df,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00db0000, 1037618708699) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00db0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00db0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00db6000, value) }
        downcasted = int136(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e0,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dc0000, 1037618708700) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dc0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dc0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dc6000, value) }
        downcasted = int128(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e1,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dd0000, 1037618708701) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dd0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dd0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00dd6000, value) }
        downcasted = int120(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e2,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00de0000, 1037618708702) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00de0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00de0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00de6000, value) }
        downcasted = int112(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e3,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00df0000, 1037618708703) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00df0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00df0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00df6000, value) }
        downcasted = int104(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e4,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e00000, 1037618708704) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e06000, value) }
        downcasted = int96(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e5,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e10000, 1037618708705) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e16000, value) }
        downcasted = int88(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e6,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e20000, 1037618708706) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e20005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e26000, value) }
        downcasted = int80(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e7,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e30000, 1037618708707) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e30005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e36000, value) }
        downcasted = int72(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e8,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ed0000, 1037618708717) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ed0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ed0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ed6000, value) }
        downcasted = int64(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000e9,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e40000, 1037618708708) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e40005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e46000, value) }
        downcasted = int56(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ea,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e50000, 1037618708709) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e56000, value) }
        downcasted = int48(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000eb,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e60000, 1037618708710) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e60005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e66000, value) }
        downcasted = int40(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ec,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e70000, 1037618708711) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e76000, value) }
        downcasted = int32(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ed,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e80000, 1037618708712) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e80005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e86000, value) }
        downcasted = int24(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ee,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e90000, 1037618708713) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e90001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e90005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00e96000, value) }
        downcasted = int16(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000ef,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ea0000, 1037618708714) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ea0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ea0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ea6000, value) }
        downcasted = int8(value);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff000000f0,downcasted)}
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00eb0000, 1037618708715) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00eb0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00eb0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00eb6000, value) }
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }

    /**
     * @dev Cast a boolean (false or true) to a uint256 (0 or 1) with no jump.
     */
    function toUint(bool b) internal pure returns (uint256 u) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ec0000, 1037618708716) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ec0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ec0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ec6000, b) }
        assembly ("memory-safe") {
            u := iszero(iszero(b))
        }
    }
}
