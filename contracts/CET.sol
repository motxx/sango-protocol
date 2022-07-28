// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { IExcitingModule } from "./components/IExcitingModule.sol";
import { ICET } from "./tokens/ICET.sol";

contract CET is ERC20, ICET, AccessControl {
    mapping (address => uint256) private _burnedAmount;
    mapping (address => bool) private _approvedReceivers; // ホワイトリスト形式

    bytes32 constant public EXCITING_MODULE_ROLE = keccak256("EXCITING_MODULE_ROLE");
    bytes32 constant public SANGO_CONTENT_ROLE = keccak256("SANGO_CONTENT_ROLE");

    // ##########################
    // ## Public functions     ##
    // ##########################

    constructor(
        string memory name,
        string memory symbol
    )
        ERC20(name, symbol)
    {
        _setupRole(SANGO_CONTENT_ROLE, msg.sender);
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
    function mint(address account, uint256 amount)
        external
        override
        onlyRole(EXCITING_MODULE_ROLE)
    {
        require (_approvedReceivers[account], "SangoContent: account is not approved");
        _mint(account, amount);
    }

    // ##########################
    // ## SangoContent Roles   ##
    // ##########################

    /// @inheritdoc ICET
    function burn(address account, uint256 amount)
        external
        override
        onlyRole(SANGO_CONTENT_ROLE)
    {
        require (_approvedReceivers[account], "SangoContent: account is not approved");
        _burnedAmount[account] += amount;
        _burn(account, amount);
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
        address to,
        uint256 /* amount */
    )
        internal
        pure
        override
    {
        require (from == address(0) || to == address(0), "CET: not transferable");
    }
}
