// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IExcitingModule } from "../components/IExcitingModule.sol";

interface ICET {
    /**
     * @notice 貢献の宣言.
     *
     * TODO: 引数に targetCommit 宣言した貢献の指標 を追加
     */
    function statementOfCommit() external;

    /**
     * @notice 登録してある Exciting Module に対し Mint CET を実行を要求する
     * Exciting Serviceは 引数のaccountに対してどれくらいCETがMintできるかを算出, Mintする
     * Note: CET は Primary に対して発行することはできない。
     * 理由として、二次創作を楽しむ(Excited)一次創作は存在しないため

     * @param account CETをMintするアドレス.
     */
    function mintCET(address account) external;

    /**
     * @notice アカウントのCETの保有数を増加させる.
     *
     * @param account 対象アカウント
     * @param amount 保有数の増分
     */
    function mintAmount(address account, uint256 amount) external;

    /**
     * @notice 自身のCETの保有数を減少させる.
     *
     * @param amount 保有数の減少分
     */
    function burnAmount(uint256 amount) external;

    /**
     * @notice CETの保有数を返す.
     *
     * @param account 対象のアカウント
     * @return CETの保有数
     */
    function holdingAmount(address account) external view returns (uint256);

    /**
     * @notice burnしたCETの総量を返す.
     *
     * @param account 対象のアカウント
     * @return burnしたCETの総量
     */
    function burnedAmount(address account) external view returns (uint256);

    /**
     * @dev 登録済みの ExcitingModule 一覧を返す.
     */
    function excitingModules() external view returns (IExcitingModule[] memory);

    /**
     * @notice CETを発行するためのActionをチェックする ExcitingModule を設定する.
     * 複数Moduleを設定できる。
     *
     * @param excitingModules ExcitingModule の Contract Addr
     */
    function setExcitingModules(IExcitingModule[] calldata excitingModules) external;
}
