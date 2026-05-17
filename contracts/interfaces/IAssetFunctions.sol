// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract IAssetFunctions {

    function _getBalance(uint256 tokenId) internal virtual returns (uint256);

    function _getBalanceCTF(address holder, uint256 tokenId) internal virtual returns (uint256);

    function _transfer(address from, address to, uint256 id, uint256 value) internal virtual;

    function _mint(address to, bytes32 conditionId, uint8 indexSet, uint256 amount) internal virtual;

    function _burn(address to, bytes32 conditionId, uint8 indexSet, uint256 amount) internal virtual;
}
