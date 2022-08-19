// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISangoGovernor {
    /**
     * @dev SangoContentのsetRoyaltyAllocationを呼び出す.
     */
    function setRoyaltyAllocation(
        uint32 creatorsAlloc,
        uint32 cbtStakersAlloc,
        uint32 cetHoldersAlloc,
        uint32 primariesAlloc
    ) external;

    /**
     * @dev SangoContentのsetApprovalForIncomingTokenを呼び出す.
     */
    function setApprovalForIncomingToken(IERC20 token, bool approved) external;
}
