// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISharesReceiver {
    /**
     * @dev ERC20のトークンを受け取った際の分配
     */
    function onERC20SharesReceived(uint256 amount) external;
}
