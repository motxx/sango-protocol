// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { RoyaltyClaimRight } from "./RoyaltyClaimRight.sol";

contract ManagedRoyaltyClaimRight is RoyaltyClaimRight, Ownable {
    event Mint(address account, uint256 amount);
    event BurnAll();

    address[] private _accounts;
    mapping (address => bool) private _isMember;

    constructor(
        string memory name,
        string memory symbol,
        IERC20[] memory approvedTokens
    )
        RoyaltyClaimRight(name, symbol)
    {
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
    // ## Owner functions    ##
    // ########################

    /**
     * @dev Mint claim rights.
     *
     * Emits an {Mint} event.
     */
    function mint(address account, uint256 amount)
        public
        onlyOwner
    {
        if (!_isMember[account]) {
            _isMember[account] = true;
            _accounts.push(account);
        }
        _mint(account, amount);

        emit Mint(account, amount);
    }

    /**
     * @dev Batch mint claim rights.
     */
    function batchMint(address[] calldata accounts_, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require (accounts_.length == amounts.length, "ManagedRoyaltyClaimRight: mismatch length");
        for (uint32 i = 0; i < accounts_.length;) {
            mint(accounts_[i], amounts[i]);
            unchecked { i++; }
        }
    }

    /**
     * @dev Burn all claim rights
     *
     * Emits a {BurnAll} event.
     */
    function burnAll()
        public
        onlyOwner
    {
        for (uint32 i = 0; i < _accounts.length;) {
            _burn(_accounts[i], balanceOf(_accounts[i]));
            _isMember[_accounts[i]] = false;
            unchecked { i++; }
        }
        delete _accounts;

        emit BurnAll();
    }

    /**
     * @dev See {RoyaltyClaimRight-_setApprovalForIncomingToken}
     */
    function setApprovalForIncomingToken(IERC20 token, bool approved)
        external
        onlyOwner
    {
        _setApprovalForIncomingToken(token, approved);
    }

    /**
     * @dev See {RoyaltyClaimRight-_setMinIncomingAmount}
     */
    function setMinIncomingAmount(IERC20 token, uint256 minAmount)
        external
        onlyOwner
    {
        _setMinIncomingAmount(token, minAmount);
    }

    // ########################
    // ## Internal functions ##
    // ########################

    /**
     * @dev Not transferable token because only owner can change the number of claim rights.
     */
    function _beforeTokenTransfer(address from, address to, uint256 /* amount */)
        internal
        pure
        override
    {
        require (from == address(0) || to == address(0), "ManagedRoyaltyClaimRight: not transferable");
    }
}
