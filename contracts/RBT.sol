//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SangoProtocol } from "./SangoProtocol.sol";

contract RBT is ERC20 {
    address _drl;
    mapping (address => bool) _isRoyaltyProvider;

    constructor(address drl)
        ERC20("RoyaltyBasedToken", "RBT")
    {
        _drl = drl;
        _isRoyaltyProvider[_drl] = true;
    }

    function registerRoyaltyProvider(address royaltyProvider)
        public
    {
        require (msg.sender == _drl, "Not DRL");
        _isRoyaltyProvider[royaltyProvider] = true;
    }

    function mint(uint256 supply)
        public
    {
        // TODO: DRLが担保を持つので、minterは考慮必要
        require (_isRoyaltyProvider[msg.sender], "Not royalty provider");
        _mint(msg.sender, supply);
    }

    // SangoProtocol上の分配処理のフック
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
    {
        // TODO: check if 'to' is SangoProtocol or EOA.
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
    {
    }
}
