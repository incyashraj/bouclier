// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01790000, 1037618708857) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01790001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01790005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01796000, slot) }
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017a0000, 1037618708858) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017a0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017a0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017a6000, slot) }
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017c0000, 1037618708860) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017c6000, slot) }
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017d0000, 1037618708861) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017d6000, slot) }
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017b0000, 1037618708859) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017b0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017b0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017b6000, slot) }
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017e0000, 1037618708862) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017e0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017e6000, slot) }
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017f0000, 1037618708863) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017f0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff017f6000, store.slot) }
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01800000, 1037618708864) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01800001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01800005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01806000, slot) }
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01810000, 1037618708865) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01810001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01810005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01816000, store.slot) }
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}
