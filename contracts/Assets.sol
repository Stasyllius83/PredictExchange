// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../contracts/tokens/IERC20.sol";
import { IAssets } from "../contracts/interfaces/IAssets.sol";

/**
 * @title Абстрактный контракт для взаимодействия с токенами
 * @notice Основные функции для взаимодействия с токенами
 */
abstract contract Assets is IAssets {

    /// @notice переменная для адреса контракта обеспечения
    address internal immutable collateral;
    /// @notice переменная для адреса контракта условных токенов
    address internal immutable ctf;

    /**
    * @notice конструктор контракта
    * @param _collateral адрес контракта обеспечения
    * @param _ctf адрес контракта условных токенов
    * @dev инициализирует контракт
    */
    constructor(address _collateral, address _ctf) {
        collateral = _collateral;
        ctf = _ctf;
        IERC20(collateral).approve(ctf, type(uint256).max);
    }

    /**
    * @notice получает адрес контракта обеспечения
    * @dev используется для получения адреса контракта обеспечения
    * @return collateral возвращает адрес контракта обеспечения
    */
    function getCollateral() public view override returns (address) {
        return collateral;
    }
    
    /**
    * @notice получает адрес контракта условных токенов
    * @dev используется для получения адреса контракта условных токенов
    * @return collateral возвращает адрес контракта условных токенов
    */
    function getCtf() public view override returns (address) {
        return ctf;
    }
}