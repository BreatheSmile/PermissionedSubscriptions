pragma solidity ^0.5.0;


import "./EndUser.sol"; //The subject of, or subscriber to, updates by issuers

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
        require ( msg.sender == owner );
        _;
    }
    
    function sendUpdate( address user, bool conditionYet ) public onlyOwner {
        mapping (address => bool) memory mymap;
        EndUser enduser = mymap[user];
        require(enduser != address(0), "Wrong address!");
        // Send out an update to a user,
        // and send out a copy of the data to subscribed users.
        
        // The user update
        user.updateData( conditionYet );
        
        // TODO is it good/bad/required to copy this to memory?
        Subscriber[] memory subs = subsDirectory[ address(user) ];
        
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