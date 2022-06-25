//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDigitalRightsLab {
    function distribute(uint256 royaltyAmount, address to) external;
}
