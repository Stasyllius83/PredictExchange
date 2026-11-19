// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Интерфейс для аутентификации администратора
 * @notice Основные функции для работы с пользователем администратор
 */
interface IAuth {
    
    /// @notice возникает, когда пользователь не администратор
    error NotAdmin();

    /**
    * @notice событие срабатывает при добавлении нового адреса администратора
    * @param newAdmin адрес администратора
    * @param admin адрес администратора, который добавляет
    */
    event NewAdmin(address indexed newAdmin, address indexed admin);

    /**
    * @notice событие срабатывает при удалении адреса администратора
    * @param removedAdmin адрес администратора
    * @param admin адрес администратора, который удаляет
    */
    event RemovedAdmin(address indexed removedAdmin, address indexed admin);

    /**
    * @notice проверяет что пользователь администратор
    * @dev используется для проверки, что пользователь с данным адресом является администратором
    * @return true/false возвращает ложь/истину
    */
    function isAdmin(address) external view returns (bool);

    /**
    * @notice добавляет адрес администратора
    * @dev используется для добавления адреса администратора (только администратор),
    * генерирует событие NewAdmin
    */
    function addAdmin(address) external;

    /**
    * @notice удаляет адрес администратора
    * @dev используется для удаления адреса администратора (только администратор),
    * генерирует событие RemovedAdmin
    */
    function removeAdmin(address) external;
}
