// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IOracle } from "../oracles/IOracle.sol";
import { ICET } from "../tokens/ICET.sol";

interface IExcitingModule {
    /**
     * @notice CETを受け取れるかOracleに確認 & CETをMINT
     * @param cet CETのアドレス
     * @param account Mint対象のアカウント
     */
    function mintCET(ICET cet, address account) external;

    // CETがMINTされる条件を設定 TODO: 想定している具体的な条件を聞く
    // function setCETMintLogic(ICET cet) external; // onlyOwner // TODO

    /**
     * @notice ChainLinkのオラクルを設定する
     * @param oracle ChainLinkClient
     */
    function setCETOracle(ICET cet, IOracle oracle) external; // onlyOwner
}
