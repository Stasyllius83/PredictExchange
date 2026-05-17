// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../tokens/IERC20.sol";

interface IConditionalTokens {
    
    function getConditionId(address oracle, bytes32 questionId) external pure returns (bytes32);

    function getPositionId(IERC20 collateralToken, bytes32 conditionId, uint8 indexSet) external pure returns (uint);

    function mintCTF(IERC20 collateralToken, address to, bytes32 conditionId, uint8 indexSet, uint256 amount, bytes memory data) external;
    
    function burnCTF(IERC20 collateralToken, address to, bytes32 conditionId, uint8 indexSet, uint256 amount) external;
}