// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the RoyaltyClaimRight.
 */
interface IRoyaltyClaimRight {
    event ApprovalForIncomingToken(address token, bool approved);
    event MinIncomingAmount(address token, uint256 minAmount);
    event Distribute(address token, uint256 amount);
    event Claim(address account, address token, uint256 amount);

    /**
     * @dev Distribute `amount` amounts of `token` from the royalty provider to this contract.
     * Holders of this claim rights can withdraw their portions of royalties.
     *
     * Emits a {Distribute} event.
     */
    function distribute(IERC20 token, uint256 amount) external;

    /**
     * @dev Claim a `token` distribution for `account`.
     * This functions calls external contract function `distribute`.
     *
     * Emits a {Claim} event if the amount > 0, skips emitting otherwise.
     */
    function claimNext(address account, IERC20 token) external;

    /**
     * @dev Claim `token` distributions for `account` by `count` times.
     */
    function claimIterate(address account, IERC20 token, uint32 times) external;

    /**
     * @dev Claim all `token` distributions for `account`.
     */
    function claimAll(address account, IERC20 token) external;

    /**
     * @dev Check the token is approved to distribute.
     */
    function isApprovedToken(IERC20 token) external view returns (bool);

    /**
     * @dev Get the minimum incoming amount.
     */
    function minIncomingAmount(IERC20 token) external view returns (uint256);
}
