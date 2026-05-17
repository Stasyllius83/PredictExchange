// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ReentrancyGuard } from "../contracts/libraries/ReentrancyGuard.sol";

abstract contract Base is ERC1155, ReentrancyGuard { }
