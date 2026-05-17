// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { INonce } from "../contracts/interfaces/INonce.sol";

abstract contract Nonce is INonce {
    mapping(address => uint256) public nonces;

    function incrementNonce() internal override {
        updateNonce(1);
    }

    function updateNonce(uint256 val) internal {
        nonces[ msg.sender] = nonces[ msg.sender] + val;
    }

    function isValidNonce(address usr, uint256 nonce) public view override returns (bool) {
        return nonces[ usr] == nonce;
    }
}