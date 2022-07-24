// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { RBTProportions } from "./RBTProportions.sol";
import { CET } from "./CET.sol";
import { IExcitingModule } from "./components/IExcitingModule.sol";

contract SangoContent is ISangoContent, Ownable, RBTProportions {
    using Address for address;

    IExcitingModule[] private _excitingModules;
    CET private _cet;

    constructor(
        IERC20 rbt,
        address[] memory creators,
        uint256[] memory creatorShares,
        address[] memory primaries,
        uint256[] memory primaryShares,
        uint32 creatorProp,
        uint32 cetBurnerProp,
        uint32 cbtStakerProp,
        uint32 primaryProp,
        string memory cetName,
        string memory cetSymbol
    )
        RBTProportions(rbt)
    {
        _getCreatorShares().initPayees(creators, creatorShares);
        _getPrimaryShares().initPayees(primaries, primaryShares);
        setRBTProportions(creatorProp, cetBurnerProp, cbtStakerProp, primaryProp);
        _cet = new CET(cetName, cetSymbol);
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

    /// @inheritdoc ISangoContent
    function setExcitingModules(IExcitingModule[] calldata excitingModules)
        external
        override
        /* onlyGovernance */
    {
        _excitingModules = excitingModules;
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
    // ## Contents Excited Token  ##
    // #############################

    /// @inheritdoc ISangoContent
    function approveCETReceiver(address account)
        external
        override
        /* onlyGovernance */
    {
        _cet.approveCETReceiver(account);
    }

    function cet()
        external
        view
        returns (CET)
    {
        return _cet;
    }

    /// @inheritdoc ISangoContent
    function mintCET(address account)
        external
        override
        /* onlyGovernance */
    {
        for (uint32 i = 0; i < _excitingModules.length;) {
            _excitingModules[i].mintCET(_cet, account);
            unchecked { i++; }
        }
    }

    /// @inheritdoc ISangoContent
    function burnCET(uint256 amount)
        external
        override
    {
        _cet.burn(_msgSender(), amount);
    }

    /// @inheritdoc ISangoContent
    function getBurnedCET(address account)
        external
        view
        override
        returns (uint256)
    {
        return _cet.burnedAmount(account);
    }
}
