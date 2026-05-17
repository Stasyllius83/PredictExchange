// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Order } from "../libraries/OrderStructs.sol";

abstract contract IHashing {
    error InvalidSignature();

    function hashOrder(Order memory order) public view virtual returns (bytes32);

    function validateOrderSignature(bytes32 orderHash, Order memory order, bytes memory signature) public pure virtual;

    function isValidSignature(
        address signer,
        bytes32 structHash,
        bytes memory signature
    ) public pure virtual returns (bool);
}