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

    IERC20 private _cbt;
    uint256 private _minAmount;
    uint private _lockInterval;
    mapping (address => uint256) private _receivedStakeAmounts;
    mapping (address => PendingReceiveStake) private _pendingReceiveStakes;

    // ######################
    // ## Owner functions  ##
    // ######################

    constructor(IERC20 cbt)
        ERC20("Wrapped CBT", "CBT")
    {
        _cbt = cbt;
    }

    /// @inheritdoc IWrappedCBT
    function redeem(address account)
        external
        override
        onlyOwner
    {
        uint256 receivedAmount = _receivedStakeAmounts[account];
        uint256 pendingAmount = _pendingReceiveStakes[account].amount;
        uint256 totalAmount = receivedAmount + pendingAmount;

        require (totalAmount > 0, "WrappedCBT: no amount deposited");
        require (_cbt.balanceOf(address(this)) >= totalAmount, "WrappedCBT: lack of CBT balance");

        delete _receivedStakeAmounts[account];
        delete _pendingReceiveStakes[account];

        _burn(account, receivedAmount);
        _cbt.transfer(account, totalAmount);
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

    /// @inheritdoc IWrappedCBT
    function stake(address from, uint256 amount)
        external
        override
        onlyOwner
    {
        require (amount >= _minAmount, "WrappedCBT: less than minAmount");
        require (_pendingReceiveStakes[from].amount == 0, "WrappedCBT: pending stake exists");

        _pendingReceiveStakes[from] = PendingReceiveStake(block.timestamp, amount);

        _cbt.transferFrom(from, address(this), amount);
    }

    /// @inheritdoc IWrappedCBT
    function receiveWCBT(address to)
        external
        override
        onlyOwner
    {
        PendingReceiveStake storage ps = _pendingReceiveStakes[to];

        require (ps.amount > 0, "WrappedCBT: no pending stake exists");
        require (ps.stakedTimestamp + _lockInterval <= block.timestamp, "WrappedCBT: within lock interval");

        uint256 amount = ps.amount;
        _receivedStakeAmounts[to] += amount;

        delete _pendingReceiveStakes[to];

        _mint(to, amount);
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
}
