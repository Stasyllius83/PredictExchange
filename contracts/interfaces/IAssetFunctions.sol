// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Абстрактный контракт для взаимодействия с токенами
 * @notice Основные функции для взаимодействия с токенами
 */
abstract contract IAssetFunctions {

    /**
    * @notice получает баланс токенов на контракте
    * @param tokenId Идентификатор токена
    * @dev получает баланс токенов на контракте
    * @return возвращает значение баланса
    */
    function _getBalance(uint256 tokenId) internal virtual returns (uint256);

    /**
    * @notice получает баланс ERC1155 токенов пользователя
    * @param tokenId Идентификатор токена
    * @dev получает баланс токенов на контракте
    * @return возвращает значение баланса
    */
    function _getBalanceCTF(address holder, uint256 tokenId) internal virtual returns (uint256);

    /**
    * @notice переводит токены
    * @param from адрес отправителя
    * @param to адрес получателя
    * @param id идентификатор токена
    * @param value значение которое спишется с баланса отправителя
    * @dev переводит токены (0 для ERC20)
    */
    function _transfer(address from, address to, uint256 id, uint256 value) internal virtual;

    /**
    * @notice чеканит токены
    * @param to адрес получателя
    * @param conditionId идентификатор условия
    * @param indexSet значение из возможных вариантов ставки
    * @param amount значение которое будет на баланса
    * @dev чеканит токены (только для вариантов "ДА" или "НЕТ")
    */
    function _mint(address to, bytes32 conditionId, uint8 indexSet, uint256 amount) internal virtual;

    /**
    * @notice сжигает токены
    * @param to адрес владельца
    * @param conditionId идентификатор условия
    * @param indexSet значение из возможных вариантов ставки
    * @param amount значение которое спишется с баланса отправителя
    * @dev сжигает токены (только для вариантов "ДА" или "НЕТ")
    */
    function _burn(address to, bytes32 conditionId, uint8 indexSet, uint256 amount) internal virtual;
}
