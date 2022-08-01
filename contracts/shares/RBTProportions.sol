// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CETHolderShares } from "./CETHolderShares.sol";
import { DynamicShares } from "./DynamicShares.sol";
import { CreatorShares } from "./CreatorShares.sol";
import { CETHolderShares } from "./CETHolderShares.sol";
import { CBTStakerShares } from "./CBTStakerShares.sol";
import { PrimaryShares } from "./PrimaryShares.sol";

/**
 * @dev SangoContent に流入した RBT を Creator, CET Holder,
 * CBT Staker, Primaries に分配する. 余剰分は Treasury に蓄積される.
 */
contract RBTProportions is DynamicShares {
    CreatorShares private _creatorShares;
    CETHolderShares private _cetHolderShares;
    CBTStakerShares private _cbtStakerShares;
    PrimaryShares private _primaryShares;

    IERC20 private _rbt;

    // Creators, CET Holders, CBTStakers, Primaries, Treasury
    uint32 constant public MAX_PAYEES = 5;

    constructor(IERC20 rbt)
        DynamicShares(rbt, MAX_PAYEES)
    {
        _rbt = rbt;
        _creatorShares = new CreatorShares(_rbt);
        _cetHolderShares = new CETHolderShares(_rbt);
        _cbtStakerShares = new CBTStakerShares(_rbt);
        _primaryShares = new PrimaryShares(_rbt);
    }

    /**
     * @dev RBT の分配率(ベーシスポイント)を設定する. 分配率の再設定は常に可能.
     *
     * RBTの入手方法により分配が変化する
     * 1) 直接 Royalty Provider から transfer された場合
     *    この場合は、Creator / CET Holder / CBT Staker / Primaries に対して設定した比率で分配される
     *    余剰分は Treasury として SangoContent に残る.
     *
     * 2) TODO: Primary より CET Holder として分配された場合
     *    この場合は、Primaries を除いた Creator / CET Holder / CBT Staker に対して設定した比率が拡張され分配される
     */
    function setRBTProportions(
        uint32 creatorProp,
        uint32 cetHolderProp,
        uint32 cbtStakerProp,
        uint32 primaryProp
    )
        public
        virtual
        /* onlyGovernance */
    {
        require(creatorProp + cetHolderProp + cbtStakerProp + primaryProp <= 10000,
            "RBTProportions: sum proportions <= 10000");

        _resetPayees();
        _addPayee(address(_creatorShares), creatorProp);
        _addPayee(address(_cetHolderShares), cetHolderProp);
        _addPayee(address(_cbtStakerShares), cbtStakerProp);
        _addPayee(address(_primaryShares), primaryProp);

        uint256 treasuryProp =
            10000 - (creatorProp + cetHolderProp + cbtStakerProp + primaryProp);
        if (treasuryProp > 0) {
            // 10000 未満の場合、余剰分が Treasury に蓄積する.
            _addPayee(address(this), treasuryProp);
        }
    }

    /**
     * @dev Creator の分配率を取得.
     */
    function creatorProportion()
        public
        view
        returns (uint32)
    {
        return uint32(shares(address(_creatorShares)));
    }

    /**
     * @dev CET Holder の分配率を取得.
     */
    function cetHolderProportion()
        public
        view
        returns (uint32)
    {
        return uint32(shares(address(_cetHolderShares)));
    }

    /**
     * @dev CBT Staker の分配率を取得.
     */
    function cbtStakerProportion()
        public
        view
        returns (uint32)
    {
        return uint32(shares(address(_cbtStakerShares)));
    }

    /**
     * @dev Primary の分配率を取得.
     */
    function primaryProportion()
        public
        view
        returns (uint32)
    {
        return uint32(shares(address(_primaryShares)));
    }

    /**
     * @dev Treasury の分配率を取得.
     */
    function treasuryProportion()
        public
        view
        returns (uint32)
    {
        return uint32(shares(address(this)));
    }

    function releaseCreatorShares(address account)
        public
    {
        if (pendingPaymentExists(address(_creatorShares))) {
            release(address(_creatorShares));
        }
        _creatorShares.release(account);
    }

    function releaseCETHolderShares(address account)
        public
    {
        if (pendingPaymentExists(address(_cetHolderShares))) {
            release(address(_cetHolderShares));
        }
        _cetHolderShares.release(account);
    }

    function releaseCBTStakerShares(address account)
        public
    {
        if (pendingPaymentExists(address(_cbtStakerShares))) {
            release(address(_cbtStakerShares));
        }
        _cbtStakerShares.release(account);
    }

    function releasePrimaryShares(address account)
        public
    {
        if (pendingPaymentExists(address(_primaryShares))) {
            release(address(_primaryShares));
        }
        _primaryShares.release(account);
    }

    /**
     * @dev CreatorShares の取得
     */
    function _getCreatorShares()
        internal
        view
        virtual
        returns (CreatorShares)
    {
        return _creatorShares;
    }

    /**
     * @dev CETHolderShares の取得
     */
    function _getCETHolderShares()
        internal
        view
        virtual
        returns (CETHolderShares)
    {
        return _cetHolderShares;
    }

    /**
     * @dev CBTStakerShares の取得
     */
    function _getCBTStakerShares()
        internal
        view
        virtual
        returns (CBTStakerShares)
    {
        return _cbtStakerShares;
    }

    /**
     * @dev PrimaryShares の取得
     */
    function _getPrimaryShares()
        internal
        view
        virtual
        returns (PrimaryShares)
    {
        return _primaryShares;
    }
}
