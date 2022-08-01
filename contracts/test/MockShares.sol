// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "../shares/DynamicShares.sol";

/**
 * @dev DynamicShares の全機能をテストするための Mock
 */
contract MockShares is DynamicShares, Ownable {
    using Address for address;

    uint32 constant public MAX_PAYEES = 100;

    constructor()
        DynamicShares(MAX_PAYEES)
    {
    }

    function approveToken(IERC20 token)
        external
        onlyOwner
    {
        _approveToken(token);
    }

    function disapproveToken(IERC20 token)
        external
        onlyOwner
    {
        _disapproveToken(token);
    }

    function initPayees(address[] calldata payees, uint256[] calldata shares_)
        external
        onlyOwner
    {
        _initPayees(payees, shares_);
    }

    function addPayee(address payee, uint256 share)
        external
        onlyOwner
    {
        _addPayee(payee, share);
    }

    function resetPayees()
        external
        onlyOwner
    {
        _resetPayees();
    }
}
