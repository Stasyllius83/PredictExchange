// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Order, ORDER_TYPEHASH } from "../contracts/libraries/OrderStructs.sol";
import { IHashing } from "../contracts/interfaces/IHashing.sol";

abstract contract Hashing is EIP712, IHashing {

    bytes32 public immutable domainSeparator;

    constructor(string memory name, string memory version) EIP712(name, version) {
        domainSeparator = _domainSeparatorV4();
    }

    function hashOrder(Order memory order) public view override returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.salt,
                    order.signer,
                    order.tokenId,
                    order.amount,
                    order.expiration,
                    order.nonce,
                    order.side,
                    order.bid
                )
            )
        );
    }

    function validateOrderSignature(
        bytes32 orderHash,
        Order memory order,
        bytes memory signature
        ) public pure override {
        if(!isValidSignature(order.signer, orderHash, signature)) {
            revert InvalidSignature();
        }
    }

    function isValidSignature(
        address signer,
        bytes32 structHash,
        bytes memory signature
    ) public pure override returns (bool) {
        return ECDSA.recover(structHash, signature) == signer;
    }
}
