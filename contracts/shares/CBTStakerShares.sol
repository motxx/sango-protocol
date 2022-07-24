// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "./DynamicShares.sol";

/**
 * @dev CBT Staker に RBT を分配する.
 */
contract CBTStakerShares is DynamicShares {
    using Address for address;

    // TODO: 128でreleaseにgasが問題ないか調査.
    uint32 constant public MAX_CBT_STAKERS = 128;

    constructor(IERC20 rbt)
        DynamicShares(rbt, MAX_CBT_STAKERS)
    {
    }

    function addPayee(address payee, uint256 share)
        public
        onlyOwner
    {
        require(!payee.isContract(), "CBTStakerShares: only EOA supported");
        _addPayee(payee, share);
    }
}
