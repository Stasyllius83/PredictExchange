// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IAuth } from "../contracts/interfaces/IAuth.sol";

/**
 * @title Абстрактный контракт для аутентификации администратора
 * @notice Основные функции для работы с пользователем администратор
 */
abstract contract Auth is IAuth {

    /**
    * @notice хранилище адресов администратора
    * @dev подтверждает, что пользователь с данным адресом является администратором
    * @notice ключ — адрес пользователя, значение — ложь/истина
    */
    mapping(address => bool) public admins;

    /// @notice Требует, чтобы msg.sender являлся администратором
    modifier onlyAdmin() {
        if (admins[msg.sender] != true) revert NotAdmin();
        _;
    }

    /**
    * @notice конструктор контракта
    * @dev инициализирует контракт адресом администратора
    */
    constructor() {
        admins[msg.sender] = true;
    }

    /**
    * @notice проверяет что пользователь администратор
    * @dev используется для проверки, что пользователь с данным адресом является администратором
    * @return true/false возвращает ложь/истину
    */
    function isAdmin(address usr) external view returns (bool) {
        return admins[usr] == true;
    }

    /**
    * @notice добавляет адрес администратора
    * @dev используется для добавления адреса администратора (только администратор),
    * генерирует событие NewAdmin
    */
    function addAdmin(address admin_) external onlyAdmin {
        admins[admin_] = true;
        emit NewAdmin(admin_, msg.sender);
    }

    /**
    * @notice удаляет адрес администратора
    * @dev используется для удаления адреса администратора (только администратор),
    * генерирует событие RemovedAdmin
    */
    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = false;
        emit RemovedAdmin(admin, msg.sender);
    }
}
