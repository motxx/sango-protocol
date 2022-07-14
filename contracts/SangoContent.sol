// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISangoContent } from "./ISangoContent.sol";
import { RBTProportions } from "./RBTProportions.sol";

contract SangoContent is ISangoContent, Ownable, RBTProportions {
    event AddPrimary(address secondary, address primary, uint32 share);

    mapping(address => bool) private _isPrimary;

    constructor(IERC20 rbt, address[] memory primaries, uint32[] memory shares)
        RBTProportions(rbt)
    {
        require (primaries.length == shares.length, "SangoContent: mismatch length");
        for (uint i = 0; i < primaries.length;) {
            _addPrimary(primaries[i], shares[i]);
            unchecked { i++; }
        }
    }

    /// @inheritdoc ISangoContent
    function setRBTProportions(
        uint32 creatorProp,
        uint32 cetBurnerProp,
        uint32 cbtStakerProp,
        uint32 primaryProp
    )
        public
        override(ISangoContent, RBTProportions)
    {
        RBTProportions.setRBTProportions(
            creatorProp,
            cetBurnerProp,
            cbtStakerProp,
            primaryProp
        );
    }

    // #############################
    // ## Contents Royalty Graph  ##
    // #############################
    /**
     * @notice RBTの受け取るChildを設定する。主に二次創作など、リスペクトする対象でありRoyaltyの
     * 一部を渡したいコンテンツが有る場合Childとして指定する。
     * Note: primary からCET経由で RBT を受け取った場合、addPrimaryのContentsにはRBTを分配しない
     *
     * @param primary RBTを受け取る Sango Contents の Contract Addr
     * @param share  Primary
     *               複数のChildがある場合、個々のWeight / 全体のWeight でRBTが決定される
     */
    function _addPrimary(address primary, uint32 share)
        internal
        onlyOwner
    {
        // 多重辺のないDAGを保証する
        require(primary != address(this), "SangoContent: self loop"); // レアケースと思われる.
        require(!_isPrimary[primary], "SangoContent: already primary");
        _isPrimary[primary] = true;

        RBTProportions.addPrimaryPayee(primary, share);
        emit AddPrimary(address(this), primary, share);
    }

    /// @inheritdoc ISangoContent
    function getPrimaries()
        public
        view
        override(ISangoContent, RBTProportions)
        returns (address[] memory)
    {
        return RBTProportions.getPrimaries();
    }
}
