// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../contracts/tokens/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { SafeTransferLib, ERC20 } from "../contracts/libraries/SafeTransferLib.sol";
import { IAssets } from "../contracts/interfaces/IAssets.sol";
import { IAssetFunctions } from "../contracts/interfaces/IAssetFunctions.sol";
import { IConditionalTokens } from "../contracts/interfaces/IConditionalTokens.sol";


abstract contract AssetFunctions is IAssets, IAssetFunctions, IERC1155 {

    function _getBalance(uint256 tokenId) internal override returns (uint256) {
        if (tokenId == 0) return IERC20(getCollateral()).balanceOf(address(this));
        return IERC1155(getCtf()).balanceOf(address(this), tokenId);
    }

    function _transfer(address from, address to, uint256 id, uint256 value) internal override {
        if (id == 0) return _transferCollateral(from, to, value);
        return _transferCTF(from, to, id, value);
    }

    function _transferCollateral(address from, address to, uint256 value) internal {
        address token = getCollateral();
        if (from == address(this)) SafeTransferLib.safeTransfer(ERC20(token), to, value);
        else SafeTransferLib.safeTransferFrom(ERC20(token), from, to, value);
    }

    function _getBalanceCTF(address holder, uint256 tokenId) internal override returns (uint256) {
        return IERC1155(getCtf()).balanceOf(holder, tokenId);
    }

    function _transferCTF(address from, address to, uint256 id, uint256 value) internal {
        IERC1155(getCtf()).safeTransferFrom(from, to, id, value, "");
    }

    function _mint(address to, bytes32 conditionId, uint8 indexSet, uint256 amount) internal override {
        IConditionalTokens(getCtf()).mintCTF(IERC20(getCollateral()), to, conditionId, indexSet, amount, "");
    }

    function _burn(address to, bytes32 conditionId, uint8 indexSet, uint256 amount) internal override {
        IConditionalTokens(getCtf()).burnCTF(IERC20(getCollateral()), to, conditionId, indexSet, amount);
    }
}
