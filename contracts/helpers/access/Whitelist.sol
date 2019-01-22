pragma solidity ^0.5.2;

import "./Roles.sol"; //Role management

contract Whitelist {

    // Library set-up
    using Roles for Roles.Role;

    function whitelist(address adr, Roles.Role storage role) internal view returns (bool) {
        return role.has(adr);
    }

    modifier whitelistOnly(address adr, Roles.Role storage role) {
        require(whitelist(adr, role), "Address not whitelisted");
        _;
    }
    
}