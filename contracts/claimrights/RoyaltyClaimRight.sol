// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IRoyaltyClaimRight } from "./IRoyaltyClaimRight.sol";

/**
 * @dev Abstract implementation of {IRoyaltyClaimRight}.
 *
 * 印税分配請求権を表すトークン。ERC20の印税分配比率を決める際は、本クラスを継承したトークンを作成する。
 * 分配比率は、mint, burn, transfer による保有量によって決定されるが、本クラスにはそれらの実装を持たない。
 * 比率の決め方は、Owner やガバナンスが決める場合や、ユーザの staking 量、X to Earn の貢献値で決めるなど、
 * 複数の方法が考えられる。mint, burn の内容や transfer の可否等が各ケースで異なるため、サブクラスで実装する。
 */
abstract contract RoyaltyClaimRight is IRoyaltyClaimRight, ERC20, ERC20Votes, ReentrancyGuard {
    using Address for address;

    mapping (IERC20 => uint[]) private _incomingBlockNumbers;
    mapping (address => mapping (IERC20 => uint32)) private _nextClaimIndexes;
    mapping (IERC20 => mapping (uint => uint256)) private _incomingAmounts;
    mapping (IERC20 => uint256) private _minIncomingAmount;
    mapping (IERC20 => bool) private _approvedToken;

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC20Permit(name)
    {
    }

    // #################################
    // ## Public functions            ##
    // #################################

    /// @inheritdoc IRoyaltyClaimRight
    function distribute(IERC20 token, uint256 amount)
        external
        override
    {
        require (_approvedToken[token], "RoyaltyClaimRight: not approved token");
        require (amount >= _minIncomingAmount[token], "RoyaltyClaimRight: less than min incoming amount");

        _incomingAmounts[token][block.number] += amount;

        uint[] storage blockNums = _incomingBlockNumbers[token];
        if (blockNums.length == 0 || blockNums[blockNums.length - 1] < block.number) {
            blockNums.push(block.number);
        }

        token.transferFrom(msg.sender, address(this), amount);

        emit Distribute(address(token), amount);
    }

    /// @inheritdoc IRoyaltyClaimRight
    function claimNext(address account, IERC20 token)
        public
        override
        nonReentrant
    {
        uint32 nextClaimIndex = _nextClaimIndexes[account][token];
        require (nextClaimIndex < _incomingBlockNumbers[token].length, "RoyaltyClaimRight: no more incoming amount exists");

        uint nextClaimBlockNumber = _incomingBlockNumbers[token][nextClaimIndex];
        require (nextClaimBlockNumber < block.number, "RoyaltyClaimRight: claim allowed under comfirmed blocks");

        uint256 incomingAmount = _incomingAmounts[token][nextClaimBlockNumber];

        uint256 share = getPastVotes(account, nextClaimBlockNumber);
        uint256 totalShare = getPastTotalSupply(nextClaimBlockNumber);

        _nextClaimIndexes[account][token]++;

        if (share == 0 || totalShare == 0) {
            // Nothing emitted if no share.
            // Note: If totalShare is zero but incomingAmount > 0, the royalties remains in the contract.
            return;
        }

        uint256 amount = incomingAmount * share / totalShare;

        if (amount == 0) {
            // Nothing emitted if no amount transferred.
            return;
        }

        token.approve(account, amount);

        if (account.isContract()) {
            try IRoyaltyClaimRight(account).distribute(token, amount) {
            } catch {
                token.transfer(account, amount);
            }
        } else {
            token.transfer(account, amount);
        }

        require (token.allowance(msg.sender, account) == 0, "RoyaltyClaimRight: can't claim enough amount");

        emit Claim(account, address(token), amount);
    }

    /// @inheritdoc IRoyaltyClaimRight
    function claimIterate(address account, IERC20 token, uint32 times)
        public
        override
    {
        uint32 nextIncomeIndex = _nextClaimIndexes[account][token];
        uint32 maxTimes = SafeCast.toUint32(_incomingBlockNumbers[token].length) - nextIncomeIndex;
        times = SafeCast.toUint32(Math.min(times, maxTimes));
        require (times > 0, "RoyaltyClaimRight: no more incoming amount exists");

        for (uint32 i = 0; i < times;) {
            claimNext(account, token);
            unchecked { i++; }
        }
    }

    /// @inheritdoc IRoyaltyClaimRight
    function claimAll(address account, IERC20 token)
        public
        override
    {
        claimIterate(account, token, type(uint32).max);
    }

    /// @inheritdoc IRoyaltyClaimRight
    function isApprovedToken(IERC20 token)
        external
        view
        override
        returns (bool)
    {
        return _approvedToken[token];
    }

    /// @inheritdoc IRoyaltyClaimRight
    function minIncomingAmount(IERC20 token)
        external
        view
        override
        returns (uint256)
    {
        return _minIncomingAmount[token];
    }

    // #################################
    // ## Internal functions          ##
    // #################################

    /**
     * @dev Approve the royalty provider to distribute `token`.
     *
     * Emits a {ApprovalForIncomingToken} event.
     */
    function _setApprovalForIncomingToken(IERC20 token, bool approved)
        internal
    {
        _approvedToken[token] = approved;
        emit ApprovalForIncomingToken(address(token), approved);
    }

    /**
     * @dev Approve the royalty provider to distribute `tokens`.
     *
     * Emits a {ApprovalForIncomingToken} event for each token.
     */
    function _approveForIncomingTokens(IERC20[] memory tokens)
        internal
    {
        for (uint32 i = 0; i < tokens.length;) {
            _setApprovalForIncomingToken(tokens[i], true);
            unchecked { i++; }
        }
    }

    /**
     * @dev Set the minimum incoming amount. This function is used for anti-spam.
     *
     * Emits a {MinIncomingAmount} event.
     */
    function _setMinIncomingAmount(IERC20 token, uint256 minAmount)
        internal
    {
        require (_approvedToken[token], "RoyaltyClaimRight: not approved token");
        _minIncomingAmount[token] = minAmount;
        emit MinIncomingAmount(address(token), minAmount);
    }

    // #################################
    // ## Override internal functions ##
    // #################################

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);

        if (from != address(0) && delegates(from) == address(0)) {
            _delegate(from, from);
        }
        if (to != address(0) && delegates(to) == address(0)) {
            _delegate(to, to);
        }
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        ERC20Votes._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        ERC20Votes._burn(account, amount);
    }
}
