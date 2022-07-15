// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ISharesReceiver } from "./shares/ISharesReceiver.sol";
import { IRBT } from "./tokens/IRBT.sol";

contract RBT is ERC20, Ownable, IRBT {
    using Address for address;

    constructor()
        ERC20("RoyaltyBasedToken", "RBT")
    {
    }

    function mint(address to, uint256 amount)
        external
        override
        onlyOwner
    {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        onlyOwner
    {
        _burn(account, amount);
    }

    function _afterTokenTransfer(
        address /* from */,
        address to,
        uint256 amount
    )
        internal
        override
    {
        if (to.isContract()) {
            if (IERC165(to).supportsInterface(type(ISharesReceiver).interfaceId)) {
                // 送信先でトークンの配分を行う
                ISharesReceiver(to).onERC20SharesReceived(amount);
            }
        }
    }
}
