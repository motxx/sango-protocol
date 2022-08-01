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
contract RoyaltyProportions is DynamicShares {
    CreatorShares private _creatorShares;
    CETHolderShares private _cetHolderShares;
    CBTStakerShares private _cbtStakerShares;
    PrimaryShares private _primaryShares;

    // Creators, CET Holders, CBTStakers, Primaries, Treasury
    uint32 constant public MAX_PAYEES = 5;

    constructor()
        DynamicShares(MAX_PAYEES)
    {
        _creatorShares = new CreatorShares();
        _cetHolderShares = new CETHolderShares();
        _cbtStakerShares = new CBTStakerShares();
        _primaryShares = new PrimaryShares();
    }

    /**
     * @notice ロイヤリティの分配率(ベーシスポイント)を設定する. 分配率の再設定は常に可能.
     *
     * ロイヤリティの入手方法により分配が変化する
     * 1) 直接 Royalty Provider から transfer された場合
     *    この場合は、Creator / CET Holder / CBT Staker / Primaries に対して設定した比率で分配される
     *    余剰分は Treasury として SangoContent に残る.
     *
     * 2) TODO: Primary より CET Holder として分配された場合
     *    この場合は、Primaries を除いた Creator / CET Holder / CBT Staker に対して設定した比率が拡張され分配される
     */
    function setRoyaltyProportions(
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
            "RoyaltyProportions: sum proportions <= 10000");

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
     * @notice ERC20トークンを分配で使用可能にする.
     */
    function approveToken(IERC20 token)
        public
        /* onlyGovernance */
    {
        _approveToken(token);
        _creatorShares.approveToken(token);
        _cetHolderShares.approveToken(token);
        _cbtStakerShares.approveToken(token);
        _primaryShares.approveToken(token);
    }

    /**
     * @notice ERC20トークンを分配で使用不可にする.
     */
    function disapproveToken(IERC20 token)
        public
        /* onlyGovernance */
    {
        _disapproveToken(token);
        _creatorShares.disapproveToken(token);
        _cetHolderShares.disapproveToken(token);
        _cbtStakerShares.disapproveToken(token);
        _primaryShares.disapproveToken(token);
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

    function releaseCreatorShares(IERC20 token, address account)
        public
    {
        if (pendingPaymentExists(token, address(_creatorShares))) {
            release(token, address(_creatorShares));
        }
        _creatorShares.release(token, account);
    }

    function releaseCETHolderShares(IERC20 token, address account)
        public
    {
        if (pendingPaymentExists(token, address(_cetHolderShares))) {
            release(token, address(_cetHolderShares));
        }
        _cetHolderShares.release(token, account);
    }

    function releaseCBTStakerShares(IERC20 token, address account)
        public
    {
        if (pendingPaymentExists(token, address(_cbtStakerShares))) {
            release(token, address(_cbtStakerShares));
        }
        _cbtStakerShares.release(token, account);
    }

    function releasePrimaryShares(IERC20 token, address account)
        public
    {
        if (pendingPaymentExists(token, address(_primaryShares))) {
            release(token, address(_primaryShares));
        }
        _primaryShares.release(token, account);
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
