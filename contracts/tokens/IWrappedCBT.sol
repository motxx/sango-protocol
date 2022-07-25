// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedCBT {
    /**
     * @notice CBTを支払い、同量のWrappedCBTを購入する.
     *
     * @param amount 変換するCBT/WrappedCBTの量
     */
    function stake(uint256 amount) external;

    /**
     * @notice 権利確定済のWrappedCBTを受け取る.
     */
    function receiveWCBT() external;

    /**
     * @notice WrappedCBTと引き換えにCBTを返済する.
     * 権利確定(WrappedCBT受領)前のCBTも返済される. TODO: 仕様確認.
     *
     * @param account 返済対象のアカウント.
     */
    function redeem(address account) external;

    /**
     * @notice stakeされているCBTをOwnerが引き落とす.
     *
     * @param amount 引き落とす金額
     */
    function withdraw(uint256 amount) external;

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
