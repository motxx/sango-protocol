// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IRBT } from "../tokens/IRBT.sol";

// ExchangeService の責務
// Fiat と RBT の交換をする
interface IExchangeService {
    // 受け取っていた状態でRBTを amount だけ to に送る
    function mint(address account, uint256 amount) external; // onlyOwner

    // RBT をBurnする。（外の世界でFiatをAddrに対して送る)
    function burn(uint256 amount) external;

    // RBTの現在発行量, Fiat の保有量を表す.
    function totalSupply() external view returns (uint256);

    // RBTのインスタンスを取得
    function rbt() external view returns (IRBT);
}
