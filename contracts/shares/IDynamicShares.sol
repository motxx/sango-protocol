// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IDynamicShares {
    function release(IERC20 token, address account) external;
    function withdraw(IERC20 token) external;
    function distribute(IERC20 token, uint256 amount) external;
    function pendingPaymentExists(IERC20 token, address account) external view returns (bool);
    function totalReceived(IERC20 token, address account) external view returns (uint256);
    function alreadyReleased(IERC20 token, address account) external view returns (uint256);
    function shares(address account) external view returns (uint256);
    function allPayees() external view returns (address[] memory);
    function isPayee(address account) external view returns (bool);
}
