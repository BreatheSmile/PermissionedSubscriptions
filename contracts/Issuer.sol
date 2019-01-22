pragma solidity ^0.5.0;


import "./EndUser.sol"; //The subject of, or subscriber to, updates by issuers
import "./helpers/access/Roles.sol"; //Role management
import "./helpers/access/Whitelist.sol"; //Whitelisting

contract Issuer is Whitelist {
    
    /*  An issuing authority keeps track of subscriptions to updates.
        The issuer sends out data updates to users that own the data
        and to any other users that are subscribed to the update.
    */
    
    // Library set-up
    using Roles for Roles.Role;

    // Roles
    Roles.Role private owners;
    Roles.Role private subscribers;
    Roles.Role private users;

    event ownerAdded(address newOwner);
    event ownerRemoved(address oldOwner);

    function addOwner(address newOwner) public whitelistOnly(msg.sender, owners) {
        owners.add(newOwner);
        emit ownerAdded(newOwner);
    }

    function removeOwner(address oldOwner) public whitelistOnly(msg.sender, owners) {
        owners.remove(oldOwner);
        emit ownerRemoved(oldOwner);
    }

    struct Subscriber {
        EndUser user;
        uint256 expirationDate;
    }
    
    // A list of subscribed users
    mapping (address => Subscriber[]) subsDirectory;
        
    constructor ( ) public {
        // Assign the owner role
        owners.add(msg.sender);    
    }
    
    function sendUpdate(EndUser user,  bool anon, bool conditionYet) public
        whitelistOnly(msg.sender, owners)
        whitelistOnly(address(user), users) {
        // Send out an update to a user,
        // and send out a copy of the data to subscribed users.
        
        // TODO should probably implement a pull model,
        // or otherwise handle failed calls

        // Send the update to the user whose data is renewed
        user.updateData(conditionYet);
        
        // Send the update to all subscribers
        Subscriber[] storage subs = subsDirectory[address(user)];
        
        for (uint256 i = 0; i < subs.length; i++) {
            Subscriber memory sub = subs[i];
            // Check whether the subscription has expired
            if (block.timestamp > sub.expirationDate){
                //The subscription has expired
                //TODO rearrange the subscriber list
            } else
                // The subscription is valid
                // Post the update
                if (anon){
                    sub.user.subscribedUpdateAnon (conditionYet);
                }
                else sub.user.subscribedUpdate (user, conditionYet);
        }
    }
    
    function newSubscription ( EndUser user, EndUser subscriber ) public {
        // Register a subscriber for a user's updates
        Subscriber memory sub;
        sub.user = subscriber;
        sub.expirationDate = block.timestamp + 12 weeks; //TODO variable lease
        subsDirectory[address(user)].push(sub);
    }
    
}