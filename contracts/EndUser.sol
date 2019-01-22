pragma solidity ^0.5.0;

import "./Issuer.sol"; //Issuing authorities
import "./helpers/access/Roles.sol"; //Role management
import "./helpers/access/Whitelist.sol"; //Whitelisting

contract EndUser is Whitelist {
    
    /* An end user A can do the following:
        1) Carry their personal data
        2) List trusted authorities that can update the data
        3) Subscribe to other end users' updates
        4) Give permission to other end users to read user A's updates
    */

    // Library set-up
    using Roles for Roles.Role;

    // Roles
    Roles.Role private owners;      // Contract owners
    Roles.Role private issuers;     // Issuing authorities
    Roles.Role private pendingSubs; // Other end users that are allowed to subscribe

    // Arrays
    Issuer[] arrayOfIssuers; // Issuing authorities in loopable array form
    
    // A user's personal data.
    // States whether the user has @condition.
    // Data about the user is issued by @issuer, at @dateIssued.
    // TODO could be a mapping over issuers
    struct PersonalData {
        bool condition;
        uint256 dateIssued;
        Issuer issuer;
    }
    
    PersonalData private pdata; // This user's data
    uint256 public identity; // A numerical stand-in for identity management
    

    constructor ( uint256 id ) public {
        // The creator is the default owner
        owners.add(msg.sender);
        identity = id;
    }
    
    // Contract ownership management events and functions
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

    // Events and functions for management of issuing authorities
    // TODO events for issuers?

    // Add a new data issuer 
    function addIssuer ( Issuer newIssuer ) public whitelistOnly(msg.sender, owners) {
        issuers.add(address(newIssuer));
        arrayOfIssuers.push(newIssuer);
    }
    
    // Remove a data issuer from the registry
    function removeIssuer ( Issuer badIssuer ) public whitelistOnly(msg.sender, owners) {
        require(issuers.has(address(badIssuer)), "Address is not a trusted issuer");
        // TODO implement array element deletion
    }

    // Issue a data update to the end user, if sender is trusted
    function updateData (bool conditionYet) public whitelistOnly(msg.sender, issuers) {
        pdata.condition = conditionYet;
        pdata.dateIssued = block.timestamp;
        pdata.issuer = Issuer(msg.sender);
        // TODO emit event here / as issuer?
    }
    
    event subUpdateEvent (uint256 indexed identity, uint256 subIdentity, bool conditionYet);
    
    // Inform an end user of an update for a user they are subscribed to
    function subscribedUpdate ( EndUser user, bool conditionYet ) public
        whitelistOnly(msg.sender, issuers) {
        //TODO Anything else need to happen?
        emit subUpdateEvent (this.identity(), user.identity(), conditionYet);
    }

    // Inform an end user of an update, while omitting the user who owns the updated data
    function subscribedUpdateAnon (bool conditionYet) public whitelistOnly(msg.sender, issuers) {
        this.subscribedUpdate(EndUser(address(0)), conditionYet); // Calls default function with null user
    }
    
    // Grant subscriber status to another user
    function allowSubscription (EndUser subscriber) public whitelistOnly(msg.sender, owners) {
        pendingSubs.add(address(subscriber));
    }
    
    // Subscribe to this user's updates
    function subscribe ( EndUser subscriber ) public whitelistOnly(msg.sender, pendingSubs) {
        // Register the subscriber with all issuers
        for (uint i = 0; i < arrayOfIssuers.length; i++) {
            Issuer issuer = arrayOfIssuers[i];
            issuer.newSubscription(this, subscriber);
        }

        //Revoke subscriber status to prevent resubscribing
        pendingSubs.remove(msg.sender);
    }
    
    //TODO unsubscribe?
    
    
}