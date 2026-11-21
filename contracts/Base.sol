// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import {ERC1155} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.5.0/contracts/token/ERC1155/ERC1155.sol";
import { ReentrancyGuard } from "../contracts/libraries/ReentrancyGuard.sol";

/**
 * @title Абстрактный базовый контракт
 * @notice Наследует функции для работы с токенами ERC1155 и проверкой на Re-entrancy attack
 */
abstract contract Base is ERC1155, ReentrancyGuard { }
