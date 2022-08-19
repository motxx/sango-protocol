// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TimelockController } from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import { IVotes } from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GovernorDelegate } from "./GovernorDelegate.sol";
import { ISangoGovernor } from "./ISangoGovernor.sol";
import { ISangoContent } from "../ISangoContent.sol";

contract SangoGovernor is ISangoGovernor, GovernorDelegate {
    TimelockController private _timelock;
    ISangoContent private _parent;

    constructor(IVotes wrappedCBT, ISangoContent parent)
        GovernorDelegate(wrappedCBT, _timelock)
    {
        _parent = parent;
    }

    /// @inheritdoc ISangoGovernor
    function setRoyaltyAllocation(
        uint32 creatorsAlloc,
        uint32 cbtStakersAlloc,
        uint32 cetHoldersAlloc,
        uint32 primariesAlloc
    )
        external
        override
        onlyGovernance
    {
        _parent.setRoyaltyAllocation(
            creatorsAlloc,
            cbtStakersAlloc,
            cetHoldersAlloc,
            primariesAlloc
        );
    }

    /// @inheritdoc ISangoGovernor
    function setApprovalForIncomingToken(IERC20 token, bool approved)
        external
        override
        onlyGovernance
    {
        _parent.setApprovalForIncomingToken(token, approved);
    }
}
