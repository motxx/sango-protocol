// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { DynamicShares } from "./DynamicShares.sol";

/**
 * @dev CBT Staker に RBT を分配する.
 */
contract CBTStakerShares is DynamicShares, AccessControl {
    using Address for address;

    bytes32 constant public WRAPPED_CBT_ROLE = keccak256("WRAPPED_CBT_ROLE");
    // TODO: 128でreleaseにgasが問題ないか調査.
    uint32 constant public MAX_CBT_STAKERS = 128;

    constructor(IERC20 rbt)
        DynamicShares(rbt, MAX_CBT_STAKERS)
    {
    }

    function addPayee(address payee, uint256 share)
        public
        onlyRole(WRAPPED_CBT_ROLE)
    {
        require(!payee.isContract(), "CBTStakerShares: only EOA supported");
        _addPayee(payee, share);
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
}
