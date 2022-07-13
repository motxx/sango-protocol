// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISangoGraph } from "./ISangoGraph.sol";

/**
 * @dev SangoContent のリレーショングラフをシングルトン的に管理するコントラクト
 */
contract SangoGraph is ISangoGraph {
    mapping (address => mapping (address => uint32)) private _graph;
    IERC20 private _rbt;

    constructor(address _rbtAddress) {
        _rbt = IERC20(_rbtAddress);
    }

    function addEdge(address secondary, address primary, uint32 weight)
        external
        override
    {
        // ToDo: 閉路チェック
        _graph[secondary][primary] = weight;
    }

    function getWeight(address secondary, address primary)
        external
        override
        view
        returns (uint32)
    {
        return _graph[secondary][primary];
    }

    function todo(uint256 totalRevenue)
        external
    {
    }
}
