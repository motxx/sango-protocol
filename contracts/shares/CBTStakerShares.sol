// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ICBTStakerShares } from "./ICBTStakerShares.sol";
import { DynamicShares } from "./DynamicShares.sol";
import { IWrappedCBT } from "../tokens/IWrappedCBT.sol";

/**
 * @dev CBT Staker に RBT を分配する.
 */
contract CBTStakerShares is ICBTStakerShares, DynamicShares, Ownable, AccessControl {
    using Address for address;

    bytes32 constant public WRAPPED_CBT_ROLE = keccak256("WRAPPED_CBT_ROLE");
    // TODO: 128でreleaseにgasが問題ないか調査.
    uint32 constant public MAX_CBT_STAKERS = 128;

    constructor(IERC20 rbt)
        DynamicShares(rbt, MAX_CBT_STAKERS)
    {
    }

    function grantWrappedCBTRole(IWrappedCBT wCBT)
        external
        onlyOwner
    {
        _grantRole(WRAPPED_CBT_ROLE, address(wCBT));
    }

    function addPayee(address payee, uint256 share)
        public
        onlyRole(WRAPPED_CBT_ROLE)
    {
        require(!payee.isContract(), "CBTStakerShares: only EOA supported");
        _addPayee(payee, share);
    }

    function updatePayee(address payee, uint256 share)
        public
        onlyRole(WRAPPED_CBT_ROLE)
    {
        require(!payee.isContract(), "CBTStakerShares: only EOA supported");
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
        override(ICBTStakerShares, DynamicShares)
        returns (bool)
    {
        return super.isPayee(account);
    }
}
