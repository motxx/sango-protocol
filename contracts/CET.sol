//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract CET is ERC20, Ownable {
    constructor(uint256 initialSupply)
        ERC20("ContentExcitedToken", "CET")
    {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 supply)
        public
        onlyOwner
    {
        _mint(msg.sender, supply);
    }
}
