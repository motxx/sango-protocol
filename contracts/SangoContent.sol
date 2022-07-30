// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { CET } from "./CET.sol";
import { RBTProportions } from "./shares/RBTProportions.sol";
import { ICET } from "./tokens/ICET.sol";
import { IWrappedCBT } from "./tokens/IWrappedCBT.sol";
import { WrappedCBT } from "./WrappedCBT.sol";

contract SangoContent is ISangoContent, Ownable, RBTProportions {
    // XXX: Deal with `Stack Too Deep`
    struct CtorArgs {
        IERC20 rbt;
        IERC20 cbt;
        address[] creators;
        uint256[] creatorShares;
        address[] primaries;
        uint256[] primaryShares;
        uint32 creatorProp;
        uint32 cetBurnerProp;
        uint32 cbtStakerProp;
        uint32 primaryProp;
        string cetName;
        string cetSymbol;
    }

    using Address for address;

    event RequestUnstake(address account);
    event AcceptUnstakeRequest(address account);

    CET private _cet;
    WrappedCBT private _wrappedCBT;
    mapping (address => bool) private _unstakeRequested;

    constructor(CtorArgs memory args)
        RBTProportions(args.rbt)
    {
        _getCreatorShares().initPayees(args.creators, args.creatorShares);
        _getPrimaryShares().initPayees(args.primaries, args.primaryShares);
        setRBTProportions(args.creatorProp, args.cetBurnerProp, args.cbtStakerProp, args.primaryProp);
        _cet = new CET(args.cetName, args.cetSymbol, msg.sender);
        _wrappedCBT = new WrappedCBT(args.cbt);
    }

    /// @inheritdoc ISangoContent
    function setRBTProportions(
        uint32 creatorProp,
        uint32 cetBurnerProp,
        uint32 cbtStakerProp,
        uint32 primaryProp
    )
        public
        override(ISangoContent, RBTProportions)
        /* onlyGovernance */
    {
        RBTProportions.setRBTProportions(
            creatorProp,
            cetBurnerProp,
            cbtStakerProp,
            primaryProp
        );
    }

    // #############################
    // ## Contents Royalty Graph  ##
    // #############################

    /// @inheritdoc ISangoContent
    function getPrimaries()
        public
        view
        override
        returns (address[] memory)
    {
        return _getPrimaryShares().allPayees();
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

    /// @inheritdoc ISangoContent
    function isStaking(address account)
        public
        view
        override
        returns (bool)
    {
        return _wrappedCBT.isStaking(account);
    }

    /// @inheritdoc ISangoContent
    function isUnstakeRequested(address account)
        external
        view
        override
        returns (bool)
    {
        return _unstakeRequested[account];
    }

    /// @inheritdoc ISangoContent
    function stake(uint256 amount)
        external
        override
    {
        _wrappedCBT.stake(msg.sender, amount);
    }

    /// @inheritdoc ISangoContent
    function receiveWCBT()
        external
        override
    {
        _wrappedCBT.receiveWCBT(msg.sender);
    }

    /// @inheritdoc ISangoContent
    function requestUnstake()
        external
        override
    {
        require (isStaking(msg.sender), "SangoContent: no amount staked");
        require (!_unstakeRequested[msg.sender], "SangoContent: already unstake requested");
        _unstakeRequested[msg.sender] = true;

        emit RequestUnstake(msg.sender);
    }

    /// @inheritdoc ISangoContent
    function acceptUnstakeRequest(address account)
        external
        override
        onlyOwner
    {
        require (_unstakeRequested[account], "SangoContent: no unstake request");
        _unstakeRequested[account] = false;
        _wrappedCBT.payback(account);

        emit AcceptUnstakeRequest(account);
    }

    /// @inheritdoc ISangoContent
    function withdraw(uint256 amount)
        external
        override
        onlyOwner
    {
        _wrappedCBT.withdraw(msg.sender, amount);
    }

    /// @inheritdoc ISangoContent
    function setLockInterval(uint64 lockInterval)
        external
        override
        onlyOwner
    {
        _wrappedCBT.setLockInterval(lockInterval);
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
}
