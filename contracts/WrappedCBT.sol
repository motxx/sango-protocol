// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWrappedCBT } from "./tokens/IWrappedCBT.sol";

/**
 * @notice コンテンツにCBTをstakeした分と同量だけ貰える、コンテンツ毎に発行されるトークン(株式).
 * wCBT の stakeholder は、RBTの分配を受けることができる. また、コンテンツのガバナンス権を持つ場合もある.
 */
contract WrappedCBT is ERC20, Ownable, IWrappedCBT {
    struct PendingReceiveStake {
        uint stakedTimestamp;
        uint256 amount;
    }

    event RequestPayback(address account);
    event AcceptPayback(address account);

    IERC20 private _cbt;
    uint256 private _minAmount;
    uint private _lockInterval;
    mapping (address => uint256) private _receivedStakeAmounts;
    mapping (address => PendingReceiveStake) private _pendingReceiveStakes;
    mapping (address => bool) private _paybackRequested;

    // ######################
    // ## Owner functions  ##
    // ######################

    constructor(IERC20 cbt, address owner_)
        ERC20("Wrapped CBT", "CBT")
    {
        _cbt = cbt;
        transferOwnership(owner_);
    }

    /// @inheritdoc IWrappedCBT
    function acceptPayback(address account)
        external
        override
        onlyOwner
    {
        require (_paybackRequested[account], "SangoContent: no payback request");

        uint256 receivedAmount = _receivedStakeAmounts[account];
        uint256 pendingAmount = _pendingReceiveStakes[account].amount;
        uint256 totalAmount = receivedAmount + pendingAmount;

        require (totalAmount > 0, "WrappedCBT: no amount deposited");
        require (_cbt.balanceOf(address(this)) >= totalAmount, "WrappedCBT: lack of CBT balance");

        _paybackRequested[account] = false;
        delete _receivedStakeAmounts[account];
        delete _pendingReceiveStakes[account];

        _burn(account, receivedAmount);
        _cbt.transfer(account, totalAmount);

        emit AcceptPayback(account);
    }

    /// @inheritdoc IWrappedCBT
    function withdraw(address contentOwner, uint256 amount)
        external
        override
        onlyOwner
    {
        _cbt.transfer(contentOwner, amount);
    }

    /// @inheritdoc IWrappedCBT
    function setLockInterval(uint64 lockInterval)
        external
        override
        onlyOwner
    {
        _lockInterval = lockInterval;
    }

    /// @inheritdoc IWrappedCBT
    function setMinAmount(uint256 amount)
        external
        override
        onlyOwner
    {
        _minAmount = amount;
    }

    // ######################
    // ## Public functions ##
    // ######################

    /// @inheritdoc IWrappedCBT
    function minAmount()
        external
        view
        override
        returns (uint256)
    {
        return _minAmount;
    }

    /// @inheritdoc IWrappedCBT
    function isStaking(address account)
        public
        view
        override
        returns (bool)
    {
        return _receivedStakeAmounts[account] > 0
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

    /// @inheritdoc IWrappedCBT
    function stake(uint256 amount)
        external
        override
    {
        require (amount >= _minAmount, "WrappedCBT: less than minAmount");
        require (_pendingReceiveStakes[msg.sender].amount == 0, "WrappedCBT: pending stake exists");
        require (_receivedStakeAmounts[msg.sender] == 0, "WrappedCBT: already staked");

        _pendingReceiveStakes[msg.sender] = PendingReceiveStake(block.timestamp, amount);

        _cbt.transferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IWrappedCBT
    function receiveWCBT()
        external
        override
    {
        PendingReceiveStake storage ps = _pendingReceiveStakes[msg.sender];

        require (ps.amount > 0, "WrappedCBT: no pending stake exists");
        require (ps.stakedTimestamp + _lockInterval <= block.timestamp, "WrappedCBT: within lock interval");

        uint256 amount = ps.amount;
        _receivedStakeAmounts[msg.sender] += amount;

        delete _pendingReceiveStakes[msg.sender];

        _mint(msg.sender, amount);
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
}
