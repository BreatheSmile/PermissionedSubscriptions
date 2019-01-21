/*  This is a concept for a permissioned news subscriptions system.
    One envisioned application is in sharing health information, especially for transmissible diseases.
    Users can ask permission to subscribe to updates about other users' health status, as new information becomes available.
    New information is issued by issuing authorities.
    Thus, this file contains an EndUser contract and an Issuer contract, specifying the two roles.
    
    Although Ethereum is currently mostly used for public data,
    this concept assumes the possibility of more private means of data transmission.
    This might be accomplished with the Azure protocol, or yet-to-be-developed means.
*/

pragma solidity ^0.5.0;

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
        
        require ( isTrusted ); _;
        
    }
    
    modifier onlyOwner {
        require ( msg.sender == owner ); _;
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



contract Issuer {
    
    /*  An issuing authority keeps track of subscriptions to updates.
        The issuer sends out data updates to users that own the data
        and to any other users that are subscribed to the update.
    */
    
    struct Subscriber {
        EndUser user;
        uint256 expirationDate;
    }
    
    // A list of subscribed users
    mapping (address => Subscriber[]) subsDirectory;
    // The contract owner
    address owner;
    
    constructor ( ) public {
        owner = msg.sender;
    }
    
    // A modifier restricting function access to the contract's owner
    modifier onlyOwner {
        require ( msg.sender == owner ); _;
    }
    
    function sendUpdate( address user, bool conditionYet ) public onlyOwner {
        
        enduser = mymap[user]
        require(enduser != null, "Wrong address!")
        // Send out an update to a user,
        // and send out a copy of the data to subscribed users.
        
        // The user update
        user.updateData( conditionYet );
        
        // TODO is it good/bad/required to copy this to memory?
        Subscriber[] subs = subsDirectory[ address(user) ];
        
        // The subscriber update
        for ( uint256 i = 0; i < subs.length; i++ ) {
            //check ne expired
            Subscriber memory sub = subs[i];
            // Check that the subscription date is still valid
            if ( now > sub.expirationDate ){
                //mark expired
            } else
                sub.user.subscribedUpdate ( user, conditionYet );
            // TODO else: delete sub from list?
        }   
    }
    
    function newSubscription ( EndUser user, EndUser subscriber ) public {
        // Register a subscriber for a user's updates
        Subscriber memory sub;
        sub.user = subscriber;
        // TODO Maar hoe komt ethereum aan now????
        sub.expirationDate = now + 12 weeks; //TODO variable lease
        subsDirectory[ address(user) ].push( sub );
    }
    
}