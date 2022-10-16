// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IRoyaltyClaimRight } from "../claimrights/IRoyaltyClaimRight.sol";
import { IExcitingModule } from "../components/IExcitingModule.sol";

/**
 * @dev Interface of {CET} implementation.
 */
interface ICET {
    event StatementOfCommit(address account, uint256 tokenId);
    event ClaimCET(address account, uint256 afterBalance);
    event SetExcitingModules(IExcitingModule[] newExcitingModules);

    /**
     * @notice Declares a new commitment to the {SangoContent}.
     *
     * Emits a {StatementOfCommit} event.
     */
    function statementOfCommit() external;

    /**
     * @notice Claims earned {CET} from `account` to {ExcitingModule}.
     *
     * Emits a {ClaimCET} event.
     */
    function claimCET(address account) external;

    /**
     * @notice Returns {CET} holding amounts by `account`.
     */
    function holdingAmount(address account) external view returns (uint256);

    /**
     * @dev Returns an array of the exciting modules associated with {CET}.
     */
    function excitingModules() external view returns (IExcitingModule[] memory);

    /**
     * @dev Returns the internal module {RoyaltyClaimRight}.
     */
    function claimRight() external view returns (IRoyaltyClaimRight);

    // ##############################
    // ## ExcitingModule Roles     ##
    // ##############################

    /**
     * @dev Mints `amount` {CET} to `account` by ExcitingModule.
     */
    function mintCET(address account, uint256 amount) external;

    // ##############################
    // ## Owner Roles              ##
    // ##############################

    /**
     * @notice Sets `excitingModules` to mint {CET}.
     *
     * Emits a {SetExcitingModules} event.
     */
    function setExcitingModules(IExcitingModule[] calldata excitingModules) external;
}
