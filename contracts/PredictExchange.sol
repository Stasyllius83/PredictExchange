// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../contracts/libraries/OrderStructs.sol";
import { Auth } from "../contracts/Auth.sol";
import { Assets } from "../contracts/Assets.sol";
import { AssetFunctions } from "../contracts/AssetFunctions.sol";
import { Hashing } from "../contracts/Hashing.sol";
import { Nonce } from "../contracts/Nonce.sol";
import { Exchange } from "../contracts/Exchange.sol";
import { ReentrancyGuard } from "../contracts/libraries/ReentrancyGuard.sol";
import { Base, ERC1155 } from "../contracts/Base.sol";


/**
 * @title Биржа предсказаний
 * @author Станислав
 * @notice Основные функции для проведения ставок
 */
contract PredictExchange is
    Base,
    Auth,
    Assets,
    AssetFunctions,
    Hashing("Predict Exchange", "1"),
    Nonce,
    Exchange
    {
        /**
        * @notice конструктор контракта
        * @param _collateral адрес контракта обеспечения
        * @param _ctf адрес контракта условных токенов
        * @dev инициализирует контракт
        */
        constructor(address _collateral, address _ctf)
            Assets(_collateral, _ctf)
            ERC1155("")
            {}

        /**
        * @notice создает предсказание
        * @param _condition условие спора
        * @param _oracle адрес оракула
        * @param _predictedPrice значение предсказываемой цены
        * @param _duration продолжительность спора
        * @dev создает предсказание (только администратор)
        */
        function createPrediction(string memory _condition, address _oracle, uint256 _predictedPrice, uint256 _duration) external onlyAdmin {
            _createPrediction(_condition, _oracle, _predictedPrice, _duration);
        }

        /**
        * @notice разрешает предсказание
        * @param _questionId идентификатор вопроса предсказания
        * @dev разрешает предсказание (только администратор)
        */
        function resolvePrediction(bytes32 _questionId) external onlyAdmin {
            _resolvePrediction(_questionId);
        }

        /**
        * @notice получает награду разрешенного предсказания
        * @param _questionId идентификатор вопроса предсказания
        * @dev получает награду разрешенного предсказания (для всех участвовавших пользователей)
        */
        function claimWinnings(bytes32 _questionId) external nonReentrant {
            _claimWinnings(_questionId);
        }

        /**
        * @notice просмотр всех вопросов предсказаний в виде массива
        * @dev в дальнейшем используется для получения идентификатора выбранного вопроса
        * @return allQuestions возвращает массив всех вопросов
        */
        function getAllQuestions() public view returns (string[] memory) {
            return allQuestions;
        }

        /**
        * @notice получает идентификатор вопроса предсказания
        * @param question вопрос спора в виде строки
        * @dev получает идентификатор вопроса предсказания с типом bytes32
        * @return возвращает идентификатор
        */
        function getQuestionId(string memory question) public pure returns (bytes32){
            return stringToBytes32(question);
        }

        /**
        * @notice создает заявку на предсказание
        * @param _questionId идентификатор вопроса
        * @param _salt произвольное значение
        * @param _side направление покупка/продажа
        * @param _bid значение ставки
        * @param _fillamount сумма на которую ставят
        * @param _expiration продолжительность заявки
        * @param _signature подпись
        * @dev создает заявку на предсказание. Подпись формируется на фронтенде
        */
        function fillOrder(bytes32 _questionId, uint256 _salt, Side _side, Bid _bid, uint256 _fillamount, uint256 _expiration, bytes memory _signature) external nonReentrant {
            _fillOrder(_questionId, _salt, _side, _bid, _fillamount, _expiration, _signature);
        }

        /**
        * @notice получает информацию об предсказании
        * @param _questionId идентификатор вопроса предсказания
        * @dev получает информацию об ранее созданном предсказании из storage
        * @return возвращает предсказание Prediction
        */
        function getPredictionById(bytes32 _questionId) view external returns (Prediction memory) {
            return predictions[_questionId];
        }

        /**
        * @notice получает информацию о цене "да"
        * @param _questionId идентификатор вопроса предсказания
        * @dev получает информацию о цене "да" для фронтенда
        * @return возвращает цену
        */
        function getYesPrice(bytes32 _questionId) external view returns (uint256) {
            return predictions[_questionId].yesPrice;
        }

        /**
        * @notice получает информацию о цене "нет"
        * @param _questionId идентификатор вопроса предсказания
        * @dev получает информацию о цене "нет" для фронтенда
        * @return возвращает цену
        */
        function getNoPrice(bytes32 _questionId) external view returns (uint256) {
            return predictions[_questionId].noPrice;
        }
}
