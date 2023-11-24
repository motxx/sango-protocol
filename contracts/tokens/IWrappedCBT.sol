// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of {WrappedCBT} implementation.
 */
interface IWrappedCBT {
    struct PendingReceiveStake {
        uint stakedTimestamp;
        uint256 amount;
    }

    event Stake(address staker, uint256 amount);
    event ClaimWCBT(address claimer, uint256 amount);
    event RequestPayback(address account);
    event AcceptPayback(address account, uint256 amount);
    event Withdraw(uint256 amount);
    event SetLockInterval(uint64 lockInterval);
    event SetMinStakeAmount(uint256 amount);

    // ######################
    // ## Public functions ##
    // ######################

    /**
     * @notice Stakes `amount` {CBT}, and receive the same amount of {WrappedCBT} after lock period expired.
     *
     * Emits a {Stake} event.
     */
    function stake(uint256 amount) external;

    /**
     * @notice Claims {WrappedCBT} which lock period expired.
     *
     * Emits a {ClaimWCBT} event.
     */
    function claimWCBT() external;

    /**
     * @notice Requests the staked {CBT} payback.
     *
     * Emits a {RequestPayback} event.
     */
    function requestPayback() external;

    /**
     * @notice Gets the minimum amount of required stakes.
     */
    function minStakeAmount() external view returns (uint256);

    /**
     * @notice Returns whether msg.sender is staking or not.
     */
    function isStaking(address account) external view returns (bool);

    /**
     * @notice Returns whether `account` is requesting payback or not.
     */
    function isPaybackRequested(address account) external view returns (bool);

    // ######################
    // ## Owner functions  ##
    // ######################

    /**
     * @notice Accepts `account` payback request and returns {CBT} in exchange for {WrappedCBT}.
     * 
     * Emits an {AcceptPayback} event.
     */
    function acceptPayback(address account) external;

    /**
     * @notice Withdraws staked {CBT} by the owner.
     *
     * Emits a {Withdraw} event.
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Sets `lockInterval` for staking.
     *
     * Emits a {SetLockInterval} event.
     */
    function setLockInterval(uint64 lockInterval) external;

    /**
     * @notice Sets `amount` as minimum required stake amount.
     *
     * Emits a {SetMinStakeAmount} event.
     */
    function setMinStakeAmount(uint256 amount) external;
}
