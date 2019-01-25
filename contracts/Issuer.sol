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

    function addUser(EndUser user) public whitelistOnly(msg.sender, owners) {
        users.add(address(user));
    }

    function removeUser(EndUser user) public whitelistOnly(msg.sender, owners){
        users.remove(address(user));
    }

    // TODO Might make more sense that this is a Subscription?
    // The same user can be a subscriber for multiple end users' updates...
    struct Subscriber {
        EndUser user;
        uint256 expirationDate;
    }

    // The time until a subscription expires
    uint subscriberLease;
    
    //A list of subscribed users
    mapping (address => Subscriber[]) subsDirectory;
            
    constructor (uint _subscriberLease) public {
        // Assign the owner role
        owners.add(msg.sender);
        subscriberLease = _subscriberLease;
    }
    
    // Send out an update to a user,
    // and send out a copy of the data to subscribed users.
    function sendUpdate(EndUser user,  bool anon, bool conditionYet) public
        whitelistOnly(msg.sender, owners)
        whitelistOnly(address(user), users) {
        
        // TODO should probably implement a pull model,
        // or otherwise handle failed calls

        // Send the update to the user whose data is renewed
        user.updateData(conditionYet);
        
        // Send the update to all subscribers
        Subscriber[] storage subs = subsDirectory[address(user)];
        
        for (uint i = 0; i < subs.length; i++) {
            Subscriber memory sub = subs[i];
            // Check whether the subscription has expired
            if (block.timestamp > sub.expirationDate){
                //The subscription has expired
                /*TODO best way to delete a subscriber?
                Current implementation:
                Move the tail element of the array
                to the deletion site.
                Then shorten the array by 1 position.
                */
                uint tailIndex = subs.length - 1;
                if (i != tailIndex) {
                    // Check that i wasn't the tail index already
                    subs[i] = subs[tailIndex];
                }
                // Shorten the list, implicitly deleting the element at the end
                subs.length -= 1;
            } else
                // The subscription is valid
                // Post the update
                if (anon){
                    sub.user.subscribedUpdateAnon (conditionYet);
                }
                else sub.user.subscribedUpdate (user, conditionYet);
        }
    }
    
    // Register a subscriber for a user's updates
    function newSubscription ( EndUser user, EndUser subscriber ) public
        whitelistOnly(address(user), users)
        whitelistOnly(address(subscriber), users) {
        require(msg.sender == address(user), "Subscription can only be authorized by data owner");
        
        // Set up a Subscriber struct instance
        Subscriber memory sub;
        sub.user = subscriber;
        sub.expirationDate = block.timestamp + subscriberLease;
        
        // Add the Subscriber to the registry
        subsDirectory[address(user)].push(sub);
    }
    
}