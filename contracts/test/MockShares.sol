// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "../shares/DynamicShares.sol";

/**
 * @dev DynamicShares の全機能をテストするための Mock
 */
contract MockShares is DynamicShares {
    using Address for address;

    constructor(IERC20 rbt)
        DynamicShares(rbt)
    {
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
