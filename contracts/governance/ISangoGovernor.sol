// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Abstract implementation of {SangoGovernor}.
 */
interface ISangoGovernor {
    /**
     * @dev Sets {SangoContent} royaly allocations.
     */
    function setRoyaltyAllocation(
        uint32 creatorsAlloc,
        uint32 cbtStakersAlloc,
        uint32 cetHoldersAlloc,
        uint32 primariesAlloc
    ) external;

    /**
     * @dev Grants or revokes permission for {SangoContent} to recieve `token`, according to `approved`.
     */
    function setApprovalForIncomingToken(IERC20 token, bool approved) external;
}
