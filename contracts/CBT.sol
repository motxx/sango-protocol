// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Implementation of {ICBT}.
 */
contract CBT is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 10 ** 14;

    constructor(address vestingWallet)
        ERC20("ContentBelieveToken", "CBT")
    {
        _mint(vestingWallet, TOTAL_SUPPLY);
    }
}
