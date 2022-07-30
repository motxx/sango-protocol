// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "./DynamicShares.sol";

/**
 * @dev CET Holder に RBT を分配する.
 * 現時点で CET Holder は EOA のみ許可.
 * TODO: CET Holder に SangoContent を追加.
 */
contract CETHolderShares is DynamicShares {
    using Address for address;

    // プロジェクト別にCET Holderが存在するので、最大値は1024でも多い方.
    // TODO: 1024でreleaseにgasが問題ないか調査.
    uint32 constant public MAX_CET_HOLDERS = 1024;

    constructor(IERC20 rbt)
        DynamicShares(rbt, MAX_CET_HOLDERS)
    {
    }

    function addPayee(address payee, uint256 share)
        public
        onlyOwner
    {
        require(!payee.isContract(), "CETHolderShares: currently only EOA supported");
        _addPayee(payee, share);
    }
}
