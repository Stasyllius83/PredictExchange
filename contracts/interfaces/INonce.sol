// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/**
 * @title Абстрактный контракт для работы с nonce
 * @notice Основные функции для обновления и проверки nonce
 */
abstract contract INonce {
    
    /**
    * @notice увеличивает nonce на 1
    * @dev увеличивает nonce на 1
    */
    function incrementNonce() internal virtual;

    /**
    * @notice проверяет что nonce пользователя соответствует данной транзакции
    * @param user пользователь   
    * @param userNonce nonce
    * @dev проверяет что nonce пользователя соответствует данной транзакции
    * @return bool возвращает ложь/истина
    */
    function isValidNonce(address user, uint256 userNonce) public view virtual returns (bool);
}