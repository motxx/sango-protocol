// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IRoyaltyClaimRight } from "./claimrights/IRoyaltyClaimRight.sol";
import { ManagedRoyaltyClaimRight } from "./claimrights/ManagedRoyaltyClaimRight.sol";
import { IExcitingModule } from "./components/IExcitingModule.sol";
import { ICET } from "./tokens/ICET.sol";

contract CET is ERC721, ICET, IRoyaltyClaimRight, AccessControl, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    IExcitingModule[] private _excitingModules;
    ManagedRoyaltyClaimRight private _claimRight;
    mapping (address => uint256) private _accountTokenId;
    Counters.Counter private _lastTokenId;

    bytes32 constant public EXCITING_MODULE_ROLE = keccak256("EXCITING_MODULE_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        IERC20[] memory approvedTokens,
        address owner_
    )
        ERC721(name, symbol)
    {
        _claimRight = new ManagedRoyaltyClaimRight(name, symbol, approvedTokens);
        transferOwnership(owner_);
    }

    // ##############################
    // ## Public functions         ##
    // ##############################

    // #######################
    // ## CET               ##
    // #######################

    /// @inheritdoc ICET
    function statementOfCommit()
        external
        override
    {
        require (_accountTokenId[msg.sender] == 0, "CET: NFT already minted");

        _lastTokenId.increment();
        _accountTokenId[msg.sender] = _lastTokenId.current();
        _mint(msg.sender, _lastTokenId.current());
        emit StatementOfCommit(msg.sender, _lastTokenId.current());
    }

    /// @inheritdoc ICET
    function claimCET(address account)
        external
        override
        nonReentrant
    {
        for (uint32 i = 0; i < _excitingModules.length;) {
            _excitingModules[i].mintCET(ICET(this), account);
            unchecked { i++; }
        }
        emit ClaimCET(msg.sender, balanceOf(msg.sender));
    }

    /// @inheritdoc ICET
    function holdingAmount(address account)
        external
        view
        override
        returns (uint256)
    {
        return _claimRight.balanceOf(account);
    }

    /// @inheritdoc ICET
    function excitingModules()
        external
        view
        override
        returns (IExcitingModule[] memory)
    {
        return _excitingModules;
    }

    /// @inheritdoc ICET
    function claimRight()
        external
        view
        override
        returns (IRoyaltyClaimRight)
    {
        return _claimRight;
    }

    // #######################
    // ## RoyaltyClaimRight ##
    // #######################

    /// @inheritdoc IRoyaltyClaimRight
    function distribute(IERC20 token, uint256 amount)
        external
        override
    {
        // XXX: 認証済みトークン, 内部コントラクト の関数呼出 なので nonReentrant 不要
        require (_claimRight.isApprovedToken(token), "CET: not approved token");
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(_claimRight), amount);
        _claimRight.distribute(token, amount);
        require (token.allowance(address(this), address(_claimRight)) == 0,
            "CET: can't distribute enough amount to RoyaltyClaimRight class");
    }

    /// @inheritdoc IRoyaltyClaimRight
    function claimNext(address account, IERC20 token)
        public
        override
    {
        _claimRight.claimNext(account, token);
    }

    /// @inheritdoc IRoyaltyClaimRight
    function claimIterate(address account, IERC20 token, uint32 times)
        public
        override
    {
        _claimRight.claimIterate(account, token, times);
    }

    /// @inheritdoc IRoyaltyClaimRight
    function claimAll(address account, IERC20 token)
        public
        override
    {
        _claimRight.claimAll(account, token);
    }

    /// @inheritdoc IRoyaltyClaimRight
    function isApprovedToken(IERC20 token)
        external
        view
        override
        returns (bool)
    {
        return _claimRight.isApprovedToken(token);
    }

    /// @inheritdoc IRoyaltyClaimRight
    function minIncomingAmount(IERC20 token)
        external
        view
        override
        returns (uint256)
    {
        return _claimRight.minIncomingAmount(token);
    }

    // #######################
    // ## Extensions        ##
    // #######################

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId)
            || AccessControl.supportsInterface(interfaceId);
    }

    // ##############################
    // ## ExcitingModule Roles     ##
    // ##############################

    /// @inheritdoc ICET
    function mintCET(address account, uint256 amount)
        external
        override
        onlyRole(EXCITING_MODULE_ROLE)
    {
        require (_accountTokenId[account] > 0, "CET: NFT not minted yet");
        _claimRight.mint(account, amount);
    }

    // ##############################
    // ## Owner Roles              ##
    // ##############################

    /// @inheritdoc ICET
    function setExcitingModules(IExcitingModule[] calldata newExcitingModules)
        external
        override
        onlyOwner
    {
        for (uint32 i = 0; i < _excitingModules.length;) {
            _revokeRole(EXCITING_MODULE_ROLE, address(_excitingModules[i]));
            unchecked { i++; }
        }
        for (uint32 i = 0; i < newExcitingModules.length;) {
            _grantRole(EXCITING_MODULE_ROLE, address(newExcitingModules[i]));
            unchecked { i++; }
        }
        _excitingModules = newExcitingModules;

        emit SetExcitingModules(newExcitingModules);
    }

    /**
     * @dev See {ManagedRoyaltyClaimRight-setApprovalForIncomingToken}
     */
    function setApprovalForIncomingToken(IERC20 token, bool approved)
        external
        onlyOwner
    {
        _claimRight.setApprovalForIncomingToken(token, approved);
    }

    /**
     * @dev See {ManagedRoyaltyClaimRight-setMinIncomingAmount}
     */
    function setMinIncomingAmount(IERC20 token, uint256 minAmount)
        external
        onlyOwner
    {
        _claimRight.setMinIncomingAmount(token, minAmount);
    }

    // ##############################
    // ## Internal functions       ##
    // ##############################

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* tokenId */
    )
        internal
        pure
        override
    {
        require (from == address(0) || to == address(0), "CET: not transferable");
    }
}
