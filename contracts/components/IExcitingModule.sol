// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOracle } from "../oracles/IOracle.sol";
import { ICET } from "../tokens/ICET.sol";

/**
 * @dev Interface of {ExcitingModule} for oracles to mint {CET} tokens.
 */
interface IExcitingModule {
    /**
     * @dev Calculates and mints the amount of `cet` to the `account` by oracle.
     */
    function mintCET(ICET cet, address account) external;

    /**
     * @dev Sets `cet` to the `oracle`.
     */
    function setCETOracle(ICET cet, IOracle oracle) external;
}
