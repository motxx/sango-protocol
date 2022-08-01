// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "./DynamicShares.sol";
import { ICETHolderShares } from "./ICETHolderShares.sol";
import { ICET } from "../tokens/ICET.sol";

/**
 * @dev CET Holder に RBT を分配する.
 * 現時点で CET Holder は EOA のみ許可.
 * TODO: CET Holder に SangoContent を追加.
 */
contract CETHolderShares is ICETHolderShares, DynamicShares, Ownable, AccessControl {
    using Address for address;

    bytes32 constant public CET_ROLE = keccak256("CET_ROLE");
    // プロジェクト別にCET Holderが存在するので、最大値は1024でも多い方.
    // TODO: 1024でreleaseにgasが問題ないか調査.
    uint32 constant public MAX_CET_HOLDERS = 1024;

    constructor()
        DynamicShares(MAX_CET_HOLDERS)
    {
    }

    function grantCETRole(ICET cet)
        external
        onlyOwner
    {
        _grantRole(CET_ROLE, address(cet));
    }

    /**
     * @notice ERC20トークンを分配で使用可能にする.
     */
    function approveToken(IERC20 token)
        public
        onlyOwner
    {
        _approveToken(token);
    }

    /**
     * @notice ERC20トークンを分配で使用不可にする.
     */
    function disapproveToken(IERC20 token)
        public
        onlyOwner
    {
        _disapproveToken(token);
    }

    function addPayee(address payee, uint256 share)
        public
        onlyRole(CET_ROLE)
    {
        require(!payee.isContract(), "CETHolderShares: only EOA supported");
        _addPayee(payee, share);
    }

    function updatePayee(address payee, uint256 share)
        public
        onlyRole(CET_ROLE)
    {
        require(!payee.isContract(), "CETHolderShares: only EOA supported");
        _updatePayee(payee, share);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(DynamicShares, AccessControl)
        returns (bool)
    {
        return DynamicShares.supportsInterface(interfaceId)
            || AccessControl.supportsInterface(interfaceId);
    }

    function isPayee(address account)
        public
        view
        override(ICETHolderShares, DynamicShares)
        returns (bool)
    {
        return super.isPayee(account);
    }
}
