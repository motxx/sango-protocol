//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISangoProtocol {
    function statement(address receiver) external;

    function addChild(address child) external;
    function setParent(address parent) external;
    function getChildren() external view returns (address[] memory);
    function getParent() external view returns (address);
}
