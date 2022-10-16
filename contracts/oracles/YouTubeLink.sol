// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IOracle, Response } from "./IOracle.sol";
import { ICET } from "../tokens/ICET.sol";

/**
 * @dev Implementation of {IOracle} to calculate engagements from YouTube view counts.
 */
contract YouTubeLink is ChainlinkClient, IOracle, Ownable {
    using Chainlink for Chainlink.Request;

    mapping (ICET => mapping (address => string)) private _youtubeIds;
    mapping (ICET => mapping (address => Response)) private _responses;

    constructor(address _link)
    {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
    }

    function getChainlinkToken()
        public
        view
        returns (address)
    {
        return chainlinkTokenAddress();
    }

    /**
     * @dev Requests view counts by YouTubeId.
     */
    function createRequestTo(
        address oracle,
        bytes32 jobId,
        uint256 payment,
        ICET cet,
        address account
    )
        public
        onlyOwner
        returns (bytes32 requestId)
    {
        require (bytes(_youtubeIds[cet][account]).length > 0, "url is required");
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        req.add("youtubeId", _youtubeIds[cet][account]);
        requestId = sendChainlinkRequestTo(oracle, req, payment);
    }

    function fulfill(
        bytes32 requestId,
        ICET cet,
        address account,
        uint64 totalEngagement
    )
        public
        recordChainlinkFulfillment(requestId)
    {
        _responses[cet][account] = Response({
            totalEngagement: totalEngagement
        });
    }

    /**
     * @notice Allows the owner to withdraw any LINK balance on the contract
     */
    function withdrawLink()
        public
        onlyOwner
    {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function cancelRequest(
        bytes32 requestId,
        uint256 payment,
        bytes4 callbackFunctionId,
        uint256 expiration
    )
        public
        onlyOwner
    {
        cancelChainlinkRequest(
            requestId,
            payment,
            callbackFunctionId,
            expiration
        );
    }

    /// @inheritdoc IOracle
    function setId(ICET cet, address account, string memory id_)
        external
        override
        onlyOwner
    {
        _youtubeIds[cet][account] = id_;
    }

    /// @inheritdoc IOracle
    function id(ICET cet, address account)
        external
        view
        override
        returns (string memory)
    {
        return _youtubeIds[cet][account];
    }

    /// @inheritdoc IOracle
    function responses(ICET cet, address account)
        external
        view
        override
        returns (Response memory)
    {
        return _responses[cet][account];
    }
}
