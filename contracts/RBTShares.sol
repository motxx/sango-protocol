// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DynamicShares } from "./finance/DynamicShares.sol";

/**
 * @dev SangoContent に流入した RBT を Creator, CET Burner,
 * CBT Staker, Primaries に分配する. 余剰分は Treasury に蓄積される.
 */
contract RBTShares is DynamicShares {
    DynamicShares private _creatorShares;
    DynamicShares private _cetBurnerShares;
    DynamicShares private _cbtStakerShares;
    DynamicShares private _primaryShares;

    IERC20 private _rbt;

    constructor(IERC20 rbt)
        DynamicShares(rbt)
    {
        _creatorShares = new DynamicShares(_rbt);
        _cetBurnerShares = new DynamicShares(_rbt);
        _cbtStakerShares = new DynamicShares(_rbt);
        _primaryShares = new DynamicShares(_rbt);
    }

    /**
     * @dev RBT の分配率を設定する. 各分配率 i は share_i / Σshare_i で決定される.
     * 分配率の再設定は常に可能.
     */
    function setRBTShares(
        uint32 creatorShare_,
        uint32 cetBurnerShare_,
        uint32 cbtStakerShare_,
        uint32 primaryShare_
    )
        public
    {
        resetPayees();
        addPayee(address(_creatorShares), creatorShare_);
        addPayee(address(_cetBurnerShares), cetBurnerShare_);
        addPayee(address(_cbtStakerShares), cbtStakerShare_);
        addPayee(address(_primaryShares), primaryShare_);
        uint256 treasuryShare = 10000
            - (creatorShare_ + cetBurnerShare_ + cbtStakerShare_ + primaryShare_);
        if (treasuryShare > 0) {
            addPayee(address(this), treasuryShare);
        }
    }

    /**
     * @dev Primary に受領者を追加.
     */
    function addPrimaryPayee(address payee, uint32 share)
        public
    {
        _primaryShares.addPayee(payee, share);
    }

    /**
     * @dev Primary 一覧の取得
     */
    function getPrimaries()
        public
        view
        virtual
        returns (address[] memory)
    {
        return _primaryShares.allPayees();
    }

    /**
     * @dev 指定した Creator の RBT を引き落とす
     */
    function releaseCreator(address account)
        public
    {
        _creatorShares.release(account);
    }

    /**
     * @dev 指定した CET Burner の RBT を引き落とす
     */
    function releaseCETBurner(address account)
        public
    {
        _cetBurnerShares.release(account);
    }

    /**
     * @dev 指定した CBT Staker の RBT を引き落とす
     */
    function releaseCBTStaker(address account)
        public
    {
        _cbtStakerShares.release(account);
    }

    /**
     * @dev 指定した Primary の RBT を引き落とす
     */
    function releasePrimary(address account)
        public
    {
        _primaryShares.release(account);
    }
}
