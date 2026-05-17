// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(uint256 salt,address signer,uint256 tokenId,uint256 amount,uint256 expiration,uint256 nonce,uint8 side,uint8 bid)"
    );

    struct Order {

        uint256 salt;

        address signer;

        uint256 tokenId;

        uint256 amount;
        
        uint256 expiration;
        
        uint256 nonce;

        Side side;

        Bid bid; 
    }

    enum Side {
        // 0: buy
        BUY,
        // 1: sell
        SELL
    }

    enum Bid {
        // 0: no
        NO,
        // 1: yes
        YES
    }

    enum MatchType {
        NONE,

        COMPLEMENTARY
    }

    error NotOwner();
    error OrderExpired();
    error InvalidNonce();