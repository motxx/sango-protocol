// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IExchangeService } from "./components/IExchangeService.sol";
import { IRBT } from "./tokens/IRBT.sol";
import { RBT } from "./RBT.sol";

/**
 * @notice Implementation of {IExchangeService}.
 */
contract ExchangeService is IExchangeService, Ownable {
    using Address for address;

    IRBT private immutable _rbt;
    uint256 private _totalSupply;

    constructor()
    {
        _rbt = new RBT();
    }

    /// @inheritdoc IExchangeService
    function mint(address account, uint256 amount)
        external
        override
        onlyOwner
    {
        _totalSupply += amount;
        _rbt.mint(account, amount);
    }

    /// @inheritdoc IExchangeService
    function burn(uint256 amount)
        external
        override
    {
        require(_totalSupply >= amount, "ExchnageService: burn amount exceeds totalSupply");
        _totalSupply -= amount;
        _rbt.burn(_msgSender(), amount);
    }

    /// @inheritdoc IExchangeService
    function totalSupply()
        external
        view
        override
        returns (uint256)
    {
        return _totalSupply;
    }

    /// @inheritdoc IExchangeService
    function rbt()
        external
        view
        override
        returns (IRBT)
    {
        return _rbt;
    }
}
