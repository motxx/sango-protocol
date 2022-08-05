// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { RoyaltyClaimRight } from "./RoyaltyClaimRight.sol";

contract FixedRoyaltyClaimRight is RoyaltyClaimRight {
    address[] private _accounts;
    mapping (address => bool) private _isMember;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory accounts_,
        uint256[] memory amounts,
        IERC20[] memory approvedTokens
    )
        RoyaltyClaimRight(name, symbol)
    {
        require (accounts_.length == amounts.length, "FixedRoyaltyClaimRight: mismatch length");
        for (uint32 i = 0; i < accounts_.length;) {
            _mint(accounts_[i], amounts[i]);
            require (!_isMember[accounts_[i]], "FixedRoyaltyClaimRight: duplicate accounts");
            _isMember[accounts_[i]] = true;
            _accounts.push(accounts_[i]);
            unchecked { i++; }
        }
        _approveForIncomingTokens(approvedTokens);
    }

    // ########################
    // ## Public functions   ##
    // ########################

    /**
     * @dev Get all accounts to have royalty claim rights.
     */
    function accounts()
        external
        view
        returns (address[] memory)
    {
        return _accounts;
    }

    // ########################
    // ## Internal functions ##
    // ########################

    /**
     * @dev Not transferable token because of fixed number of claim rights.
     */
    function _beforeTokenTransfer(address from, address to, uint256 /* amount */)
        internal
        pure
        override
    {
        require (from == address(0) || to == address(0), "FixedRoyaltyClaimRight: not transferable");
    }
}
