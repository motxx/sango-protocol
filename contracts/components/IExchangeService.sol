//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ExchangeService の責務
// Fiat と RBT の交換をする
interface IExchangeService {
    
    // RBTの現在発行量, Fiat の保有量を表す.
    function totalSupply () external view returns (uint);

    // 受け取っていた状態でRBTを royaltyAmount だけ to に送る
    function mint(uint256 royaltyAmount, address to) external onlyOwner;
    
    // RBT をBurnする。（外の世界でFiatをAddrに対して送る)
    function burn(uint amount) external;
    
}
