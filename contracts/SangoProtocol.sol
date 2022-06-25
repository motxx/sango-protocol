//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ISangoProtocol } from "./ISangoProtocol.sol";

contract SangoProtocol is ERC721, ISangoProtocol {
    mapping (address => uint256) _cetBalance;
    address _parent;
    address[] _children;

    constructor()
        ERC721("SangoProtocol", "Sango")
    {
    }

    function statement(address receiver)
        external
    {
    }

    // Graph

    function addChild(address child)
        external
    {
        _children.push(child);
        SangoProtocol(child).setParent(address(this));
    }

    function setParent(address parent)
        external
    {
        _parent = parent;
    }

    function getChildren()
        external
        view
        returns (address[] memory)
    {
        return _children;
    }

    function getParent()
        external
        view
        returns (address)
    {
        return _parent;
    }

    // interface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(ISangoProtocol).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
