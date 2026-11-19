// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Order } from "../libraries/OrderStructs.sol";

/**
 * @title Абстрактный контракт для сопоставления заказов и работе с предсказаниями
 * @notice Основные функции для сопоставления заказов и работе с предсказаниями
 */
abstract contract IExchange {

    /// @notice структура предсказания
    struct Prediction {
        /// @notice условие спора предсказания
        string condition;
        /// @notice идентификатор условия 
        bytes32 conditionId;
        /// @notice адрес оракула
        address oracle;
        /// @notice время подведения итогов
        uint256 endsAt;
        /// @notice цена "да"
        uint256 yesPrice;
        /// @notice цена "нет"
        uint256 noPrice;
        /// @notice сумма всех заказов "да"
        uint256 sumYes;
        /// @notice сумма всех заказов "нет"
        uint256 sumNo;
        /// @notice комиссия в заказе "да"
        uint256 feeYes;
        /// @notice комиссия в заказе "нет"
        uint256 feeNo;
        /// @notice предсказанная цена
        uint256 predictedPrice;
        /// @notice счетчик взаимнодополняемых заказов
        uint256 matchesCounter;
        /// @notice массив заказов
        Order[] orders;
    }

    /**
    * @notice вызывается при создании нового предсказания
    * @dev новое предсказания создается только администратором
    * @param conditionId идентификатор условия
    * @param condition условие спора предсказания
    * @param oracle адрес оракула
    * @param endsAt время подведения итогов
    */
    event PredictionCreate(
        bytes32 indexed conditionId,
        string indexed condition,
        address indexed oracle,
        uint256 endsAt
    );

    /**
    * @notice вызывается при успешном создании нового заказа
    * @dev значение передается в wei USDC
    * @param user адрес создателя заказа
    * @param userAssetId идентификатор токена создающего заказ
    * @param userAmountFilled значение средств в заказе
    * @param orderHash хэш заказа
    */
    event OrderFilled(
        address indexed user,
        uint256 userAssetId,
        uint256 userAmountFilled,
        bytes32 indexed orderHash
    );

    /**
    * @notice вызывается при успешном сопоставлении заказов
    * @dev вызывается при успешном сопоставлении заказов
    * @param takerOrderMaker адрес создателя заказа
    * @param makerAssetId идентификатор токена создающего заказ
    * @param takerAssetId идентификатор токена взаимнодополняемого с заказом
    * @param makerAmountFilled значение средств зарезервированные при создании заказа
    * @param takerAmountFilled значение средств сопоставленные с заказом
    */
    event OrdersMatched(
        address indexed takerOrderMaker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled
    );

    /**
    * @notice вызывается при изменении комиссии
    * @dev вызывается при изменении комиссии
    * @param payer адрес платильщика
    * @param tokenId идентификатор токена
    * @param fee значение комиссии
    */
    event FeeCharged(
        address indexed payer,
        uint256 tokenId, 
        uint256 fee
    );

    /**
    * @notice вызывается при разрешении спора
    * @dev вызывается при разрешении спора
    * @param questionId идентификатор вопроса
    * @param outcome значение исхода спора
    * @param winningTokenAmount значение выигрыша
    */
    event PredictionResolved(
        bytes32 indexed questionId,
        bool indexed outcome,
        uint256 winningTokenAmount
    );

     /**
    * @notice вызывается при получении выигрыша участником
    * @dev вызывается при получении выигрыша участником
    * @param user адрес участника
    * @param questionId идентификатор вопроса
    * @param amount значение выигрыша
    * @param outcome значение исхода
    */   
    event WinningsClaimed(
        address indexed user,
        bytes32 indexed questionId,
        uint256 amount,
        bool outcome
    );

    /**
    * @notice создает новое предсказание
    * @param _question вопрос предсказания
    * @param _oracle адрес оракула
    * @param _predictedPrice предсказуемая цена
    * @param _duration продолжительность спора
    * @dev создает предсказание (только администратор)
    */
    function _createPrediction(string memory _question, address _oracle, uint256 _predictedPrice, uint256 _duration) internal virtual;

    /**
    * @notice разрешает спор
    * @param _questionId идентификатор вопроса предсказания
    * @dev разрешает спор (только администратор)
    */
    function _resolvePrediction(bytes32 _questionId) internal virtual;
 
    /**
    * @notice получение выигрыша участником
    * @param _questionId идентификатор вопроса предсказания
    * @dev получение выигрыша участником
    */   
    function _claimWinnings(bytes32 _questionId) internal virtual;
}