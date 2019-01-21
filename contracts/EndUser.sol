pragma solidity ^0.5.0;

import "./Issuer.sol"; //Issuing authorities

contract EndUser {
    
    /* An end user A can do the following:
        1) Carry their personal data
        2) List trusted authorities that can update the data
        3) Subscribe to other end users' updates
        4) Give permission to other end users to read user A's updates
    */
    
    // A user's personal data.
    // States whether the user has @condition.
    // Data about the user is issued by @issuer, at @dateIssued.
    struct PersonalData {
        bool condition;
        uint256 dateIssued;
        address issuer;
    }
    
    // Initialize user data storage
    PersonalData private pdata;
    
    // Initialize trusted data issuer registry
    Issuer[] private trustedIssuers;
    EndUser[] private subscribers;
    
    address private owner;
    uint256 public identity; // A numerical stand-in for identity management
    
    constructor ( uint256 id ) public {
        owner = msg.sender;
        identity = id;
    }
    
    // A modifier restricting action to trusted data issuers
    modifier onlyTrusted {
        bool isTrusted = false;
        
        // Check if msg.sender is a trusted issuer
        for ( uint i = 0; i < trustedIssuers.length; i++ )
            if ( Issuer(msg.sender) == trustedIssuers[i] ) {
                isTrusted = true;
                break;
            }
        
        require ( isTrusted );
        _;
        
    }
    
    modifier onlyOwner {
        require ( msg.sender == owner );
        _;
    }
    
    modifier onlySubscribers {
        // TODO check that msg.sender is a subscriber (convert address to EndUser ?)
        _;
    }
    
    // Issue a data update to the end user, if sender is trusted
    function updateData ( bool conditionYet ) public onlyTrusted {
        pdata.condition = conditionYet;
        pdata.dateIssued = now;
        pdata.issuer = msg.sender;
    }
    
    event subUpdateEvent ( uint256 indexed identity, uint256 subIdentity, bool conditionYet );
    
    // Inform an end user of an update for a user they are subscribed to
    function subscribedUpdate ( EndUser user, bool conditionYet ) public onlyTrusted {
        //TODO Anything else need to happen?
        emit subUpdateEvent ( this.identity(), user.identity(), conditionYet );
    }
    
    // Grant subscriber status to another user
    function allowSubscription ( EndUser subscriber ) public onlyOwner {
        subscribers.push(subscriber);
    }
    
    // Subscribe to this user's updates
    function subscribe ( EndUser subscriber ) public onlySubscribers {
        // Register the subscriber with all issuers
        for ( uint i = 0; i < trustedIssuers.length; i++ ) {
            Issuer issuer = trustedIssuers[i];
            issuer.newSubscription( this, subscriber );
        }
    }
    
    //TODO unsubscribe?
    
    
    // Add a new data issuer to the registry of trusted issuers
    function startTrusting ( Issuer newIssuer ) public onlyOwner {
        trustedIssuers.push( newIssuer );
    }
    
    function stopTrusting ( Issuer badIssuer ) public onlyOwner {
        // TODO does pop work by reference?
        // TODO what if issuer not in list?
        for ( uint i = 0; i < trustedIssuers.length; i++ ) {
            Issuer issuer = trustedIssuers[i];
            // TODO delete sets element to default value. What is that and is it safe?
            if ( issuer == badIssuer ) delete trustedIssuers[i];
        }
    }
}