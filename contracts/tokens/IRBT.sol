// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRBT {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}
