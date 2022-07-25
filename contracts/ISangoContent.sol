// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IExcitingModule } from "./components/IExcitingModule.sol";
import { ICET } from "./tokens/ICET.sol";

interface ISangoContent {
    /**
     * @notice RBTの受け取る比率(ベーシスポイント)を設定する.
     * 全体で10000を超えて設定することはできない. 余剰分はTreasuryに入る.
     *
     * @param creatorProp クリエイター側の取り分
     * @param cetBurnerProp CET Burner の全体の取り分
     * @param cbtStakerProp CBT Staker の全体の取り分
     * @param primaryProp addPrimary したコンテンツの全体の取り分
     */
    function setRBTProportions(uint32 creatorProp, uint32 cetBurnerProp, uint32 cbtStakerProp, uint32 primaryProp) external; // onlyOwner

    /**
     * @notice CETを発行するためのActionをチェックする ExcitingModule を設定する.
     * 複数Moduleを設定できる。
     *
     * @param excitingModules ExcitingModule の Contract Addr
     */
    function setExcitingModules(IExcitingModule[] calldata excitingModules) external;

    /**
     * @dev 登録済みの ExcitingModule 一覧を返す.
     */
    function excitingModules() external view returns (IExcitingModule[] memory);

    // #############################
    // ## Contents Royalty Graph  ##
    // #############################

    /**
     * @notice RBTの受け取るPrimary一覧を取得する
     */
    function getPrimaries() external view returns (address[] memory);

    // #############################
    // ## Content Believe Token   ##
    // #############################

    /**
     * @notice account がステークしているか確認
     *
     * @return ステークしている場合 True が帰る
     */
    function isStaking(address account) external view returns (bool);

    /**
     * @notice amount 分 stake する. 株式と同様で返済義務はない.
     * stakeholder は wCBT を獲得し、ガバナンス権(暫定)を得る.
     *
     * @param amount stake するCBTの数量
     */
    function stake(uint256 amount) external;

    /**
     * @notice unstake を要求する. request は記録される.
     */
    function requestUnstake() external;

    /**
     * @notice unstake の要求を承諾し、全額(暫定)引き落とされる.
     *
     * @param account unstake を要求しているアカウント
     */
    function acceptUnstakeRequest(address account) external;

    /**
     * @notice unstake の要求を拒否する.
     *
     * @param account unstake を要求しているアカウント
     */
    // function rejectUnstakeRequest(address account) external; // TODO: 処理内容が明確になってから実装

    /**
     * @notice ステークしてからRBTがもらえるようになるまでの期間を設定する
     *
     * @param lockInterval ステークしてから、RBT受け取る事ができるまでの期間
     */
    function setLockInterval(uint64 lockInterval) external;

    // #############################
    // ## Content Excited Token   ##
    // #############################

    /**
     * @notice Addr(Wallet / Contract)にCETを受け取る権利を与える.
     *
     * @param account CETを受け取るアドレス
     */
    function approveCETReceiver(address account) external;

    /**
     * @notice Addr(Wallet / Contract)からCETを受け取る権利を剥奪する.
     *
     * @param account CETを受け取る権利を剥奪するアドレス
     */
    function disapproveCETReceiver(address account) external;

    /**
     * @notice 登録してある Exciting Module に対し Mint CET を実行を要求する
     * Exciting Serviceは 引数のaccountに対してどれくらいCETがMintできるかを算出, Mintする
     * Note: CET は Primary に対して発行することはできない。
     * 理由として、二次創作を楽しむ(Excited)一次創作は存在しないため
     *
     * @param account CETをMintするアドレス.
     */
    function mintCET(address account) external;

    /**
     * @notice CET を Burn する。これによりBurnerはRBTを受け取る権利を獲る。
     *
     * @param amount CETのBurnする量.
     */
    function burnCET(uint256 amount) external;

    /**
     * @notice addrのBurnした量を取得する
     *
     * @param addr CETのBurn量を確認するAddr.
     */
    function getBurnedCET(address addr) external view returns (uint256);

    /**
     * @dev CETのアドレスを取得する.
     */
    function cet() external view returns (ICET);
}
