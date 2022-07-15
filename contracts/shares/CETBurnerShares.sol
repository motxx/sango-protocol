// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "./DynamicShares.sol";

/**
 * @dev CET Burner に RBT を分配する.
 * 現時点で CET Burner は EOA のみ許可.
 * TODO: CET Burner に SangoContent を追加.
 */
contract CETBurnerShares is DynamicShares {
    using Address for address;

    uint32 constant public MAX_CET_BURNERS = 1024;

    constructor(IERC20 rbt)
        DynamicShares(rbt, MAX_CET_BURNERS)
    {
    }

    function addPayee(address payee, uint256 share)
        public
        onlyOwner
    {
        require(!payee.isContract(), "CETBurnerShares: currently only EOA supported");
        _addPayee(payee, share);
    }
}
