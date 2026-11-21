// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockConditionalTokens is ERC1155 {
    IERC20 public collateralToken;

    constructor(address _collateralToken) ERC1155("") {
        collateralToken = IERC20(_collateralToken);
    }

    function getConditionId(address oracle, bytes32 questionId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(oracle, questionId));
    }

    function getPositionId(IERC20 _collateralToken, bytes32 conditionId, uint8 indexSet) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_collateralToken, conditionId, indexSet)));
    }

    function mintCTF(IERC20, address to, bytes32 conditionId, uint8 indexSet, uint256 amount, bytes memory) external {
        uint256 id = getPositionId(collateralToken, conditionId, indexSet);
        _mint(to, id, amount, "");
    }

    function burnCTF(IERC20, address from, bytes32 conditionId, uint8 indexSet, uint256 amount) external {
        uint256 id = getPositionId(collateralToken, conditionId, indexSet);
        _burn(from, id, amount);
    }
}
