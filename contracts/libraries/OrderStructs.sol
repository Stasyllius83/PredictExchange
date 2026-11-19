// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(uint256 salt,address signer,uint256 tokenId,uint256 amount,uint256 expiration,uint256 nonce,uint8 side,uint8 bid)"
    );

    /// @notice структура заказа
    struct Order {
        /// @notice уникальная соль для обеспечения энтропии
        uint256 salt;
        /// @notice подписант заказа
        address signer;
        /// @notice идентификатор токена актива стандарта ERC1155 (CTF), подлежащего покупке или продаже
        uint256 tokenId;
        /// @notice количество токенов
        uint256 amount;
        /// @notice временная метка, после которой срок действия ордера истекает
        uint256 expiration;
        /// @notice нонс, используемый для создания уникальности каждой транзакции в блокчейне
        uint256 nonce;
        /// @notice сторона заказа: BUY (покупка) или SELL (продажа)
        Side side;
        /// @notice ставка заказа: YES (за) или NO (против)
        Bid bid; 
    }

    /// @notice сторона ордера
    enum Side {
        // 0: покупка
        BUY,
        // 1: продажа
        SELL
    }

    /// @notice ставка ордера
    enum Bid {
        // 0: против
        NO,
        // 1: за
        YES
    }

    /// @notice комплементарность/взаимнодополняемость ордера
    enum MatchType {
        NONE,

        COMPLEMENTARY
    }

    /// @notice не владелец контракта
    error NotOwner();

    /// @notice заказ истек
    error OrderExpired();

    /// @notice некорректный нонс
    error InvalidNonce();