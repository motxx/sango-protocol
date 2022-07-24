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
    function purchase(uint256 amount) external;

    /**
     * @notice WrappedCBTと引き換えにCBTを返済する.
     *
     * @param account 返済対象のアカウント.
     */
    function redeem(address account) external;

    /**
     * @notice 購入の最低金額を設定する.
     *
     * @param amount 設定する最低金額
     */
    function updateMinAmount(uint256 amount) external;

    /**
     * @notice 購入の最低金額を取得する.
     *
     * @return 現在の最低金額
     */
    function minAmount() external view returns (uint256);
}
