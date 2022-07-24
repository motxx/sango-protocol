// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { ICET } from "../tokens/ICET.sol";

struct Response {
    uint64 totalEngagement; // 再生回数など
}

interface IOracle {
    function setId(ICET cet, address account, string memory id_) external;
    function id(ICET cet, address account) external view returns (string memory);
    function responses(ICET cet, address account) external view returns (Response memory);
}
