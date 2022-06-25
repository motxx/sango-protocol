//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISangoBase {
    function distribute() external;

    // Contents Register Service invokes
    // - constructor / setCETPropotion / setCBTPropotion
    function setCETPropotion(uint32 propotion) external onlyOwner;
    function setCBTPropotion(uint32 propotion) external onlyOwner; // ToDo 
    // - addChild 二次創作のときに親コンテンツを指定する

    // -------- Contents Royalty Graph --------
    function addChild(address child) external onlyOwner; // 二次創作創作を表現できる
    function setParent(address parent) external ; // 暫定
    function getChildren() external view returns (address[] memory);
    function getParent() external view returns (address);

    // コンテンツの親子含めグラフ全体の規模
    // - Contents / Wallet数
    // - CBT staked
    // - CET mited / burn
    // - RBT received 
    function contentsGraphScale () external view ();
    // このグラフの親を取得
    function getRoot () external view ();

    // -------- CBT --------
    // CBTをステークする
    // 一ユーザー, 一回だけ
    function stake(uint amount) external; // ToDo
    // ステークしてるCBTを全額引き出す
    function unstake() external; // ToDo
    // 
    function isMeStaking() external view returns (bool);

    // ステークしてからRBTがもらえるようになるまでの期間を設定する
    function setLockInterval(uint time) external onlyOwner; // Todo 

    struct StakeInfo { 
        uint timestamp;
        uint amount;
        uint propotion;
    };
    // - Stake 時間 / 量 / 比率(現在の);
    function getSteke() external view (StakeInfo); // ToDo

    // -------- CET --------
    // CETを受け取るAddr(Wallet / Contract)の表明
    function statement(address receiver) external;

    // CET を Burn する
    function burnCET(uint amount) external; // ToDo 
    // Burn した総量を確認
    function getBurnedCET(address addr) view  (uint); // ToDo
}
