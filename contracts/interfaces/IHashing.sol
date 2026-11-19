// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Order } from "../libraries/OrderStructs.sol";

/**
 * @title Абстрактный контракт для хэширования и проверки подписи
 * @notice Основные функции для хэширования и проверки подписи
 */
abstract contract IHashing {
    
    /// @notice возникает, когда подпись некорректна
    error InvalidSignature();

    /**
    * @notice вычисляет хэш заказа
    * @param order заказ
    * @dev вычисляет хэш заказа
    * @return bytes32 возвращает хэш
    */
    function hashOrder(Order memory order) public view virtual returns (bytes32);

    /**
    * @notice проверяет заказ на соответствие подписи подписанту
    * @param orderHash хэш заказа
    * @param order заказ
    * @param signature подпись (генерируется на фронтенде)
    * @dev проверяет заказ на соответствие подписи подписанту. Генерирует ошибку, если провал
    */
    function validateOrderSignature(bytes32 orderHash, Order memory order, bytes memory signature) public pure virtual;

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
    ) public pure virtual returns (bool);
}