// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IWrappedCBT } from "../tokens/IWrappedCBT.sol";

interface ICBTStakerShares {
    function grantWrappedCBTRole(IWrappedCBT wCBT) external;
    function addPayee(address payee, uint256 share) external;
    function updatePayee(address payee, uint256 share) external;
    function isPayee(address account) external view returns (bool);
}
