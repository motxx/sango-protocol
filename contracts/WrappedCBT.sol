// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWrappedCBT } from "./tokens/IWrappedCBT.sol";
import { RoyaltyClaimRight } from "./claimrights/RoyaltyClaimRight.sol";

/**
 * @notice コンテンツにCBTをstakeした分と同量だけ貰える、コンテンツ毎に発行されるトークン(株式).
 * wCBT の stakeholder は、RBTの分配を受けることができる. また、コンテンツのガバナンス権を持つ場合もある.
 */
contract WrappedCBT is IWrappedCBT, RoyaltyClaimRight, Ownable {
    IERC20 private _cbt;
    uint256 private _minStakeAmount;
    uint private _lockInterval;
    mapping (address => PendingReceiveStake) private _pendingReceiveStakes;
    mapping (address => bool) private _paybackRequested;

    constructor(IERC20 cbt, IERC20[] memory approvedTokens, address owner_)
        RoyaltyClaimRight("Wrapped CBT", "CBT")
    {
        _cbt = cbt;
        _approveForIncomingTokens(approvedTokens);
        transferOwnership(owner_);
    }

    // ######################
    // ## Public functions ##
    // ######################

    /// @inheritdoc IWrappedCBT
    function stake(uint256 amount)
        external
        override
    {
        require (amount >= _minStakeAmount, "WrappedCBT: less than minStakeAmount");
        require (_pendingReceiveStakes[msg.sender].amount == 0, "WrappedCBT: pending stake exists");
        require (balanceOf(msg.sender) == 0, "WrappedCBT: already staked");

        _pendingReceiveStakes[msg.sender] = PendingReceiveStake(block.timestamp, amount);

        _cbt.transferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, amount);
    }

    /// @inheritdoc IWrappedCBT
    function claimWCBT()
        external
        override
    {
        uint256 amount = _pendingReceiveStakes[msg.sender].amount;
        uint stakedTimestamp = _pendingReceiveStakes[msg.sender].stakedTimestamp;

        require (amount > 0, "WrappedCBT: no pending stake exists");
        require (stakedTimestamp + _lockInterval <= block.timestamp, "WrappedCBT: within lock interval");

        delete _pendingReceiveStakes[msg.sender];
        _mint(msg.sender, amount);

        emit ClaimWCBT(msg.sender, amount);
    }

    /// @inheritdoc IWrappedCBT
    function requestPayback()
        external
        override
    {
        require (isStaking(msg.sender), "SangoContent: no amount staked");
        require (!_paybackRequested[msg.sender], "SangoContent: already payback requested");
        _paybackRequested[msg.sender] = true;

        emit RequestPayback(msg.sender);
    }

    /// @inheritdoc IWrappedCBT
    function minStakeAmount()
        external
        view
        override
        returns (uint256)
    {
        return _minStakeAmount;
    }

    /// @inheritdoc IWrappedCBT
    function isStaking(address account)
        public
        view
        override
        returns (bool)
    {
        return balanceOf(account) > 0
            || _pendingReceiveStakes[account].amount > 0;
    }

    /// @inheritdoc IWrappedCBT
    function isPaybackRequested(address account)
        external
        view
        override
        returns (bool)
    {
        return _paybackRequested[account];
    }

    // ######################
    // ## Owner functions  ##
    // ######################

    /// @inheritdoc IWrappedCBT
    function acceptPayback(address account)
        external
        override
        onlyOwner
    {
        require (_paybackRequested[account], "SangoContent: no payback request");

        uint256 claimedAmount = balanceOf(account);
        uint256 pendingAmount = _pendingReceiveStakes[account].amount;
        uint256 totalAmount = claimedAmount + pendingAmount;

        require (totalAmount > 0, "WrappedCBT: no amount deposited");
        require (_cbt.balanceOf(address(this)) >= totalAmount, "WrappedCBT: lack of CBT balance");

        _paybackRequested[account] = false;
        delete _pendingReceiveStakes[account];

        if (claimedAmount > 0) {
            _burn(account, claimedAmount);
        }
        _cbt.transfer(account, totalAmount);

        emit AcceptPayback(account, totalAmount);
    }

    /// @inheritdoc IWrappedCBT
    function withdraw(uint256 amount)
        external
        override
        onlyOwner
    {
        _cbt.transfer(msg.sender, amount);
        emit Withdraw(amount);
    }

    /// @inheritdoc IWrappedCBT
    function setLockInterval(uint64 lockInterval)
        external
        override
        onlyOwner
    {
        _lockInterval = lockInterval;
        emit SetLockInterval(lockInterval);
    }

    /// @inheritdoc IWrappedCBT
    function setMinStakeAmount(uint256 amount)
        external
        override
        onlyOwner
    {
        _minStakeAmount = amount;
        emit SetMinStakeAmount(amount);
    }

    /**
     * @dev See {RoyaltyClaimRight-_setApprovalForIncomingToken}
     * TODO: onlyOwner vs onlyGovernance
     */
    function setApprovalForIncomingToken(IERC20 token, bool approved)
        external
        onlyOwner
    {
        _setApprovalForIncomingToken(token, approved);
    }
}
