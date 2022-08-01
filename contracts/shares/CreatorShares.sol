// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "./DynamicShares.sol";

/**
 * @dev Creator に RBT を分配する.
 */
contract CreatorShares is DynamicShares, Ownable {
    using Address for address;

    uint32 constant public MAX_CREATORS = 128;

    constructor()
        DynamicShares(MAX_CREATORS)
    {
    }

    /**
     * @dev Creator の取り分を初期化する.
     */
    function initPayees(address[] calldata payees, uint256[] calldata shares_)
        public
        onlyOwner
    {
        for (uint32 i = 0; i < payees.length;) {
            require(!payees[i].isContract(), "CreatorShares: only EOA supported");
            unchecked { i++; }
        }
        _initPayees(payees, shares_);
    }

    /**
     * @notice ERC20トークンを分配で使用可能にする.
     */
    function approveToken(IERC20 token)
        public
        onlyOwner
    {
        _approveToken(token);
    }

    /**
     * @notice ERC20トークンを分配で使用不可にする.
     */
    function disapproveToken(IERC20 token)
        public
        onlyOwner
    {
        _disapproveToken(token);
    }
}
