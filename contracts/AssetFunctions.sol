// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../contracts/tokens/IERC20.sol";
import {IERC1155} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.5.0/contracts/token/ERC1155/IERC1155.sol";
import { SafeTransferLib, ERC20 } from "../contracts/libraries/SafeTransferLib.sol";
import { IAssets } from "../contracts/interfaces/IAssets.sol";
import { IAssetFunctions } from "../contracts/interfaces/IAssetFunctions.sol";
import { IConditionalTokens } from "../contracts/interfaces/IConditionalTokens.sol";

/**
 * @title Абстрактный контракт для взаимодействия с токенами
 * @notice Основные функции для взаимодействия с токенами
 */
abstract contract AssetFunctions is IAssets, IAssetFunctions, IERC1155 {

    /**
    * @notice получает баланс токенов на контракте
    * @param tokenId идентификатор токена
    * @dev получает баланс токенов на контракте
    * @return возвращает значение баланса
    */
    function _getBalance(uint256 tokenId) internal override returns (uint256) {
        if (tokenId == 0) return IERC20(getCollateral()).balanceOf(address(this));
        return IERC1155(getCtf()).balanceOf(address(this), tokenId);
    }

    /**
    * @notice получает баланс ERC1155 токенов пользователя
    * @param tokenId идентификатор токена
    * @dev получает баланс токенов на контракте
    * @return возвращает значение баланса
    */
    function _getBalanceCTF(address holder, uint256 tokenId) internal override returns (uint256) {
        return IERC1155(getCtf()).balanceOf(holder, tokenId);
    }

    /**
    * @notice переводит токены
    * @param from адрес отправителя
    * @param to адрес получателя
    * @param id идентификатор токена
    * @param value значение которое спишется с баланса отправителя
    * @dev переводит токены (0 для ERC20)
    */
    function _transfer(address from, address to, uint256 id, uint256 value) internal override {
        if (id == 0) return _transferCollateral(from, to, value);
        return _transferCTF(from, to, id, value);
    }

    /**
    * @notice переводит токены обеспечения
    * @param from адрес отправителя
    * @param to адрес получателя
    * @param value значение которое спишется с баланса отправителя
    * @dev переводит токены ERC20
    */
    function _transferCollateral(address from, address to, uint256 value) internal {
        address token = getCollateral();
        if (from == address(this)) SafeTransferLib.safeTransfer(ERC20(token), to, value);
        else SafeTransferLib.safeTransferFrom(ERC20(token), from, to, value);
    }

    /**
    * @notice переводит условные токены
    * @param from адрес отправителя
    * @param to адрес получателя
    * @param value значение которое спишется с баланса отправителя
    * @dev переводит токены ERC1155
    */
    function _transferCTF(address from, address to, uint256 id, uint256 value) internal {
        IERC1155(getCtf()).safeTransferFrom(from, to, id, value, "");
    }

    /**
    * @notice чеканит токены
    * @param to адрес получателя
    * @param conditionId идентификатор условия
    * @param indexSet значение из возможных вариантов ставки
    * @param amount значение которое будет на баланса
    * @dev чеканит токены (только для вариантов "ДА" или "НЕТ")
    */
    function _mint(address to, bytes32 conditionId, uint8 indexSet, uint256 amount) internal override {
        IConditionalTokens(getCtf()).mintCTF(IERC20(getCollateral()), to, conditionId, indexSet, amount, "");
    }

    /**
    * @notice сжигает токены
    * @param to адрес владельца
    * @param conditionId идентификатор условия
    * @param indexSet значение из возможных вариантов ставки
    * @param amount значение которое спишется с баланса отправителя
    * @dev сжигает токены (только для вариантов "ДА" или "НЕТ")
    */
    function _burn(address to, bytes32 conditionId, uint8 indexSet, uint256 amount) internal override {
        IConditionalTokens(getCtf()).burnCTF(IERC20(getCollateral()), to, conditionId, indexSet, amount);
    }
}
