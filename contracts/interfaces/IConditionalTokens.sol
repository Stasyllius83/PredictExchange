// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../tokens/IERC20.sol";

/**
 * @title Интерфейс для условных токенов
 * @notice Основные функции генерации ИД условий, позиции, минтинга и сжигания токенов
 */
interface IConditionalTokens {

    /**
    * @notice получает идентификатор условия для условных токенов
    * @param oracle адрес оракула
    * @param questionId идентификатор вопроса
    * @dev получает идентификатор условия
    * return возвращает значение идентификатора
    */
    function getConditionId(address oracle, bytes32 questionId) external pure returns (bytes32);

    /**
    * @notice получает идентификатор позиции для условных токенов
    * @param collateralToken адрес токена обеспечения
    * @param conditionId идентификатор условия
    * @param indexSet позиция выбора/ставки
    * @dev получает идентификатор позиции
    * return возвращает значение идентификатора позиции
    */
    function getPositionId(IERC20 collateralToken, bytes32 conditionId, uint8 indexSet) external pure returns (uint);

    /**
    * @notice чеканит условные токены
    * @param collateralToken адрес токена обеспечения
    * @param conditionId идентификатор условия
    * @param indexSet значение выбора/ставки
    * @dev чеканит токены (только для вариантов "ДА" или "НЕТ")
    */
    function mintCTF(IERC20 collateralToken, address to, bytes32 conditionId, uint8 indexSet, uint256 amount, bytes memory data) external;

    /**
    * @notice сжигает условные токены
    * @param collateralToken адрес токена обеспечения
    * @param conditionId идентификатор условия
    * @param indexSet значение выбора/ставки
    * @dev сжигает токены (только для вариантов "ДА" или "НЕТ")
    */
    function burnCTF(IERC20 collateralToken, address to, bytes32 conditionId, uint8 indexSet, uint256 amount) external;
}
