// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedCBT {
    /**
     * @notice CBTを支払い、同量のwCBTを購入する.
     *
     * @param from CBTを支払うアカウント
     * @param amount 変換するCBT/wCBTの量
     */
    function stake(address from, uint256 amount) external;

    /**
     * @notice 権利確定済のwCBTを受け取る.
     *
     * @param to wCBTを受け取るアカウント
     */
    function receiveWCBT(address to) external;

    /**
     * @notice wCBTと引き換えにCBTを返済する.
     * 権利確定(wCBT受領)前のCBTも返済される. TODO: 仕様確認.
     *
     * @param account 返済対象のアカウント.
     */
    function redeem(address account) external;

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
}
