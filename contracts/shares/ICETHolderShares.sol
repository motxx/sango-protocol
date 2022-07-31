// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICET } from "../tokens/ICET.sol";

interface ICETHolderShares {
    function grantCETRole(ICET cet) external;
    function addPayee(address payee, uint256 share) external;
    function updatePayee(address payee, uint256 share) external;
    function isPayee(address account) external view returns (bool);
}
