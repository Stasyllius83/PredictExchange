// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../tokens/IERC20.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";

contract ConditionalTokens is IConditionalTokens, ERC1155 {

    constructor() ERC1155("") {}

    function getConditionId(address oracle, bytes32 questionId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(oracle, questionId));
    }

    function getPositionId(IERC20 collateralToken, bytes32 conditionId, uint8 bid) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(collateralToken, conditionId, bid)));
    }

    function mintCTF(IERC20 collateralToken, address to, bytes32 conditionId, uint8 indexSet, uint256 amount, bytes memory data) public {
                _mint(
                    to,
                    getPositionId(collateralToken, conditionId, indexSet),
                    amount,
                    data
                );
    }

    function burnCTF(IERC20 collateralToken, address to, bytes32 conditionId, uint8 indexSet, uint256 amount) public {
                _burn(
                    to,
                    getPositionId(collateralToken, conditionId, indexSet),
                    amount
                );
    }

}
