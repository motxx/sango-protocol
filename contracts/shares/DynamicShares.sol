// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ISharesReceiver } from "./ISharesReceiver.sol";

/**
 * @dev ERC20 のトークンを指定の比率に従って各ウォレットやコントラクトに配分するクラス
 * OpenZeppelin の PaymentSplitter を動的に payees, shares を変更可能としたもの
 * 使用する ERC20 は transfer 時に onERC20SharesReceived を呼び出す必要がある
 */
abstract contract DynamicShares is ISharesReceiver, Context, IERC165 {
    event ResetPayees();
    event AddPayee(address payee, uint256 share);
    event UpdatePayee(address payee, uint256 share);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 internal _totalShares;

    mapping(address => uint256) private _totalReceived;
    mapping(address => uint256) private _alreadyReleased;

    address[] internal _payees;
    mapping(address => uint256) private _shares;
    mapping(address => bool) private _isPayee;

    IERC20 private _token;

    uint32 immutable private _maxPayees;

    constructor(IERC20 token, uint32 maxPayees)
    {
        _token = token;
        _maxPayees = maxPayees;
    }

    /**
     * @dev Initialize payees and shares in the contract.
     * @param payees The addresses of the payee to add.
     * @param shares_ The shares owned by the payees.
     */
    function _initPayees(address[] calldata payees, uint256[] calldata shares_)
        internal
    {
        require(payees.length == shares_.length, "DynamicShares: mismatch length");
        require(payees.length <= _maxPayees, "DynamicShares: over than _maxPayees");

        _resetPayees();

        for (uint32 i = 0; i < payees.length;) {
            _addPayee(payees[i], shares_[i]);
            unchecked { i++; }
        }
    }

    /**
     * @dev Reset payees and shares in the contract.
     */
    function _resetPayees()
        internal
    {
        _totalShares = 0;
        for (uint32 i = 0; i < _payees.length;) {
            _isPayee[_payees[i]] = false;
            _shares[_payees[i]] = 0;
            unchecked { i++; }
        }
        delete _payees;

        emit ResetPayees();
    }

    /**
     * @dev Add a payee and share in the contract.
     * @param payee The address of the payee to add.
     * @param share The share owned by the payee.
     */
    function _addPayee(address payee, uint256 share)
        internal
    {
        require(!_isPayee[payee], "DynamicShares: the payee already exists");

        _isPayee[payee] = true;
        _payees.push(payee);
        _shares[payee] = share;
        _totalShares += share;

        emit AddPayee(payee, share);
    }

    function _updatePayee(address payee, uint256 share)
        internal
    {
        require(_isPayee[payee], "DynamicShares: payee doesn't exist");
        _shares[payee] = share;
        emit UpdatePayee(payee, share);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     * release 対象の account に自身を指定するはことはできない. なお Treasury 用途で自身の addPayee() は可.
     */
    function release(address account)
        public
    {
        require(account != address(this), "DynamicShares: self payment loop");
        uint256 payment = _totalReceived[account] - _alreadyReleased[account];
        require(payment > 0, "DynamicShares: account is not due payment");
        _alreadyReleased[account] += payment;

        _token.transfer(account, payment);
        emit ERC20PaymentReleased(_token, account, payment);
    }

    /**
     * @dev Withdraw ERC20 token.
     */
    function withdraw()
        external
    {
        this.release(_msgSender());
    }

    /**
     * @dev Check pending payments exists for specified account.
     */
    function pendingPaymentExists(address account)
        public
        view
        returns (bool)
    {
        require(account != address(this), "DynamicShares: self payment loop");
        uint256 payment = _totalReceived[account] - _alreadyReleased[account];
        return payment > 0;
    }


    /**
     * @dev ERC20のトークンを受け取った際の分配.
     * 分配対象が未設定の場合、revertされる.
     * (mintやreleaseによる、ERC20のtransferが失敗する.)
     */
    function onERC20SharesReceived(uint256 amount)
        external
        override
    {
        require(msg.sender == address(_token), "DynamicShares: must be called by pre-registered ERC20 token");
        require(_payees.length > 0, "DynamicShares: no payees");
        require(_token.balanceOf(address(this)) >= amount, "DynamicShares: too much amount");

        uint256 sumShares = 0;
        for (uint32 i = 0; i < _payees.length;) {
            uint256 aShare = amount * _shares[_payees[i]] / _totalShares;
            _totalReceived[_payees[i]] += aShare;
            sumShares += aShare;
            unchecked { i++; }
        }

        require(amount >= sumShares, "DynamicShares: (BUG) invalid shares");
        _totalReceived[_payees[0]] += amount - sumShares; // 最初の人が余剰分を受け取る.
    }

    /**
     * @dev ERC165 の機能. ERC20 で transfer の to が本コントラクトかを判定するために用いる.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        virtual
        view
        override
        returns (bool)
    {
        return interfaceId == type(ISharesReceiver).interfaceId;
    }

    /**
     * @dev アカウントが受領したトークンの総量
     * @param account The address of the account.
     */
    function totalReceived(address account)
        public
        view
        returns (uint256)
    {
        return _totalReceived[account];
    }

    /**
     * @dev アカウントに放出されたトークンの総量
     * @param account The address of the account.
     */
    function alreadyReleased(address account)
        public
        view
        returns (uint256)
    {
        return _alreadyReleased[account];
    }

    /**
     * @dev アカウントの現在の分配を取得
     * @param account The address of the account.
     */
    function shares(address account)
        public
        view
        returns (uint256)
    {
        return _shares[account];
    }

    /**
     * @dev 現在の分配を受けるアカウント一覧を取得
     */
    function allPayees()
        public
        view
        returns (address[] memory)
    {
        return _payees;
    }

    /**
     * @dev アカウントが分配の受領者として登録済みかの確認
     */
    function isPayee(address account)
        public
        virtual
        view
        returns (bool)
    {
        return _isPayee[account];
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
}
