// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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

    // #############################
    // ## Contents Royalty Graph  ##
    // #############################

    /**
     * @notice RBTの受け取るPrimary一覧を取得する
     */
    function getPrimaries() external view returns (address[] memory);
}
