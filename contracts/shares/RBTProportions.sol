// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CETBurnerShares } from "./CETBurnerShares.sol";
import { DynamicShares } from "./DynamicShares.sol";
import { CreatorShares } from "./CreatorShares.sol";
import { CETBurnerShares } from "./CETBurnerShares.sol";
import { CBTStakerShares } from "./CBTStakerShares.sol";
import { PrimaryShares } from "./PrimaryShares.sol";

/**
 * @dev SangoContent に流入した RBT を Creator, CET Burner,
 * CBT Staker, Primaries に分配する. 余剰分は Treasury に蓄積される.
 */
contract RBTProportions is DynamicShares {
    CreatorShares private _creatorShares;
    CETBurnerShares private _cetBurnerShares;
    CBTStakerShares private _cbtStakerShares;
    PrimaryShares private _primaryShares;

    IERC20 private _rbt;

    // Creators, CET Burners, CBTStakers, Primaries, Treasury
    uint32 constant public MAX_PAYEES = 5;

    constructor(IERC20 rbt)
        DynamicShares(rbt, MAX_PAYEES)
    {
        _rbt = rbt;
        _creatorShares = new CreatorShares(_rbt);
        _cetBurnerShares = new CETBurnerShares(_rbt);
        _cbtStakerShares = new CBTStakerShares(_rbt);
        _primaryShares = new PrimaryShares(_rbt);
    }

    /**
     * @dev RBT の分配率(ベーシスポイント)を設定する. 分配率の再設定は常に可能.
     *
     * RBTの入手方法により分配が変化する
     * 1) 直接 Royalty Provider から transfer された場合
     *    この場合は、Creator / CET Burner / CBT Staker / Primaries に対して設定した比率で分配される
     *    余剰分は Treasury として SangoContent に残る.
     *
     * 2) TODO: Primary より CET Burner として分配された場合
     *    この場合は、Primaries を除いた Creator / CET Burner / CBT Staker に対して設定した比率が拡張され分配される
     */
    function setRBTProportions(
        uint32 creatorProp,
        uint32 cetBurnerProp,
        uint32 cbtStakerProp,
        uint32 primaryProp
    )
        public
        virtual
    {
        require(creatorProp + cetBurnerProp + cbtStakerProp + primaryProp <= 10000,
            "RBTProportions: sum proportions <= 10000");

        _resetPayees();
        _addPayee(address(_creatorShares), creatorProp);
        _addPayee(address(_cetBurnerShares), cetBurnerProp);
        _addPayee(address(_cbtStakerShares), cbtStakerProp);
        _addPayee(address(_primaryShares), primaryProp);

        uint256 treasuryProp =
            10000 - (creatorProp + cetBurnerProp + cbtStakerProp + primaryProp);
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
     * @dev CET Burner の分配率を取得.
     */
    function cetBurnerProportion()
        public
        view
        returns (uint32)
    {
        return uint32(shares(address(_cetBurnerShares)));
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

    function releaseCETBurnerShares(address account)
        public
    {
        if (pendingPaymentExists(address(_cetBurnerShares))) {
            release(address(_cetBurnerShares));
        }
        _cetBurnerShares.release(account);
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
     * @dev CETBurnerShares の取得
     */
    function _getCETBurnerShares()
        internal
        view
        virtual
        returns (CETBurnerShares)
    {
        return _cetBurnerShares;
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
