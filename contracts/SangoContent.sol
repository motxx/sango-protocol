// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { RBTProportions } from "./RBTProportions.sol";

contract SangoContent is ISangoContent, Ownable, RBTProportions {
    using Address for address;

    constructor(
        IERC20 rbt,
        address[] memory creators,
        uint256[] memory creatorShares,
        address[] memory primaries,
        uint256[] memory primaryShares,
        uint32 creatorProp,
        uint32 cetBurnerProp,
        uint32 cbtStakerProp,
        uint32 primaryProp
    )
        RBTProportions(rbt)
    {
        _getCreatorShares().initPayees(creators, creatorShares);
        _getPrimaryShares().initPayees(primaries, primaryShares);
        setRBTProportions(creatorProp, cetBurnerProp, cbtStakerProp, primaryProp);
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
}
