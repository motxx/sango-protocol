// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { IExcitingModule } from "./components/IExcitingModule.sol";
import { ICET } from "./tokens/ICET.sol";

contract CET is ERC721, ICET, AccessControl {
    using Counters for Counters.Counter;

    mapping (address => uint256) private _burnedAmount;
    mapping (address => uint256) private _holdingAmount;
    mapping (address => uint256) private _accountTokenId;
    mapping (address => bool) private _approvedReceivers; // ホワイトリスト形式
    Counters.Counter private _nextTokenId;

    bytes32 constant public EXCITING_MODULE_ROLE = keccak256("EXCITING_MODULE_ROLE");
    bytes32 constant public SANGO_CONTENT_ROLE = keccak256("SANGO_CONTENT_ROLE");

    // ##########################
    // ## Public functions     ##
    // ##########################

    constructor(
        string memory name,
        string memory symbol
    )
        ERC721(name, symbol)
    {
        _setupRole(SANGO_CONTENT_ROLE, msg.sender);
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

    // ##########################
    // ## ExcitingModule Roles ##
    // ##########################

    /// @inheritdoc ICET
    function mintAmount(address account, uint256 amount)
        external
        override
        onlyRole(EXCITING_MODULE_ROLE)
    {
        require (_approvedReceivers[account], "CET: account is not approved");
        require (_accountTokenId[account] > 0, "CET: NFT not minted yet");

        _holdingAmount[account] += amount;
    }

    // ##########################
    // ## SangoContent Roles   ##
    // ##########################

    /// @inheritdoc ICET
    function mintNFT(address account)
        external
        override
        onlyRole(SANGO_CONTENT_ROLE)
    {
        require (_approvedReceivers[account], "CET: account is not approved");
        require (_accountTokenId[account] == 0, "CET: NFT already minted");

        _nextTokenId.increment();
        _accountTokenId[account] = _nextTokenId.current();
        _mint(account, _nextTokenId.current());
    }

    /// @inheritdoc ICET
    function burnAmount(address account, uint256 amount)
        external
        override
        onlyRole(SANGO_CONTENT_ROLE)
    {
        require (_approvedReceivers[account], "CET: account is not approved");
        require (_holdingAmount[account] >= amount, "CET: lack of amount");
        _holdingAmount[account] -= amount;
        _burnedAmount[account] += amount;
    }

    /// @inheritdoc ICET
    function approveCETReceiver(address account)
        external
        override
        onlyRole(SANGO_CONTENT_ROLE)
    {
        _approvedReceivers[account] = true;
    }

    /// @inheritdoc ICET
    function disapproveCETReceiver(address account)
        external
        override
        onlyRole(SANGO_CONTENT_ROLE)
    {
        _approvedReceivers[account] = false;
    }

    /// @inheritdoc ICET
    function grantExcitingModule(IExcitingModule excitingModule)
        public
        override
        onlyRole(SANGO_CONTENT_ROLE)
    {
        _grantRole(EXCITING_MODULE_ROLE, address(excitingModule));
    }

    /// @inheritdoc ICET
    function revokeExcitingModule(IExcitingModule excitingModule)
        public
        override
        onlyRole(SANGO_CONTENT_ROLE)
    {
        revokeRole(EXCITING_MODULE_ROLE, address(excitingModule));
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
