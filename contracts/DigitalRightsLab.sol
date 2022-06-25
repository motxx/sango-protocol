//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IDigitalRightsLab } from "./IDigitalRightsLab.sol";
import { ISangoProtocol } from "./ISangoProtocol.sol";
import { RBT } from "./RBT.sol";

contract DigitalRightsLab is IDigitalRightsLab {
    RBT _rbtContract;

    constructor()
    {
        _rbtContract = new RBT();
    }

    function distribute(uint256 royaltyAmount, address to)
        external
    {
        // TODO: Check if 'to' is SangoProtocol.
        _rbtContract.mint(royaltyAmount);
        _rbtContract.transfer(to, royaltyAmount);
        ISangoProtocol(to).distribute();
    }
}
