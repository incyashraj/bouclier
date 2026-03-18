// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

/// @title  BouclierProxyAdmin
/// @notice 2-of-3 multisig timelock admin for UUPS proxy upgrades.
///         Wraps OZ's TimelockController — any upgrade proposal must
///         wait at least `MIN_DELAY` seconds before execution.
///
///         Roles:
///           PROPOSER_ROLE — can schedule upgrades (multisig signers)
///           EXECUTOR_ROLE — can execute after timelock (same as proposers)
///           CANCELLER_ROLE — can cancel a pending upgrade (guardian)
///
/// Usage:
///   1. Deploy with proposers = [signer1, signer2, signer3], MIN_DELAY = 48h
///   2. Transfer UUPSUpgradeable._authorizeUpgrade ownership to this contract
///   3. Any 1 proposer can schedule an upgrade; 48h later any executor can run it
contract BouclierProxyAdmin is TimelockController {
    uint256 public constant MIN_DELAY = 48 hours;

    /// @param proposers  Addresses that can propose upgrades (multisig signers)
    /// @param executors  Addresses that can execute after timelock (pass proposers)
    /// @param admin      Optionally set an initial admin (pass address(0) to make contract self-governed)
    constructor(
        address[] memory proposers,
        address[] memory executors,
        address admin
    )
        TimelockController(MIN_DELAY, proposers, executors, admin)
    {}
}
