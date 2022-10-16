// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICET } from "../tokens/ICET.sol";

/**
 * @dev Oracle response for calculate SNS engagements.
 */
struct Response {
    uint64 totalEngagement;
}

/**
 * @dev Interface of SNS oracle implementations.
 */
interface IOracle {
    function setId(ICET cet, address account, string memory id_) external;
    function id(ICET cet, address account) external view returns (string memory);
    function responses(ICET cet, address account) external view returns (Response memory);
}
