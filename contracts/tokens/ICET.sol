// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IExcitingModule } from "../components/IExcitingModule.sol";

interface ICET {
    /**
     * @notice CETのNFTを発行する.
     * tokenId は 1-indexed で増加する. 初期保有数は 0 になる.
     *
     * @param account 対象アカウント
     */
    function mintNFT(address account) external;

    /**
     * @notice CETの保有数を増加させる.
     *
     * @param account 対象アカウント
     * @param amount 保有数の増分
     */
    function mintAmount(address account, uint256 amount) external;

    /**
     * @notice CETの保有数を減少させる.
     *
     * @param account 対象アカウント
     * @param amount 保有数の減少分
     */
    function burnAmount(address account, uint256 amount) external;

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
     * @notice CETを受け取る権利を与える.
     *
     * @param account 対象のアカウント
     */
    function approveCETReceiver(address account) external;

    /**
     * @notice CETを受け取る権利を剥奪する.
     *
     * @param account 対象のアカウント
     */
    function disapproveCETReceiver(address account) external;

    /**
     * @notice ExcitingModuleにCETのMint権等を与える.
     *
     * @param excitingModule 対象のExcitingModule
     */
    function grantExcitingModule(IExcitingModule excitingModule) external;

    /**
     * @notice ExcitingModuleからCETのMint権等を剥奪する.
     *
     * @param excitingModule 対象のExcitingModule
     */
    function revokeExcitingModule(IExcitingModule excitingModule) external;
}
