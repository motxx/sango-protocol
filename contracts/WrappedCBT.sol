// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWrappedCBT } from "./tokens/IWrappedCBT.sol";

/**
 * @notice コンテンツにCBTをstakeした分と同量だけ貰えるトークン(株式).
 */
contract WrappedCBT is ERC20, Ownable, IWrappedCBT {
    address private _cbt;
    uint256 private _minAmount;
    mapping (address => uint256) private _purchasedAmount;

    // ######################
    // ## Owner functions  ##
    // ######################

    constructor(address cbt)
        ERC20("Wrapped CBT", "CBT")
    {
        _cbt = cbt;
    }

    function redeem(address account)
        external
        override
        onlyOwner
    {
        uint256 amount = _purchasedAmount[account];

        require (amount > 0, "WrappedCBT: no amount deposited");
        require (IERC20(_cbt).balanceOf(address(this)) >= amount, "WrappedCBT: lack of CBT balance");

        _purchasedAmount[account] = 0;

        _burn(account, amount);
        IERC20(_cbt).transfer(account, amount);
    }

    function withdraw(uint256 amount)
        external
        onlyOwner
    {
        IERC20(_cbt).transfer(msg.sender, amount);
    }

    function setMinAmount(uint256 amount)
        external
        override
        onlyOwner
    {
        _minAmount = amount;
    }

    // ######################
    // ## Public functions ##
    // ######################

    function purchase(uint256 amount)
        external
        override
    {
        require (amount >= _minAmount, "WrappedCBT: less than minAmount");

        _purchasedAmount[msg.sender] = amount;

        IERC20(_cbt).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function minAmount()
        external
        view
        override
        returns (uint256)
    {
        return _minAmount;
    }
}
