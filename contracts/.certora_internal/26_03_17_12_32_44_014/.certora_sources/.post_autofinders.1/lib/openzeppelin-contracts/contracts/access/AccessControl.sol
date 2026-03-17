// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01070000, 1037618708743) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01070001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01070005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01076000, interfaceId) }
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01080000, 1037618708744) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01080001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01080005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01086001, account) }
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011d0000, 1037618708765) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011d0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011d0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011d6000, role) }
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e0000, 1037618708766) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011e6001, account) }
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01060000, 1037618708742) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01060001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01060005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01066000, role) }
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual logInternal290(account)onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }modifier logInternal290(address account) { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01220000, 1037618708770) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01220001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01220005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01226001, account) } _; }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual logInternal291(account)onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }modifier logInternal291(address account) { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01230000, 1037618708771) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01230001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01230005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01236001, account) } _; }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010a0000, 1037618708746) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010a0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010a0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff010a6001, callerConfirmation) }
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01200000, 1037618708768) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01200001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01200005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01206001, adminRole) }
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01210000, 1037618708769) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01210001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01210005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01216001, account) }
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` from `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f0000, 1037618708767) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff011f6001, account) }
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}
