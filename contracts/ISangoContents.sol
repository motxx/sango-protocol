//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// このクラスの責務
// - CBT のステーク, アンステーク
// - CET の受け取り表明, Burn（CETのMintは ExcitingService にまかせる)
// - Contents Royalty Graph 管理, RBT distribution
interface ISangoContents {

    /**
     * @notice treasury に溜まったRBT を Creator / CET Burner / CBT Staker / Primaries に対して分配を行う.
     *
     * Distribute について、割合はsetRBTPropotionによって決定される.
     * なお、RBTの入手方法により分配が変化する
     * 1) 直接 Royalty Provider から distribute された場合
     *    この場合は、Creator / CET Burner / CBT Staker / Primaries に対して設定した比率に分配される
     * 2) Primary より, CET Burner として分配されて場合
     *    この場合は、Primaries を覗いた Creator / CET Burner / CBT Staker に対して設定した比率が拡張され分配される
     */
    function distribute() external;

    /**
     * @notice ガバナンスを行うモジュールContractを設定する。
     * Contract は以下のInterfaceを実装しており、SangoContentsのガバナンスを行う。
     * 指定していない場合、Ownerが権限を持つ。
     *
     * @param governance ガバナンスを行うモジュールのContract Addr
     */
    function setGovernance(address governance) external;

    /**
     * @notice CETを発行するためのActionをチェックする ExcitingService を設定する.
     * 複数Serviceを設定できる。
     *
     * @param excitingServices Excitign Service の Contract Addr
     */
    function setExcitingServices(address[] excitingServices) external onlyOwner;
   
    /**
     * @notice RBTの受け取る比率を設定する.
     * 全体で100を超えて設定することはできない。
     *
     * @param creators クリエイター側の取り分
     * @param cetProp CET Burner の全体の取り分
     * @param cbtProp CBT Staker の全体の取り分
     * @param primaryProp addPrimary したコンテンツの全体の取り分
     */
    function setRBTPropotion(uint32 creators, uint32 cetProp, uint32 cbtProp, uint32 primaryProp) external onlyOwner;

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
    function addPrimary(address primary, uint32 weight) external onlyOwner;

    function addSecondary(address parent) external ; // 暫定

    /**
     * @notice RBTの受け取るChild一覧を取得する
     */
    function getPrimaries() external view returns (address[] memory);

    /**
     * @notice RBTを配給するParentの一覧を取得する
     */
    function getSecondaries() external view returns (address[]);

    struct GraphScale {
        uint32 totalCETReceivers; // CETを受け取ったWallet/Contract数
        uint32 totalCBTStakers;   // CBTをステークした人の数
        uint32 totalStakedCBT;   // ステークされたCBTの量 (lock含む)
        uint32 totalMintedCET;   // MintされたCETの量
        uint32 totalBurnedCET;   // BurnされたCETの量
        uint32 totalReceivedRBT; // 受け取ったRBTの総量
    }
    /**
     * @notice コンテンツの親子含めグラフ全体の規模を返す
     *
     * @return GraphScale を返す
     */
    function getGraphScale () external view ();
    // このグラフの親を取得
    function getRoot () external view ();

    // #############################
    // ## Contents Believe Token  ##
    // #############################
    /**
     * @notice CBTをステークする. 1 Wallet は1回だけステークすることができる.
     * lock intervalを経過しないとRBTの分配を受けることはできない
     *
     * @param amount ステークするCBTの量
     */
    function stake(uint amount) external; // ToDo
    /**
     * @notice ステークしているCBTを全て取り出す
     */
    function unstake() external; // ToDo
    /**
     * @notice 自分がステークしているか確認
     *
     * @return ステークしている場合 True が帰る
     */
    function isMeStaking() external view returns (bool);

    /**
     * @notice ステークしてからRBTがもらえるようになるまでの期間を設定する
     *
     * @param time ステークしてから、RBT受け取る事ができるまでの期間
     */
    function setLockInterval(uint32 time) external onlyOwner; // Todo 

    struct StakeInfo { 
        uint elapsedTime;   // ステークしてからの経過時間
        uint amount;        // ステーク量
        uint propotion;     // 現在のCBTステーク総量に対する割合 (canReceiveRBT関係ない?)
        bool canReceiveRBT; // RBTを受け取ることができるか
    };
    /**
     * @notice 自分のステークしているCBT情報を返す。
     *
     * @return StakeInfo
     */
    function getStekeInfo() external view (StakeInfo); // ToDo

    // #############################
    // ## Contents Excited Token  ##
    // #############################
    // CETを受け取るAddr(Wallet / Contract)の表明
    function statement(address receiver) external;

    /**
     * @notice 登録してある Exciting Module に対し Mint CET を実行を要求する
     * Exciting Serviceは 引数のAddrに対してどれくらいCETがMintできるかを算出, Mintする
     * Note: CET は Primary に対して発行することはできない。
     * 理由として、二次創作を楽しむ(Excited)一次創作は存在しないため
     *
     * @param addr CETをMintするアドレス.
     */
    function mintCET(address addr) external view (uint); // ToDo

    /**
     * @notice CET を Burn する。これによりBurnerはRBTを受け取る権利を獲る。
     *
     * @param amount CETのBurnする量.
     */
    function burnCET(uint amount) external; // ToDo

    /**
     * @notice addrのBurnした量を取得する
     *
     * @param addr CETのBurn量を確認するAddr.
     */
    function getBurnedCET(address addr) view  (uint); // ToDo
}
