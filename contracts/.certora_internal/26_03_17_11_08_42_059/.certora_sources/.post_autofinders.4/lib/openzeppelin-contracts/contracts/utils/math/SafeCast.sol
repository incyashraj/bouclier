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
    function toUint248(uint256 value) internal pure returns (uint248) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01de0000, 1037618708958) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01de0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01de0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01de6000, value) }
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
    function toUint240(uint256 value) internal pure returns (uint240) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01df0000, 1037618708959) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01df0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01df0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01df6000, value) }
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
    function toUint232(uint256 value) internal pure returns (uint232) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e10000, 1037618708961) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e16000, value) }
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
    function toUint224(uint256 value) internal pure returns (uint224) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e20000, 1037618708962) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e20005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e26000, value) }
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
    function toUint216(uint256 value) internal pure returns (uint216) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e00000, 1037618708960) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e06000, value) }
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
    function toUint208(uint256 value) internal pure returns (uint208) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e30000, 1037618708963) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e30005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e36000, value) }
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
    function toUint200(uint256 value) internal pure returns (uint200) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e40000, 1037618708964) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e40005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e46000, value) }
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
    function toUint192(uint256 value) internal pure returns (uint192) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e50000, 1037618708965) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e56000, value) }
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
    function toUint184(uint256 value) internal pure returns (uint184) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e60000, 1037618708966) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e60005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e66000, value) }
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
    function toUint176(uint256 value) internal pure returns (uint176) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e70000, 1037618708967) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e76000, value) }
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
    function toUint168(uint256 value) internal pure returns (uint168) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e80000, 1037618708968) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e80005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e86000, value) }
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
    function toUint160(uint256 value) internal pure returns (uint160) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e90000, 1037618708969) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e90001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e90005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01e96000, value) }
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
    function toUint152(uint256 value) internal pure returns (uint152) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ea0000, 1037618708970) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ea0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ea0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ea6000, value) }
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
    function toUint144(uint256 value) internal pure returns (uint144) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01eb0000, 1037618708971) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01eb0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01eb0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01eb6000, value) }
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
    function toUint136(uint256 value) internal pure returns (uint136) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ec0000, 1037618708972) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ec0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ec0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ec6000, value) }
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
    function toUint128(uint256 value) internal pure returns (uint128) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ed0000, 1037618708973) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ed0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ed0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ed6000, value) }
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
    function toUint120(uint256 value) internal pure returns (uint120) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02170000, 1037618709015) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02170001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02170005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02176000, value) }
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
    function toUint112(uint256 value) internal pure returns (uint112) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02160000, 1037618709014) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02160001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02160005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02166000, value) }
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
    function toUint104(uint256 value) internal pure returns (uint104) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02150000, 1037618709013) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02150001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02150005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02156000, value) }
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
    function toUint96(uint256 value) internal pure returns (uint96) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02180000, 1037618709016) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02180001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02180005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02186000, value) }
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
    function toUint88(uint256 value) internal pure returns (uint88) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02190000, 1037618709017) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02190001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02190005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02196000, value) }
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
    function toUint80(uint256 value) internal pure returns (uint80) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021a0000, 1037618709018) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021a0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021a6000, value) }
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
    function toUint72(uint256 value) internal pure returns (uint72) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021b0000, 1037618709019) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021b0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021b0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021b6000, value) }
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
    function toUint64(uint256 value) internal pure returns (uint64) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021c0000, 1037618709020) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021c6000, value) }
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
    function toUint56(uint256 value) internal pure returns (uint56) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021d0000, 1037618709021) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021d6000, value) }
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
    function toUint48(uint256 value) internal pure returns (uint48) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021e0000, 1037618709022) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021e0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff021e6000, value) }
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
    function toUint40(uint256 value) internal pure returns (uint40) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fc0000, 1037618708988) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fc0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fc0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fc6000, value) }
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
    function toUint32(uint256 value) internal pure returns (uint32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fd0000, 1037618708989) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fd0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fd0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fd6000, value) }
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
    function toUint24(uint256 value) internal pure returns (uint24) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fe0000, 1037618708990) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fe0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fe0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fe6000, value) }
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
    function toUint16(uint256 value) internal pure returns (uint16) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f50000, 1037618708981) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f50001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f50005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f56000, value) }
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
    function toUint8(uint256 value) internal pure returns (uint8) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f60000, 1037618708982) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f60001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f60005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f66000, value) }
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
    function toUint256(int256 value) internal pure returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f70000, 1037618708983) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f70001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f70005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f76000, value) }
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
    function toInt248(int256 value) internal pure returns (int248 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f80000, 1037618708984) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f80001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f80005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f86000, value) }
        downcasted = int248(value);
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
    function toInt240(int256 value) internal pure returns (int240 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f90000, 1037618708985) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f90001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f90005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f96000, value) }
        downcasted = int240(value);
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
    function toInt232(int256 value) internal pure returns (int232 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fa0000, 1037618708986) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fa0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fa0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fa6000, value) }
        downcasted = int232(value);
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
    function toInt224(int256 value) internal pure returns (int224 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fb0000, 1037618708987) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fb0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fb0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01fb6000, value) }
        downcasted = int224(value);
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
    function toInt216(int256 value) internal pure returns (int216 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ee0000, 1037618708974) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ee0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ee0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ee6000, value) }
        downcasted = int216(value);
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
    function toInt208(int256 value) internal pure returns (int208 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ef0000, 1037618708975) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ef0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ef0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ef6000, value) }
        downcasted = int208(value);
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
    function toInt200(int256 value) internal pure returns (int200 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f00000, 1037618708976) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f00001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f00005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f06000, value) }
        downcasted = int200(value);
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
    function toInt192(int256 value) internal pure returns (int192 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f10000, 1037618708977) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f10001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f10005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f16000, value) }
        downcasted = int192(value);
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
    function toInt184(int256 value) internal pure returns (int184 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f20000, 1037618708978) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f20001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f20005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f26000, value) }
        downcasted = int184(value);
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
    function toInt176(int256 value) internal pure returns (int176 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f30000, 1037618708979) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f30001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f30005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f36000, value) }
        downcasted = int176(value);
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
    function toInt168(int256 value) internal pure returns (int168 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f40000, 1037618708980) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f40005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01f46000, value) }
        downcasted = int168(value);
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
    function toInt160(int256 value) internal pure returns (int160 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ff0000, 1037618708991) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ff0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ff0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01ff6000, value) }
        downcasted = int160(value);
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
    function toInt152(int256 value) internal pure returns (int152 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02000000, 1037618708992) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02000001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02000005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02006000, value) }
        downcasted = int152(value);
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
    function toInt144(int256 value) internal pure returns (int144 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02010000, 1037618708993) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02010001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02010005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02016000, value) }
        downcasted = int144(value);
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
    function toInt136(int256 value) internal pure returns (int136 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02020000, 1037618708994) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02020001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02020005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02026000, value) }
        downcasted = int136(value);
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02030000, 1037618708995) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02030001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02030005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02036000, value) }
        downcasted = int128(value);
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
    function toInt120(int256 value) internal pure returns (int120 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02040000, 1037618708996) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02040001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02040005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02046000, value) }
        downcasted = int120(value);
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
    function toInt112(int256 value) internal pure returns (int112 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02050000, 1037618708997) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02050001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02050005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02056000, value) }
        downcasted = int112(value);
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
    function toInt104(int256 value) internal pure returns (int104 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02060000, 1037618708998) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02060001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02060005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02066000, value) }
        downcasted = int104(value);
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
    function toInt96(int256 value) internal pure returns (int96 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02070000, 1037618708999) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02070001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02070005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02076000, value) }
        downcasted = int96(value);
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
    function toInt88(int256 value) internal pure returns (int88 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02080000, 1037618709000) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02080001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02080005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02086000, value) }
        downcasted = int88(value);
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
    function toInt80(int256 value) internal pure returns (int80 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02090000, 1037618709001) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02090001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02090005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02096000, value) }
        downcasted = int80(value);
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
    function toInt72(int256 value) internal pure returns (int72 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020a0000, 1037618709002) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020a0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020a6000, value) }
        downcasted = int72(value);
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02140000, 1037618709012) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02140001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02140005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02146000, value) }
        downcasted = int64(value);
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
    function toInt56(int256 value) internal pure returns (int56 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020b0000, 1037618709003) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020b0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020b0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020b6000, value) }
        downcasted = int56(value);
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
    function toInt48(int256 value) internal pure returns (int48 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020c0000, 1037618709004) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020c6000, value) }
        downcasted = int48(value);
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
    function toInt40(int256 value) internal pure returns (int40 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020d0000, 1037618709005) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020d6000, value) }
        downcasted = int40(value);
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020e0000, 1037618709006) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020e0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020e6000, value) }
        downcasted = int32(value);
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
    function toInt24(int256 value) internal pure returns (int24 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020f0000, 1037618709007) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff020f6000, value) }
        downcasted = int24(value);
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02100000, 1037618709008) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02100001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02100005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02106000, value) }
        downcasted = int16(value);
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
    function toInt8(int256 value) internal pure returns (int8 downcasted) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02110000, 1037618709009) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02110001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02110005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02116000, value) }
        downcasted = int8(value);
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
    function toInt256(uint256 value) internal pure returns (int256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02120000, 1037618709010) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02120001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02120005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02126000, value) }
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }

    /**
     * @dev Cast a boolean (false or true) to a uint256 (0 or 1) with no jump.
     */
    function toUint(bool b) internal pure returns (uint256 u) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02130000, 1037618709011) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02130001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02130005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff02136000, b) }
        assembly ("memory-safe") {
            u := iszero(iszero(b))
        }
    }
}
