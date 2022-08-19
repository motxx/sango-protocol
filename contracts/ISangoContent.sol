// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { FixedRoyaltyClaimRight } from "./claimrights/FixedRoyaltyClaimRight.sol";
import { ManagedRoyaltyClaimRight } from "./claimrights/ManagedRoyaltyClaimRight.sol";
import { IExcitingModule } from "./components/IExcitingModule.sol";
import { ICET } from "./tokens/ICET.sol";
import { IWrappedCBT } from "./tokens/IWrappedCBT.sol";

interface ISangoContent {
    event SetRoyaltyAllocation(
        uint256 creatorAlloc, uint256 cbtStakerAlloc, uint256 cetHolderAlloc,
        uint256 primaryAlloc, uint256 treasuryAlloc);
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
     * @notice ロイヤリティの受け取る比率(ベーシスポイント)を設定する.
     * 全体で10000を超えて設定することはできない. 余剰分はTreasuryに入る.
     *
     * ロイヤリティの入手方法により分配が変化する
     * 1) 直接 Royalty Provider から transfer された場合
     *    この場合は、Creatorr / CBT Stake / CET Holder / Primaries / Treasury に対して設定した比率で分配される
     *
     * 2) TODO: Primary より CET Holder として分配された場合
     *    この場合は、Primaries を除いた Creator / CBT Staker / CET Holder に対して設定した比率が拡張され分配される
     *
     * Emits a {SetRoyaltyAllocation} event.
     *
     * @param creatorsAlloc クリエイター側の取り分
     * @param cbtStakersAlloc CBT Staker の全体の取り分
     * @param cetHoldersAlloc CET Holder の全体の取り分
     * @param primariesAlloc addPrimary したコンテンツの全体の取り分
     */
    function setRoyaltyAllocation(
        uint32 creatorsAlloc,
        uint32 cbtStakersAlloc,
        uint32 cetHoldersAlloc,
        uint32 primariesAlloc
    ) external;

    /**
     * @notice Approve `token` to distribute to royalty receivers.
     */
    function setApprovalForIncomingToken(IERC20 token, bool approved) external;

    // ###########################
    // ## Public functions      ##
    // ###########################

    /**
     * @notice ロイヤリティを受け取るCreatorを管理するコントラクトを取得する
     */
    function creators() external view returns (ManagedRoyaltyClaimRight);

    /**
     * @notice ロイヤリティを受け取るPrimaryを管理するコントラクトを取得する
     */
    function primaries() external view returns (FixedRoyaltyClaimRight);

    /**
     * @notice Treasuryを管理するコントラクトを取得する
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
