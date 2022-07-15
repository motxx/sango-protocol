// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "./finance/DynamicShares.sol";

/**
 * @dev CET Burner に RBT を分配する.
 * 現時点で CET Burner は EOA のみ許可.
 * TODO: CET Burner に SangoContent を追加.
 */
contract CETBurnerShares is DynamicShares {
    using Address for address;

    constructor(IERC20 rbt)
        DynamicShares(rbt)
    {
    }

    function addPayee(address payee, uint256 share)
        public
        virtual
        override
        onlyOwner
    {
        require(!payee.isContract(), "CETBurnerShares: currently only EOA supported");
        _payees.push(payee);
        _shares[payee] = share;
        _totalShares += share;
        emit AddPayee(payee, share);
    }
}
