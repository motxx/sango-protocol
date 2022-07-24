// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CBT is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 2 ** 14; // TODO

    constructor(address vestingWallet)
        ERC20("ContentBelieveToken", "CBT")
    {
        // TODO: 発行量の調整は VestingWallet でよいか (_mintを段階的にすべきではないか?)
        _mint(vestingWallet, TOTAL_SUPPLY);
    }
}
