// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ICET } from "./tokens/ICET.sol";

contract CET is ERC20, ICET {
    mapping (address => uint256) private _burnedAmount;
    mapping (address => bool) private _approveReceivers; // ホワイトリスト形式

    constructor(
        string memory name,
        string memory symbol
    )
        ERC20(name, symbol)
    {
    }

    function mint(address account, uint256 amount)
        external
        override
        /* onlySangoContent */
    {
        require (_approveReceivers[account], "SangoContent: account is not approved");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        /* onlySangoContent */
    {
        require (_approveReceivers[account], "SangoContent: account is not approved");
        _burnedAmount[account] += amount;
        _burn(account, amount);
    }

    function burnedAmount(address account)
        external
        view
        override
        returns (uint256)
    {
        return _burnedAmount[account];
    }

    function approveCETReceiver(address account)
        external
        /* onlySangoContent */
    {
        _approveReceivers[account] = true;
    }

    function disapproveCETReceiver(address account)
        external
        /* onlySangoContent */
    {
        _approveReceivers[account] = false;
    }

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
