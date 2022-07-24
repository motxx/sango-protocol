// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IExcitingModule } from "./components/IExcitingModule.sol";

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

    // #############################
    // ## Contents Royalty Graph  ##
    // #############################

    /**
     * @notice RBTの受け取るPrimary一覧を取得する
     */
    function getPrimaries() external view returns (address[] memory);

    // #############################
    // ## Contents Excited Token  ##
    // #############################

    /**
     * @notice CETを受け取るAddr(Wallet / Contract)を許可する.
     *
     * @param account CETを受け取るアドレス
     */
    function approveCETReceiver(address account) external;

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
}
