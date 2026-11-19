// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { INonce } from "../contracts/interfaces/INonce.sol";

/**
 * @title Абстрактный контракт для работы с nonce
 * @notice Основные функции для обновления и проверки nonce
 */
abstract contract Nonce is INonce {

    /**
    * @notice хранилище nonce
    * @dev подтверждает, что пользователь с данным адресом имеет данный nonce
    * @notice ключ — адрес пользователя, значение — nonce
    */
    mapping(address => uint256) public nonces;

    /**
    * @notice увеличивает nonce на 1
    * @dev увеличивает nonce на 1
    */
    function incrementNonce() internal override {
        updateNonce(1);
    }

    /**
    * @notice обновляет nonce
    * @param val заказ
    * @dev обновляет nonce отправителем
    */
    function updateNonce(uint256 val) internal {
        nonces[ msg.sender] = nonces[ msg.sender] + val;
    }

    /**
    * @notice проверяет что nonce пользователя соответствует данной транзакции
    * @param user пользователь   
    * @param userNonce nonce
    * @dev проверяет что nonce пользователя соответствует данной транзакции
    * @return bool возвращает ложь/истина
    */
    function isValidNonce(address user, uint256 userNonce) public view override returns (bool) {
        return nonces[ user] == userNonce;
    }
}