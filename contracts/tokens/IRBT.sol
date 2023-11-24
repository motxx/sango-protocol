// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Interface of {RBT} implementation.
 */
interface IRBT {
    /**
     * @notice Mints `amount` {RBT} to `to` account.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burns `amount` {RBT} from `account`.
     */
    function burn(address account, uint256 amount) external;
}
