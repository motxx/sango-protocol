// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IOracle, Response } from "../oracles/IOracle.sol";
import { ICET } from "../tokens/ICET.sol";

contract MockOracle is IOracle, Ownable {
    mapping (ICET => mapping (address => string)) private _mockIds;
    mapping (ICET => mapping (address => Response)) private _responses;

    /// @inheritdoc IOracle
    function setId(ICET cet, address account, string memory id_)
        external
        override
        onlyOwner
    {
        _mockIds[cet][account] = id_;
    }

    /// @inheritdoc IOracle
    function id(ICET cet, address account)
        external
        view
        override
        returns (string memory)
    {
        return _mockIds[cet][account];
    }

    /// @inheritdoc IOracle
    function responses(ICET /* cet */, address /* account */)
        external
        pure /* view */
        override
        returns (Response memory)
    {
        return Response({
            title: "MockTitle",
            totalEngagement: 10000
        });
    }
}
