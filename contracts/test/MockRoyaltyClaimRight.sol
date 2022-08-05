// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { RoyaltyClaimRight } from "../claimrights/RoyaltyClaimRight.sol";

contract MockRoyaltyClaimRight is RoyaltyClaimRight {
    constructor(string memory name, string memory symbol)
        RoyaltyClaimRight(name, symbol)
    {}

    function setApprovalForIncomingToken(IERC20 token, bool approved)
        external
    {
        _setApprovalForIncomingToken(token, approved);
    }

    function setMinIncomingAmount(IERC20 token, uint256 minAmount)
        external
    {
        _setMinIncomingAmount(token, minAmount);
    }

    function mint(address to, uint256 amount)
        external
    {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount)
        external
    {
        _burn(account, amount);
    }
}
