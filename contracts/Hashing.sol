// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.5.0/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.5.0/contracts/utils/cryptography/ECDSA.sol";
import { Order, ORDER_TYPEHASH } from "../contracts/libraries/OrderStructs.sol";
import { IHashing } from "../contracts/interfaces/IHashing.sol";

/**
 * @title Абстрактный контракт для хэширования и проверки подписи
 * @notice Основные функции для хэширования и проверки подписи
 */
abstract contract Hashing is EIP712, IHashing {

    /// @notice переменная для значения domainSeparator
    bytes32 public immutable domainSeparator;

    /**
    * @notice конструктор контракта
    * @dev инициализирует контракт значением domainSeparator
    */
    constructor(string memory name, string memory version) EIP712(name, version) {
        domainSeparator = _domainSeparatorV4();
    }

    /**
    * @notice вычисляет хэш заказа
    * @param order заказ
    * @dev вычисляет хэш заказа
    * @return bytes32 возвращает хэш
    */
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

    /**
    * @notice проверяет заказ на соответствие подписи подписанту
    * @param orderHash хэш заказа
    * @param order заказ
    * @param signature подпись (генерируется на фронтенде)
    * @dev проверяет заказ на соответствие подписи подписанту. Генерирует ошибку, если провал
    */
    function validateOrderSignature(
        bytes32 orderHash,
        Order memory order,
        bytes memory signature
        ) public pure override {
        if(!isValidSignature(order.signer, orderHash, signature)) {
            revert InvalidSignature();
        }
    }

    /**
    * @notice проверяет корректность подписи
    * @param signer подписант заказа
    * @param structHash хэш заказа
    * @param signature подпись (генерируется на фронтенде)
    * @dev проверяет корректность подписи. Адрес подписанта восстанавливается из хэша
    * @return bool возвращает ложь/истина
    */
    function isValidSignature(
        address signer,
        bytes32 structHash,
        bytes memory signature
    ) public pure override returns (bool) {
        return ECDSA.recover(structHash, signature) == signer;
    }
}
