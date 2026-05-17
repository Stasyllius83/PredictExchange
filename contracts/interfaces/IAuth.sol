// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IAuth {
    
    error NotAdmin();

    event NewAdmin(address indexed newAdmin, address indexed admin);

    event RemovedAdmin(address indexed removedAdmin, address indexed admin);

    function isAdmin(address) external view returns (bool);

    function addAdmin(address) external;

    function removeAdmin(address) external;
}
