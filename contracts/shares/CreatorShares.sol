// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "./DynamicShares.sol";

/**
 * @dev Creator に RBT を分配する.
 */
contract CreatorShares is DynamicShares {
    using Address for address;

    constructor(IERC20 rbt)
        DynamicShares(rbt)
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
}
