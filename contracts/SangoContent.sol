// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { RBTProportions } from "./RBTProportions.sol";

contract SangoContent is ISangoContent, Ownable, RBTProportions {
    event AddPrimary(address secondary, address primary, uint32 share);

    mapping(address => bool) private _isPrimary;

    IERC20 private _rbt;

    constructor(IERC20 rbt)
        RBTProportions(rbt)
    {
        _rbt = rbt;
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
    {
        RBTProportions.setRBTProportions(
            creatorProp,
            cetBurnerProp,
            cbtStakerProp,
            primaryProp
        );
    }

    /// @inheritdoc ISangoContent
    function addPrimary(address primary, uint32 share)
        external
        override
        onlyOwner
    {
        require(!_isPrimary[primary], "SangoContent: it is already primary");
        _isPrimary[primary] = true;
        RBTProportions.addPrimaryPayee(primary, share);
        emit AddPrimary(address(this), primary, share);
    }

    /// @inheritdoc ISangoContent
    function getPrimaries()
        public
        view
        override(ISangoContent, RBTProportions)
        returns (address[] memory)
    {
        return RBTProportions.getPrimaries();
    }
}
