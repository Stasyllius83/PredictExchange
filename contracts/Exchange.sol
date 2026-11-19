// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../contracts/tokens/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IExchange } from "../contracts/interfaces/IExchange.sol";
import "../contracts/libraries/OrderStructs.sol";
import { IAssets } from "../contracts/interfaces/IAssets.sol";
import { IAssetFunctions } from "../contracts/interfaces/IAssetFunctions.sol";
import { IHashing } from "../contracts/interfaces/IHashing.sol";
import { Nonce } from "../contracts/Nonce.sol";
import { IConditionalTokens } from "../contracts/interfaces/IConditionalTokens.sol";

/**
 * @title Абстрактный контракт для сопоставления заказов и работе с предсказаниями
 * @notice Основные функции для сопоставления заказов и работе с предсказаниями
 */
abstract contract Exchange is IExchange, IAssets, IAssetFunctions, IHashing, Nonce {

    // Коэффициент для сравнения сопоставляемых сумм в заказах (decimals = 6)
    uint256 internal constant ONE = 10 ** 6;
    // Коэффициент комиссии
    uint256 internal constant FEE = 2;
    // Коэффициент проценты
    uint256 internal constant Percent = 100;
    // Хранилище предсказаний
    mapping(bytes32 questionId => Prediction) public predictions;
    // Хранилище разрешенных вопросов
    mapping(bytes32 questionId => bool resolved) public predictionResolved;
    // Хранилище ответов на разрешенные вопросы
    mapping(bytes32 questionId => bool outcome) public predictionOutcome; 
    // Хранилище выиграшных сумм уже разрешенных вопросов
    mapping(bytes32 questionId => uint256 winningTokenAmount) public winningTokenAmount;
    // Хранилище пользователей, получившие выигрыш уже разрешенных вопросов
    mapping(bytes32 questionId => mapping(address user => bool claimed)) public hasClaimed;
    // Массив всех вопросов предсказаний
    string[] public allQuestions;
    // Хранилище подписей
    mapping(address signer => mapping(uint256 tokenId => mapping(uint256 amount => bytes))) public signatures;

    /**
    * @notice преобразует текст вопроса в данные bytes32
    * @param _source текст вопроса
    * @dev преобразует текст вопроса в bytes32 для ключа мэппинга
    * @return result возвращает текст вопроса в bytes32 
    */
    function stringToBytes32(string memory _source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(_source, 32))
        }
    }

    /**
    * @notice создает новое предсказание
    * @param _question вопрос предсказания
    * @param _oracle адрес оракула
    * @param _predictedPrice предсказуемая цена
    * @param _duration продолжительность спора
    * @dev создает предсказание (только администратор)
    */
    function _createPrediction(string memory _question, address _oracle, uint256 _predictedPrice, uint256 _duration) internal override {
        bytes32 _questionId;
        bytes32 _conditionId;
        _questionId = stringToBytes32(_question);
        _conditionId = IConditionalTokens(getCtf()).getConditionId(_oracle, _questionId);
        
        if (bytes(predictions[_questionId].condition).length == 0 && _oracle != address(0) && _predictedPrice != 0 && _duration != 0) {
            predictions[_questionId].condition = _question;
            predictions[_questionId].conditionId = _conditionId;
            predictions[_questionId].oracle = _oracle;
            predictions[_questionId].predictedPrice = _predictedPrice;
            predictions[_questionId].endsAt = block.timestamp + _duration;
            allQuestions.push(_question);
        }

        emit PredictionCreate(_conditionId, _question, _oracle, block.timestamp + _duration);
    }

    /**
    * @notice создает новый заказ
    * @param _questionId вопрос предсказания
    * @param _salt соль
    * @param _side сторона заказа
    * @param _bid ставка заказа
    * @param _fillamount сумма ставки
    * @param _expiration срок заказа 
    * @param _signature подпись
    * @dev создает новый заказ
    */
    function _fillOrder(bytes32 _questionId, uint256 _salt, Side _side, Bid _bid, uint256 _fillamount, uint256 _expiration, bytes memory _signature) internal {
        
        require(block.timestamp < predictions[_questionId].endsAt, "Ended!");
        
        require(_fillamount > 0, "Zero bid");

        uint256 tokenId = IConditionalTokens(getCtf()).getPositionId(IERC20(getCollateral()), 
                                                                    predictions[_questionId].conditionId, 
                                                                    uint8(_bid));
        // проверка баланса при продаже
        if(_side == Side.SELL) {
            require( _getBalanceCTF(msg.sender, tokenId) > 0, "Balance ctf zero");
        }

        MatchType matchType = Match(_questionId, _side, _bid, _fillamount);

        Order memory newOrder;

        //если не совпали, то создание нового
        if (matchType != MatchType.COMPLEMENTARY) {
            incrementNonce();

            newOrder = Order({
                salt: _salt,
                signer: msg.sender,
                tokenId: tokenId,
                amount: _fillamount,
                expiration: _expiration,
                nonce: nonces[msg.sender],
                side: _side,
                bid: _bid
            });

            signatures[msg.sender][tokenId][_fillamount] = _signature;
        } 

        predictions[_questionId].orders.push(newOrder);

    }

    /**
    * @notice сопоставляет заказы
    * @param _questionId вопрос предсказания
    * @param _side сторона заказа
    * @param _bid ставка заказа
    * @param _fillamount сумма ставки
    * @dev сопоставляет заказы
    */
    function Match(bytes32 _questionId, Side _side, Bid _bid, uint256 _fillamount) internal returns (MatchType) {

        Prediction storage cPrediction = predictions[_questionId];
        uint256 length = cPrediction.orders.length;

        MatchType matchType = MatchType.NONE;

        Bid bidOpposite = _bid == Bid.NO ? Bid.YES : Bid.NO;
        Side sideOpposite = _side == Side.SELL ? Side.BUY : Side.SELL;

        uint256 i = 0; 

        for (; i < length;) {
            
            //сделка и минт обоих
            if ((cPrediction.orders[i].side == Side.BUY) && (cPrediction.orders[i].bid == bidOpposite) && 
                (ONE - _fillamount == cPrediction.orders[i].amount)) {

                _validateOrder(hashOrder(cPrediction.orders[i]), cPrediction.orders[i], signatures[cPrediction.orders[i].signer][cPrediction.orders[i].tokenId][cPrediction.orders[i].amount]);
                matchType = _mintAndBuy(cPrediction.orders[i], _questionId, _side, _bid, _fillamount);
                incrementNonce();
                delete predictions[_questionId].orders[i];

            } else 

            //обмен токенами
            if ((cPrediction.orders[i].side == sideOpposite) && (cPrediction.orders[i].bid == _bid) && 
                (_fillamount == cPrediction.orders[i].amount)) {

                _validateOrder(hashOrder(cPrediction.orders[i]), cPrediction.orders[i], signatures[cPrediction.orders[i].signer][cPrediction.orders[i].tokenId][cPrediction.orders[i].amount]);
                matchType = _exchangeToken(cPrediction.orders[i], _questionId, _side, _bid, _fillamount);
                incrementNonce();
                delete predictions[_questionId].orders[i];
            }
            unchecked {
                ++i;
            }
        }   
        return matchType;
    }

    /**
    * @notice переводит средства и минтит новые токены CTF
    * @param _order объект заказа
    * @param _questionId вопрос предсказания
    * @param _side сторона заказа
    * @param _bid ставка заказа
    * @param _fillamount сумма ставки
    * @dev вызывается, когда оба заказа на покупку с противоположными сторонами. Общая сумма = 1usdt
    */
    function _mintAndBuy(Order memory _order, bytes32 _questionId, Side _side, Bid _bid, uint256 _fillamount) internal returns (MatchType) {
        MatchType matchType = MatchType.COMPLEMENTARY;
        Prediction storage cPrediction = predictions[_questionId];

        uint256 senderFee = _bid == Bid.YES ? cPrediction.feeYes : cPrediction.feeNo;
        uint256 orderFee = _order.bid == Bid.YES ? cPrediction.feeYes : cPrediction.feeNo;

        _transfer(msg.sender, address(this), 0, _fillamount);
        _chargeFee(msg.sender, 0, senderFee);
        _transfer(_order.signer, address(this), 0, _order.amount);
        _chargeFee(_order.signer, 0, orderFee);

        // подсчет комиссии при минте новых токенов
        _calculateFee(_questionId);
        _calculatePrice(_questionId, _fillamount - senderFee, _order.amount - orderFee, _side, _bid);

        _mint(msg.sender, cPrediction.conditionId, uint8(_bid), _fillamount - senderFee);
        _mint(_order.signer, cPrediction.conditionId, uint8(_order.bid), _order.amount - orderFee);

        cPrediction.matchesCounter ++;

        uint256 tokenId = IConditionalTokens(getCtf()).getPositionId(IERC20(getCollateral()), 
                                                                    cPrediction.conditionId, 
                                                                    uint8(_bid));
        emit OrdersMatched(msg.sender, _order.tokenId, tokenId, _order.amount - orderFee, _fillamount - senderFee);
        return matchType;
    }

    /**
    * @notice обменивает токены и сжигаены токены CTF со счета владельца
    * @param _order объект заказа
    * @param _questionId вопрос предсказания
    * @param _side сторона заказа
    * @param _bid ставка заказа
    * @param _fillamount сумма ставки
    * @dev вызывается, когда противоположные заказы совпадают по сумме
    */
    function _exchangeToken(Order memory _order, bytes32 _questionId, Side _side, Bid _bid, uint256 _fillamount) internal returns (MatchType) {

        MatchType matchType = MatchType.COMPLEMENTARY;
        Prediction storage cPrediction = predictions[_questionId];

        uint256 senderFee = _bid == Bid.YES ? cPrediction.feeYes : cPrediction.feeNo;
        uint256 orderFee = _order.bid == Bid.YES ? cPrediction.feeYes : cPrediction.feeNo;

        uint256 tokenId = IConditionalTokens(getCtf()).getPositionId(IERC20(getCollateral()), 
                                                                    cPrediction.conditionId, 
                                                                    uint8(_bid));

        if (_side == Side.BUY) {
            _transfer(msg.sender, _order.signer, 0, _fillamount - senderFee);
            _transfer(msg.sender, address(this), 0, senderFee);
            _chargeFee(msg.sender, 0, senderFee);
            _transfer(_order.signer, msg.sender, tokenId, _order.amount - orderFee);
            _chargeFee(_order.signer, tokenId, orderFee);
            _burn(_order.signer, cPrediction.conditionId, uint8(_order.bid), orderFee);
            emit OrdersMatched(msg.sender, tokenId, 0,  _order.amount - orderFee, _fillamount - senderFee);
        } else {
            _transfer(msg.sender, _order.signer, tokenId, _fillamount - senderFee);
            _chargeFee(msg.sender, tokenId, senderFee);
            _transfer(_order.signer, msg.sender, 0, _order.amount - orderFee);
            _transfer(_order.signer, address(this), 0, orderFee);
            _burn(msg.sender, cPrediction.conditionId, uint8(_bid), senderFee);
            _chargeFee(_order.signer, 0, orderFee);
             emit OrdersMatched(msg.sender, 0, tokenId, _order.amount - orderFee, _fillamount - senderFee);
        }
        
        if (_bid == Bid.YES) {
            predictions[_questionId].sumYes -= cPrediction.feeYes;
        } else {
            predictions[_questionId].sumNo -= cPrediction.feeNo;
        }

        return matchType;
    }
    
    /**
    * @notice вычисляет цены позиций
    * @param _questionId вопрос предсказания
    * @param _amountTaker сумма принимающего
    * @param _amountMaker сумма заказывающего
    * @param _side сторона заказа
    * @param _bid ставка заказа
    * @dev вычисляет цены позиций
    */
    function _calculatePrice(bytes32 _questionId, uint256 _amountTaker, uint256 _amountMaker, Side _side, Bid _bid) internal {
        uint256 _sumYes = predictions[_questionId].sumYes;
        uint256 _sumNo = predictions[_questionId].sumNo;
        uint256 yesAmountTaker = _bid == Bid.YES ? _amountTaker : 0;
        uint256 noAmountTaker = _bid == Bid.YES ? 0 : _amountTaker;
        uint256 yesAmountMaker = _bid == Bid.YES ? 0 : _amountMaker;
        uint256 noAmountMaker = _bid == Bid.YES ? _amountMaker : 0;
        _sumYes = _side == Side.SELL ? _sumYes - (yesAmountTaker + yesAmountMaker) : _sumYes + (yesAmountTaker + yesAmountMaker);
        _sumNo = _side == Side.SELL ? _sumNo - (noAmountTaker + noAmountMaker) : _sumNo + (noAmountTaker + noAmountMaker);
        uint256 sum = _sumYes + _sumNo;
        predictions[_questionId].sumYes = _sumYes;
        predictions[_questionId].sumNo = _sumNo;
        predictions[_questionId].yesPrice = (_sumYes * ONE + sum - 1) / sum;
        predictions[_questionId].noPrice = _sumNo * ONE / sum;
    }

    /**
    * @notice вычисляет комиссию
    * @param _questionId вопрос предсказания
    * @dev вычисляет комиссию
    */
    function _calculateFee(bytes32 _questionId) internal {
        predictions[_questionId].feeYes = predictions[_questionId].yesPrice * FEE / Percent;
        predictions[_questionId].feeNo = predictions[_questionId].noPrice * FEE / Percent;
    }

    /**
    * @notice корректирует комиссию после совершенной сделки
    * @param _payer адрес плательщик
    * @param _tokenId индификатор токена
    * @param _fee значение комиссии
    * @dev корректирует комиссию после совершенной сделки
    */
    function _chargeFee(address _payer, uint256 _tokenId, uint256 _fee) internal {
        if (_fee > 0) {
            emit FeeCharged(_payer, _tokenId, _fee);
        }
    }

    /**
    * @notice валидирует заказ
    * @param _orderHash хэш заказа
    * @param _order заказ
    * @param _signature подпись
    * @dev валидирует заказ
    */
    function _validateOrder(bytes32 _orderHash, Order memory _order, bytes memory _signature) internal view {
        // проверка срока действия
        if (_order.expiration <= 0 || _order.expiration < block.timestamp) {
            revert OrderExpired();
        }
        
        // проверка подписи
        validateOrderSignature(_orderHash, _order, _signature);
        
        // проверка nonce
        if (!isValidNonce(_order.signer, _order.nonce)) {
            revert InvalidNonce();
        }
    }

    /**
    * @notice получает актуальную цену из ChainLink
    * @param _aggregator адрес агрегатора пары
    * @dev получает актуальную цену из ChainLink
    */
    function getChainlinkPrice(AggregatorV3Interface _aggregator) internal view returns(uint256) {
        (, int256 price,,,) = _aggregator.latestRoundData();
        uint8 decimals = _aggregator.decimals();
        return uint256(price) / uint256(10 ** (decimals - 2));
    }

    /**
    * @notice разрешает спор
    * @param _questionId идентификатор вопроса предсказания
    * @dev разрешает спор (только администратор)
    */
    function _resolvePrediction(bytes32 _questionId) internal override {
        Prediction storage cPrediction = predictions[_questionId];
        require(block.timestamp >= cPrediction.endsAt, "Not ended!");
        require(!predictionResolved[_questionId], "Already resolved");
        require(bytes(predictions[_questionId].condition).length > 0, "Not exist");


        uint256 priceToday = getChainlinkPrice(AggregatorV3Interface(predictions[_questionId].oracle));

        if (cPrediction.predictedPrice * 10 ** 2 > priceToday) {
            predictionOutcome[_questionId] = true;
        } else {
            predictionOutcome[_questionId] = false;
        }
        predictionResolved[_questionId] = true;
        winningTokenAmount[_questionId] = (predictions[_questionId].sumYes + predictions[_questionId].sumNo) / predictions[_questionId].matchesCounter;
    
        emit PredictionResolved(_questionId, predictionOutcome[_questionId], winningTokenAmount[_questionId]);
    }

    /**
    * @notice получение выигрыша участником
    * @param _questionId идентификатор вопроса предсказания
    * @dev получение выигрыша участником
    */
    function _claimWinnings(bytes32 _questionId) internal override {
        require(predictionResolved[_questionId], "Not resolved");
        require(!hasClaimed[_questionId][msg.sender], "Already claimed");

        uint256 tokenId = IConditionalTokens(getCtf()).getPositionId(IERC20(getCollateral()), predictions[_questionId].conditionId, uint8(predictionOutcome[_questionId] ? Bid.YES : Bid.NO));
        uint256 userTokens = _getBalanceCTF(msg.sender, tokenId);
        require(userTokens > 0, "No winnings to claim");

        hasClaimed[_questionId][msg.sender] = true;
        // Проверяем баланс контракта
        require(_getBalance(0) >= winningTokenAmount[_questionId], "Contract has insufficient balance");

        _transfer(address(this), msg.sender, 0, winningTokenAmount[_questionId]);
        _burn(msg.sender, predictions[_questionId].conditionId, uint8(predictionOutcome[_questionId] ? Bid.YES : Bid.NO), userTokens);

        emit WinningsClaimed(msg.sender, _questionId, winningTokenAmount[_questionId], predictionOutcome[_questionId]);
    }
}