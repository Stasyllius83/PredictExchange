// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../tokens/IERC20.sol";
import {ERC1155} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.5.0/contracts/token/ERC1155/ERC1155.sol";
import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";

/**
 * @title Контракт условных токенов
 * @author Станислав
 * @notice Основные функции генерации идентификатора условий, позиции, минтинга и сжигания токенов
 */
contract ConditionalTokens is IConditionalTokens, ERC1155 {

    /**
    * @notice конструктор контракта
    * @dev наследует контракт ERC1155
    */
    constructor() ERC1155("") {}

    /**
    * @notice получает идентификатор условия для условных токенов
    * @param oracle адрес оракула
    * @param questionId идентификатор вопроса
    * @dev получает идентификатор условия
    * @return возвращает значение идентификатора
    */
    function getConditionId(address oracle, bytes32 questionId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(oracle, questionId));
    }

    /**
    * @notice получает идентификатор позиции для условных токенов
    * @param collateralToken адрес токена обеспечения
    * @param conditionId идентификатор условия
    * @param bid позиция выбора/ставки
    * @dev получает идентификатор позиции
    * @return возвращает значение идентификатора позиции
    */
    function getPositionId(IERC20 collateralToken, bytes32 conditionId, uint8 bid) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(collateralToken, conditionId, bid)));
    }

    /**
    * @notice чеканит условные токены CTF
    * @param collateralToken адрес токена обеспечения
    * @param to адрес получателя
    * @param conditionId идентификатор условия
    * @param indexSet значение выбора/ставки
    * @dev чеканит токены (только для вариантов "ДА" или "НЕТ")
    */
    function mintCTF(IERC20 collateralToken, address to, bytes32 conditionId, uint8 indexSet, uint256 amount, bytes memory data) public {
                _mint(
                    to,
                    getPositionId(collateralToken, conditionId, indexSet),
                    amount,
                    data
                );
    }

    /**
    * @notice сжигает условные токены CTF
    * @param collateralToken адрес токена обеспечения
    * @param to адрес владельца
    * @param conditionId идентификатор условия
    * @param indexSet значение выбора/ставки
    * @dev сжигает токены (только для вариантов "ДА" или "НЕТ")
    */
    function burnCTF(IERC20 collateralToken, address to, bytes32 conditionId, uint8 indexSet, uint256 amount) public {
                _burn(
                    to,
                    getPositionId(collateralToken, conditionId, indexSet),
                    amount
                );
    }

}
