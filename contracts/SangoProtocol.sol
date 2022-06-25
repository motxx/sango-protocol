//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { CET } from "./CET.sol";
import { ISangoProtocol } from "./ISangoProtocol.sol";

struct RoyaltyPropotions {
    address[] receivers;
    uint32[] propotions; // 0 (0.00 %) ~ 10000 (100.00 %)
}

contract SangoProtocol is ERC721, Ownable, ISangoProtocol {
    address _rbtAddress; // RBT token address
    uint32 _cetPropotion; // CET の割合 (子コンテンツへの分配率). 0 (0.00 %) ~ 10000 (100.00 %).

    CET _cetContract; // 自コンテンツが発行するCET.

    address _parent; // 親コンテンツ (SangoProtocol).
    address[] _children; // 子コンテンツ (SangoProtocol). CETの分配対象.
    RoyaltyPropotions _creators; // クリエイター (EOA).    

    constructor(RoyaltyPropotions memory creators, address rbtAddress)
        ERC721("SangoProtocol", "Sango")
    {
        uint length = creators.receivers.length;
        require (length == creators.propotions.length, "Mismatch length.");
        uint32 total = 0;
        for (uint32 i = 0; i < length; i++) {
            total += creators.propotions[i];
        }
        require (total == 10000, "Total propotion must be 10000.");

        _creators = creators;
        _rbtAddress = rbtAddress;

        _cetContract = new CET();
    }

    function statement(address receiver)
        external
    {
    }

    function distribute()
        external
    {
        IERC20 r = IERC20(_rbtAddress);

        // 受け取ったRBTの総量
        uint256 totalRBT = r.balanceOf(address(this));

        // 子コンテンツ (CET) 側を切り捨てる
        uint256 childrenRBT = totalRBT * _cetPropotion / 10000;

        // 子コンテンツのCET総数を計算
        uint256 totalCET = 0;
        for (uint32 i = 0; i < _children.length; i++) {
            uint256 cet = _cetContract.balanceOf(_children[i]);
            totalCET += cet;
        }
        // CETの割合に応じてRBTを分配
        uint256 usedCET = 0;
        for (uint32 i = 0; i < _children.length; i++) {
            uint256 cet = i < _children.length - 1
                ? _cetContract.balanceOf(_children[i])
                : totalCET - usedCET;
            usedCET += cet;
            uint256 rbt = childrenRBT * cet / totalCET;
            IERC20(_rbtAddress).transfer(_children[i], rbt);
            ISangoProtocol(_children[i]).distribute();
        }
    }

    // Creator

    function setCETPropotion(uint32 propotion)
        external
        onlyOwner
    {
        require (propotion <= 10000, "Propotion <= 10000");
        _cetPropotion = propotion;
    }

    // Graph

    // 許諾は未実装 (二次創作作った場合に登録可能としたい).
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
