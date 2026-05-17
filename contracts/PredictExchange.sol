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



contract PredictExchange is 
    Base,
    Auth, 
    Assets, 
    AssetFunctions, 
    Hashing("Predict Exchange", "1"), 
    Nonce,
    Exchange
    {
        constructor(address _collateral, address _ctf)
            Assets(_collateral, _ctf)
            ERC1155("")
            {}

        function createPrediction(string memory _condition, address _oracle, uint256 _predictedPrice, uint256 _duration) external onlyAdmin {
            _createPrediction(_condition, _oracle, _predictedPrice, _duration);
        }

        function resolvePrediction(bytes32 _questionId) external onlyAdmin {
            _resolvePrediction(_questionId);
        }

        function claimWinnings(bytes32 _questionId) external nonReentrant {
            _claimWinnings(_questionId);
        }

        // Просмотр всех вопросов для предсказаний в виде массива
        function getAllQuestions() public view returns (string[] memory) {
            return allQuestions;
        }

        function getQuestionId(string memory question) public pure returns (bytes32){
            return stringToBytes32(question);
        }

        function fillOrder(bytes32 _questionId, uint256 _salt, Side _side, Bid _bid, uint256 _fillamount, uint256 _expiration, bytes memory _signature) external nonReentrant {
            _fillOrder(_questionId, _salt, _side, _bid, _fillamount, _expiration, _signature);
        }

        function getPredictionById(bytes32 _questionId) view external returns (Prediction memory) {
            return predictions[_questionId];
        }

        function getYesPrice(bytes32 _questionId) external view returns (uint256) {
            return predictions[_questionId].yesPrice;
        }

        function getNoPrice(bytes32 _questionId) external view returns (uint256) {
            return predictions[_questionId].noPrice;
        }
}
