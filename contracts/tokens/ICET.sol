// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IExcitingModule } from "../components/IExcitingModule.sol";

interface ICET {
    /**
     * @notice CETをmintする.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice CETをburnする.
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice アカウントがCETをburnした総量を返す.
     */
    function burnedAmount(address account) external view returns (uint256);

    /**
     * @notice アカウントにCETを受け取る権利を与える.
     */
    function approveCETReceiver(address account) external;

    /**
     * @notice アカウントからCETを受け取る権利を剥奪する.
     */
    function disapproveCETReceiver(address account) external;

    /**
     * @notice ExcitingModuleにCETのMint権等を与える.
     */
    function grantExcitingModule(IExcitingModule excitingModule) external;

    /**
     * @notice ExcitingModuleからCETのMint権等を剥奪する.
     */
    function revokeExcitingModule(IExcitingModule excitingModule) external;
}
