//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IRBT } from "./IRBT.sol";

contract RBT is ERC20, Ownable, IRBT {
    constructor()
        ERC20("RoyaltyBasedToken", "RBT")
    {
    }

    function mint(uint256 supply)
        external
        onlyOwner
    {
        _mint(msg.sender, supply);
    }
}
