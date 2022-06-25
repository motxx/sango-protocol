
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExcitingModule {
  // CETを受け取れるかOracleに確認 & CETをMINT
  function mintCET(address addr, ISango sango) external;
  // CETがMINTされる条件を設定
  function setCETMintLogic(ISango sango) external onlyOwner; // ToDo 
  // CETを取得する条件のデータを提供するOracleの設定
  struct Oracle {
  };
  function setCETOracle(Oracle oracle) external onlyOwner; // ToDo 
}
