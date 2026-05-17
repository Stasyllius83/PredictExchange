// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Order } from "../libraries/OrderStructs.sol";

abstract contract IExchange {

    struct Prediction {

        string condition;

        bytes32 conditionId;

        address oracle;

        uint256 endsAt;

        uint256 yesPrice;

        uint256 noPrice;

        uint256 sumYes;

        uint256 sumNo;

        uint256 feeYes;

        uint256 feeNo;

        uint256 predictedPrice;

        uint256 matchesCounter;

        Order[] orders;
    }

    event PredictionCreate(
        bytes32 indexed conditionId,
        string indexed condition,
        address indexed oracle,
        uint256 endsAt
    );

    event OrderFilled(
        address indexed user,
        uint256 userAssetId,
        uint256 userAmountFilled,
        bytes32 indexed orderHash
    );

    event OrdersMatched(
        address indexed takerOrderMaker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled
    );

    event TokenExchange(
        address indexed takerOrderMaker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled
    );

    event FeeCharged(
        address indexed payer,
        uint256 tokenId, 
        uint256 fee
    );

    event PredictionResolved(
        bytes32 indexed questionId,
        bool indexed outcome,
        uint256 winningTokenAmount
    );
    
    event WinningsClaimed(
        address indexed user,
        bytes32 indexed questionId,
        uint256 amount,
        bool outcome
    );

    function _createPrediction(string memory _question, address _oracle, uint256 _predictedPrice, uint256 _duration) internal virtual;

    function _resolvePrediction(bytes32 _questionId) internal virtual;
    
    function _claimWinnings(bytes32 _questionId) internal virtual;
}