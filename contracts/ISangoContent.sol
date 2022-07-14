// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISangoContent {
    /**
     * @notice RBTの受け取る比率(ベーシスポイント)を設定する.
     * 全体で10000を超えて設定することはできない。
     *
     * @param creatorProp クリエイター側の取り分
     * @param cetBurnerProp CET Burner の全体の取り分
     * @param cbtStakerProp CBT Staker の全体の取り分
     * @param primaryProp addPrimary したコンテンツの全体の取り分
     */
    function setRBTProportions(uint32 creatorProp, uint32 cetBurnerProp, uint32 cbtStakerProp, uint32 primaryProp) external; // onlyOwner

    // #############################
    // ## Contents Royalty Graph  ##
    // #############################
    /**
     * @notice RBTの受け取るChildを設定する。主に二次創作など、リスペクトする対象でありRoyaltyの
     * 一部を渡したいコンテンツが有る場合Childとして指定する。
     * Note: primary からCET経由で RBT を受け取った場合、addPrimaryのContentsにはRBTを分配しない 
     *
     * @param primary RBTを受け取る Sango Contents の Contract Addr
     * @param weight Primary
     *               複数のChildがある場合、個々のWeight / 全体のWeight でRBTが決定される
     */
    function addPrimary(address primary, uint32 weight) external; // onlyOwner

    /**
     * @notice RBTの受け取るPrimary一覧を取得する
     */
    function getPrimaries() external view returns (address[] memory);
}
