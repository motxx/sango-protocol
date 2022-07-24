// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICET {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function burnedAmount(address account) external view returns (uint256);
}
