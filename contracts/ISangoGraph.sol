// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISangoGraph {
    function addEdge(address secondary, address primary, uint32 weight) external;
    function getWeight(address secondary, address primary) external view returns (uint32);
}
