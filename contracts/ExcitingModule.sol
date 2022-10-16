// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IExcitingModule } from "./components/IExcitingModule.sol";
import { IOracle } from "./oracles/IOracle.sol";
import { ICET } from "./tokens/ICET.sol";

/**
 * @notice Implementation of {IExcitingModule}.
 */
contract ExcitingModule is IExcitingModule, Ownable {
    mapping (ICET => IOracle) private _oracles;
    mapping (ICET => mapping (address => uint256)) private _alreadyMinted;

    /// @inheritdoc IExcitingModule
    function mintCET(ICET cet, address account)
        external
        override
    {
        uint256 amount = _getTotalEngagement(cet, account) - _alreadyMinted[cet][account];
        require (amount > 0, "ExcitingModule: no amount to mint");
        _alreadyMinted[cet][account] += amount;
        cet.mintCET(account, amount);
    }

    /// @inheritdoc IExcitingModule
    function setCETOracle(ICET cet, IOracle oracle)
        external
        override
        onlyOwner
    {
        _oracles[cet] = oracle;
    }

    function _getTotalEngagement(ICET cet, address account)
        private
        view
        returns (uint256)
    {
        require (address(_oracles[cet]) != address(0), "ExcitingModule: no oracle set");
        return _oracles[cet].responses(cet, account).totalEngagement;
    }
}
