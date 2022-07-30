// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { IExcitingModule } from "./components/IExcitingModule.sol";
import { ICET } from "./tokens/ICET.sol";

contract CET is ERC721, ICET, AccessControl, Ownable {
    using Counters for Counters.Counter;

    IExcitingModule[] private _excitingModules;

    mapping (address => uint256) private _burnedAmount;
    mapping (address => uint256) private _holdingAmount;
    mapping (address => uint256) private _accountTokenId;
    Counters.Counter private _nextTokenId;

    bytes32 constant public EXCITING_MODULE_ROLE = keccak256("EXCITING_MODULE_ROLE");

    // ##########################
    // ## Public functions     ##
    // ##########################

    constructor(
        string memory name,
        string memory symbol,
        address owner_
    )
        ERC721(name, symbol)
    {
        transferOwnership(owner_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId)
            || AccessControl.supportsInterface(interfaceId);
    }

    /// @inheritdoc ICET
    function holdingAmount(address account)
        external
        view
        override
        returns (uint256)
    {
        return _holdingAmount[account];
    }

    /// @inheritdoc ICET
    function burnedAmount(address account)
        external
        view
        override
        returns (uint256)
    {
        return _burnedAmount[account];
    }

    /// @inheritdoc ICET
    function statementOfCommit()
        external
        override
    {
        require (_accountTokenId[msg.sender] == 0, "CET: NFT already minted");

        _nextTokenId.increment();
        _accountTokenId[msg.sender] = _nextTokenId.current();
        _mint(msg.sender, _nextTokenId.current());
    }

    /// @inheritdoc ICET
    function mintCET(address account)
        external
        override
    {
        for (uint32 i = 0; i < _excitingModules.length;) {
            _excitingModules[i].mintCET(ICET(this), account);
            unchecked { i++; }
        }
    }

    /// @inheritdoc ICET
    function burnAmount(uint256 amount)
        external
        override
    {
        require (_holdingAmount[msg.sender] >= amount, "CET: lack of amount");
        _holdingAmount[msg.sender] -= amount;
        _burnedAmount[msg.sender] += amount;
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

    // ##########################
    // ## ExcitingModule Roles ##
    // ##########################

    /// @inheritdoc ICET
    function mintAmount(address account, uint256 amount)
        external
        override
        onlyRole(EXCITING_MODULE_ROLE)
    {
        require (_accountTokenId[account] > 0, "CET: NFT not minted yet");
        _holdingAmount[account] += amount;
    }

    // ##########################
    // ## Owner Roles          ##
    // ##########################

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
    }

    // ########################
    // ## Internal functions ##
    // ########################

    function _beforeTokenTransfer(
        address from,
        address /* to */,
        uint256 /* tokenId */
    )
        internal
        pure
        override
    {
        require (from == address(0), "CET: not transferable");
    }
}
