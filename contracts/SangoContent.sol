// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { CET } from "./CET.sol";
import { WrappedCBT } from "./WrappedCBT.sol";
import { FixedRoyaltyClaimRight } from "./claimrights/FixedRoyaltyClaimRight.sol";
import { ManagedRoyaltyClaimRight } from "./claimrights/ManagedRoyaltyClaimRight.sol";
import { RoyaltyClaimRight } from "./claimrights/RoyaltyClaimRight.sol";
import { SangoGovernor } from "./governance/SangoGovernor.sol";
import { ICET } from "./tokens/ICET.sol";
import { IWrappedCBT } from "./tokens/IWrappedCBT.sol";

contract SangoContent is ISangoContent, RoyaltyClaimRight, AccessControl {
    ManagedRoyaltyClaimRight private _creators;
    WrappedCBT private _wrappedCBT;
    CET private _cet;
    FixedRoyaltyClaimRight private _primaries;
    ManagedRoyaltyClaimRight private _treasury;

    SangoGovernor private _governor;

    bytes32 constant public SANGO_GOVERNER_ROLE = keccak256("SANGO_GOVERNER_ROLE");

    constructor(ConstructorArgs memory args)
        RoyaltyClaimRight("Content Claim Right", "CClaimRight")
    {
        _wrappedCBT = new WrappedCBT(
            args.cbt,
            args.approvedTokens,
            msg.sender
        );

        _cet = new CET(
            args.cetName,
            args.cetSymbol,
            args.approvedTokens,
            msg.sender
        );

        _creators = new ManagedRoyaltyClaimRight(
            "Creators Claim Right",
            "CRClaimRight",
            args.approvedTokens
        );
        _creators.batchMint(args.creators, args.creatorShares);
        _creators.transferOwnership(msg.sender);

        _primaries = new FixedRoyaltyClaimRight(
            "Primaries Claim Right",
            "PRClaimRight",
            args.primaries,
            args.primaryShares,
            args.approvedTokens
        );

        _treasury = new ManagedRoyaltyClaimRight(
            "Treasury Claim Right",
            "TRClaimRight",
            args.approvedTokens
        );

        _approveForIncomingTokens(args.approvedTokens);
        _setRoyaltyAllocation(args.creatorsAlloc, args.cbtStakersAlloc, args.cetHoldersAlloc, args.primariesAlloc);

        _governor = new SangoGovernor(_wrappedCBT, this);
        _grantRole(SANGO_GOVERNER_ROLE, address(_governor));
    }

    // #############################
    // ## Governance functions    ##
    // #############################

    /// @inheritdoc ISangoContent
    function setRoyaltyAllocation(
        uint32 creatorsAlloc,
        uint32 cbtStakersAlloc,
        uint32 cetHoldersAlloc,
        uint32 primariesAlloc
    )
        public
        override
        onlyRole(SANGO_GOVERNER_ROLE)
    {
        _setRoyaltyAllocation(creatorsAlloc, cbtStakersAlloc, cetHoldersAlloc, primariesAlloc);
    }

    /// @inheritdoc ISangoContent
    function setApprovalForIncomingToken(IERC20 token, bool approved)
        external
        override
        onlyRole(SANGO_GOVERNER_ROLE)
    {
        _setApprovalForIncomingToken(token, approved);
        _creators.setApprovalForIncomingToken(token, approved);
        _wrappedCBT.setApprovalForIncomingToken(token, approved);
        _cet.setApprovalForIncomingToken(token, approved);
        // _primaries.setApprovalForIncomingToken(token, approved); // TODO: Primary に支払う token は後決め可能か?
        _treasury.setApprovalForIncomingToken(token, approved);
    }

    // #############################
    // ## Public functions        ##
    // #############################

    /// @inheritdoc ISangoContent
    function creators()
        public
        view
        override
        returns (ManagedRoyaltyClaimRight)
    {
        return _creators;
    }

    /// @inheritdoc ISangoContent
    function primaries()
        public
        view
        override
        returns (FixedRoyaltyClaimRight)
    {
        return _primaries;
    }

    /// @inheritdoc ISangoContent
    function treasury()
        public
        view
        override
        returns (ManagedRoyaltyClaimRight)
    {
        return _treasury;
    }

    /// @inheritdoc ISangoContent
    function forceClaimAll(IERC20 token)
        external
        override
    {
        claimAll(address(_creators), token);
        claimAll(address(_wrappedCBT), token);
        claimAll(address(_cet), token);
        claimAll(address(_primaries), token);
        claimAll(address(_treasury), token);

        emit ForceClaimAll(token);
    }

    // #############################
    // ## Content Believe Token   ##
    // #############################

    /// @inheritdoc ISangoContent
    function wrappedCBT()
        external
        view
        override
        returns (IWrappedCBT)
    {
        return _wrappedCBT;
    }

    // #############################
    // ## Content Excited Token   ##
    // #############################

    /// @inheritdoc ISangoContent
    function cet()
        external
        view
        override
        returns (ICET)
    {
        return _cet;
    }

    // #############################
    // ## Internal functions      ##
    // #############################

    /**
     * @dev Not transferable token because only owner can change allocation.
     */
    function _beforeTokenTransfer(address from, address to, uint256 /* amount */)
        internal
        pure
        override
    {
        require (from == address(0) || to == address(0), "SangoContent: not transferable");
    }

    /**
     * @dev Set `amount` as the allocation for `account`.
     */
    function _setAllocation(address account, uint32 amount)
        internal
    {
        require (amount <= 10000, "SangoContent: alloc <= 10000");
        _burn(account, balanceOf(account));
        _mint(account, amount);
    }

    /**
     * @dev Internal function for {ISangoContent-setRoyaltyAllocation}
     */
    function _setRoyaltyAllocation(
        uint32 creatorsAlloc,
        uint32 cbtStakersAlloc,
        uint32 cetHoldersAlloc,
        uint32 primariesAlloc
    )
        internal
    {
        require (creatorsAlloc <= 10000 && cbtStakersAlloc <= 10000
            && cetHoldersAlloc <= 10000 && primariesAlloc <= 10000,
            "SangoContent: each alloc <= 10000"
        );
        uint32 mainAllocSum = creatorsAlloc + cbtStakersAlloc + cetHoldersAlloc + primariesAlloc;
        require (mainAllocSum <= 10000, "RoyaltyProportions: alloc sum <= 10000");

        _setAllocation(address(_creators), creatorsAlloc);
        _setAllocation(address(_wrappedCBT), cbtStakersAlloc);
        _setAllocation(address(_cet), cetHoldersAlloc);
        _setAllocation(address(_primaries), primariesAlloc);

        uint32 treasuryAlloc = 10000 - mainAllocSum;
        _setAllocation(address(_treasury), treasuryAlloc);

        emit SetRoyaltyAllocation(creatorsAlloc, cbtStakersAlloc, cetHoldersAlloc, primariesAlloc, treasuryAlloc);
    }
}
