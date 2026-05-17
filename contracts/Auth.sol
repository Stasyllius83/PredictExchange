// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IAuth } from "../contracts/interfaces/IAuth.sol";

abstract contract Auth is IAuth {
    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        if (admins[msg.sender] != true) revert NotAdmin();
        _;
    }

    constructor() {
        admins[msg.sender] = true;
    }

    function isAdmin(address usr) external view returns (bool) {
        return admins[usr] == true;
    }

    function addAdmin(address admin_) external onlyAdmin {
        admins[admin_] = true;
        emit NewAdmin(admin_, msg.sender);
    }

    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = false;
        emit RemovedAdmin(admin, msg.sender);
    }
}

