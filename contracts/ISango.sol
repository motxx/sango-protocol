//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// このクラスの責務
// - CBT のステーク, アンステーク
// - CET の受け取り表明, Burn（CETのMintは ExcitingService にまかせる)
// - Contents Royalty Graph 管理, RBT distribution
interface ISango {
    function distribute() external;

    function setGovernance(address governance) external;
    function setExcitingServices(address[] exciting) external onlyOwner;
   
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
    function getGraphScale () external view ();
    // このグラフの親を取得
    function getRoot () external view ();

    // -------- CBT --------
    // CBTをステークする
    // 一ユーザー, 一回だけ
    function stake(uint amount) external; // ToDo
    // ステークしてるCBTを全額引き出す
    function unstake() external; // ToDo
    // 自分がステークしているか確認
    function isMeStaking() external view returns (bool);

    // ステークしてからRBTがもらえるようになるまでの期間を設定する
    function setLockInterval(uint time) external onlyOwner; // Todo 

    struct StakeInfo { 
        uint timestamp;
        uint amount;
        uint propotion;
    };
    // - Stake 時間 / 量 / 比率(現在の);
    function getStekeInfo() external view (StakeInfo); // ToDo

    // -------- CET --------
    // CETを受け取るAddr(Wallet / Contract)の表明
    function statement(address receiver) external;

    // 登録してある Exciting Module に対し Mint CET を実行する
    function mintCET(address addr) external view (uint); // ToDo
    // CET を Burn する
    function burnCET(uint amount) external; // ToDo 
    // Burn した総量を確認
    function getBurnedCET(address addr) view  (uint); // ToDo
}
