// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Абстрактный контракт для взаимодействия с токенами
 * @notice Основные функции для взаимодействия с токенами
 */
abstract contract IAssets {

    /**
    * @notice получает адрес контракта обеспечения
    * @dev используется для получения адреса контракта обеспечения
    * @return collateral возвращает адрес контракта обеспечения
    */
    function getCollateral() public virtual returns (address);
    
    /**
    * @notice получает адрес контракта условных токенов
    * @dev используется для получения адреса контракта условных токенов
    * @return collateral возвращает адрес контракта условных токенов
    */
    function getCtf() public virtual returns (address);
}