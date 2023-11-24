// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { FixedRoyaltyClaimRight } from "./claimrights/FixedRoyaltyClaimRight.sol";
import { ManagedRoyaltyClaimRight } from "./claimrights/ManagedRoyaltyClaimRight.sol";
import { IExcitingModule } from "./components/IExcitingModule.sol";
import { ICET } from "./tokens/ICET.sol";
import { IWrappedCBT } from "./tokens/IWrappedCBT.sol";

/**
 * @notice Interface of {SangoContent} implementation.
 */
interface ISangoContent {
    event SetRoyaltyAllocation(
        uint256 creatorAlloc, uint256 cbtStakerAlloc, uint256 cetHolderAlloc,
        uint256 primaryAlloc, uint256 treasuryAlloc);

    event SetApprovalForIncomingToken(
        address token,
        bool approved
    );

    event ForceClaimAll(IERC20 token);

    // XXX: Deal with `Stack Too Deep`
    struct ConstructorArgs {
        IERC20 cbt;
        IERC20[] approvedTokens;
        address[] creators;
        uint256[] creatorShares;
        address[] primaries;
        uint256[] primaryShares;
        uint32 creatorsAlloc;
        uint32 cbtStakersAlloc;
        uint32 cetHoldersAlloc;
        uint32 primariesAlloc;
        string cetName;
        string cetSymbol;
    }

    // #############################
    // ## Governance functions    ##
    // #############################

    /**
     * @dev Sets the royalty allocation. Each argument is specified by basis points.
     *
     * Emits a {SetRoyaltyAllocation} event.
     */
    function setRoyaltyAllocation(
        uint32 creatorsAlloc,
        uint32 cbtStakersAlloc,
        uint32 cetHoldersAlloc,
        uint32 primariesAlloc
    ) external;

    /**
     * @dev Approve `token` to distribute to royalty receivers.
     *
     * Emits an {ApprovalForIncomingToken} event.
     */
    function setApprovalForIncomingToken(IERC20 token, bool approved) external;

    // ###########################
    // ## Public functions      ##
    // ###########################

    /**
     * @notice Gets the {RoyaltyClaimRight} contract for creators.
     */
    function creators() external view returns (ManagedRoyaltyClaimRight);

    /**
     * @notice Gets the {RoyaltyClaimRight} contract for primaries.
     */
    function primaries() external view returns (FixedRoyaltyClaimRight);

    /**
     * @notice Gets the {RoyaltyClaimRight} contract for treasury.
     */
    function treasury() external view returns (ManagedRoyaltyClaimRight);

    /**
     * @notice Claim all pending `token` distributions.
     *
     * Emits a {ForceClaimAll} event.
     */
    function forceClaimAll(IERC20 token) external;

    // ###########################
    // ## Content Believe Token ##
    // ###########################

    /**
     * @notice コンテンツの発行する WrappedCBT のアドレスを返す.
     */
    function wrappedCBT() external view returns (IWrappedCBT);

    // ###########################
    // ## Content Excited Token ##
    // ###########################

    /**
     * @notice CETのアドレスを取得する.
     */
    function cet() external view returns (ICET);
}
