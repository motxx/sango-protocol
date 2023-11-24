// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IRBT } from "../tokens/IRBT.sol";

/**
 * @dev Interface of {ExchangeService} for exchanging among fiat currencies and {RBT} tokens.
 */
interface IExchangeService {
    /**
     * @dev Mints `amount` {RBT} tokens to the `account`.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burns `amount` {RBT} tokens from the `msg.sender`.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Returns total supply of {RBT}.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Gets the {RBT} instance.
     */
    function rbt() external view returns (IRBT);
}
