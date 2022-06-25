//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchangeService {
    // 受け取っていた状態でRBTを royaltyAmount だけ to に送る
    function mint(uint256 royaltyAmount, address to) external;
    

}
