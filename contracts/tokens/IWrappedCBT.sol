// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedCBT {
    // ######################
    // ## Owner functions  ##
    // ######################

    /**
     * @notice 返済の要求を承諾し、wCBTと引き換えにCBTを返済する.
     * 権利確定(wCBT受領)前のCBTも返済される.

     * @param account 返済対象のアカウント
     */
    function acceptPayback(address account) external;

    /**
     * @notice stakeされているCBTをOwnerが引き落とす.
     *
     * @param contentOwner コンテンツのOwner(クリエイター)
     * @param amount 引き落とす金額
     */
    function withdraw(address contentOwner, uint256 amount) external;

    /**
     * @notice 権利確定までのロック期間を設定する.
     *
     * @param lockInterval ロック期間.
     */
    function setLockInterval(uint64 lockInterval) external;

    /**
     * @notice 購入の最低金額を設定する.
     *
     * @param amount 設定する最低金額
     */
    function setMinAmount(uint256 amount) external;

    // ######################
    // ## Public functions ##
    // ######################

    /**
     * @notice 購入の最低金額を取得する.
     *
     * @return 現在の最低金額
     */
    function minAmount() external view returns (uint256);

    /**
     * @notice stake 済か否かを返す. 権利確定前でも stake されていれば真を返す.
     *
     * @return 購入したか否か
     */
    function isStaking(address account) external view returns (bool);

    /**
     * @notice account が返済要求中かを確認
     *
     * @return 要求中である場合 True が返る
     */
    function isPaybackRequested(address account) external view returns (bool);

    /**
     * @notice CBTを支払い、ロック期間終了後に同量のwCBTを受け取る.
     *
     * @param amount CBT/wBTの量
     */
    function stake(uint256 amount) external;

    /**
     * @notice 権利確定済のwCBTを受け取る.
     */
    function claimWCBT() external;

    /**
     * @notice 返済を要求する.
     */
    function requestPayback() external;
}
