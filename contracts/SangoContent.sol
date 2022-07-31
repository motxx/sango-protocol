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
        uint32 cetHolderProp;
        uint32 cbtStakerProp;
        uint32 primaryProp;
        string cetName;
        string cetSymbol;
    }

    using Address for address;

    CET private _cet;
    WrappedCBT private _wrappedCBT;

    constructor(CtorArgs memory args)
        RBTProportions(args.rbt)
    {
        _cet = new CET(args.cetName, args.cetSymbol, msg.sender);
        _wrappedCBT = new WrappedCBT(args.cbt, _getCBTStakerShares(), msg.sender);

        _getCBTStakerShares().grantWrappedCBTRole(_wrappedCBT);
        _getCreatorShares().initPayees(args.creators, args.creatorShares);
        _getPrimaryShares().initPayees(args.primaries, args.primaryShares);
        setRBTProportions(args.creatorProp, args.cetHolderProp, args.cbtStakerProp, args.primaryProp);
    }

    /// @inheritdoc ISangoContent
    function setRBTProportions(
        uint32 creatorProp,
        uint32 cetHolderProp,
        uint32 cbtStakerProp,
        uint32 primaryProp
    )
        public
        override(ISangoContent, RBTProportions)
        /* onlyGovernance */
    {
        RBTProportions.setRBTProportions(
            creatorProp,
            cetHolderProp,
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
