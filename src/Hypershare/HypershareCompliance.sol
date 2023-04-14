// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import '.././Interface/IHypershareCompliance.sol';

// Calling
import '.././Interface/IHyperbaseClaimRegistry.sol';

// #TODO: sanity checks

contract HypershareCompliance is IHypershareCompliance, Ownable {

  	////////////////
    // INTERFACES
    ////////////////

    // Claims reg contract
    IHyperbaseClaimRegistry public _claimRegistry;

  	////////////////
    // STATE
    ////////////////

    // Claims topics that will be required to hold shares
    mapping(uint256 => uint256[]) public _claimTopicsRequired;
    
    // Adresses that will be exempt
    mapping(address => bool) public _whitelisted;

  	////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address claims
    ) {
        setClaimRegistry(claims);
    }

  	////////////////
    // MODIFIER
    ////////////////

    // Ensure the claim topic does not already exist
    modifier topicNotExists(
        uint256 claimTopic,
        uint256 tokenId
    ) {
        for (uint256 i = 0; i < _claimTopicsRequired[tokenId].length; i++) {
            if (_claimTopicsRequired[tokenId][i] == claimTopic)
                revert TopicExists();
        }
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE CLAIM TOPICS
    //////////////////////////////////////////////

    // Add a claim topic to be required of holders
    function addClaimTopic(
        uint256 claimTopic,
        uint256 tokenId
    )
        public
        override
        onlyOwner
        topicNotExists(claimTopic, tokenId)
    {
        // Add topic 
        _claimTopicsRequired[tokenId].push(claimTopic);

        // Event
        emit AddedClaimTopic(claimTopic, tokenId);
    }

    // Remove claim topic required of holders
    function removeClaimTopic(
        uint256 claimTopic,
        uint256 tokenId
    )
        public
        override
        onlyOwner
    {
        // Iterate through and remove the topic
        for (uint256 i = 0; i < _claimTopicsRequired[tokenId].length; i++) {
            if (_claimTopicsRequired[tokenId][i] == claimTopic) {
                _claimTopicsRequired[tokenId][i] = _claimTopicsRequired[tokenId][_claimTopicsRequired[tokenId].length - 1];
                _claimTopicsRequired[tokenId].pop();
                emit RemovedClaimTopic(claimTopic, tokenId);
                break;
            }
        }
    }

    //////////////////////////////////////////////
    // ADD | REMOVE WHITELIST
    //////////////////////////////////////////////

    // Add to whitelist
    function addToWhitelist(
        address account
    )
        public
        onlyOwner
    {
        _whitelisted[account] = true;
    }

    // Remove from whitelist
    function removeFromWhitelist(
        address account
    )
        public
        onlyOwner
    {
        _whitelisted[account] = false;
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Set claims
    function setClaimRegistry(
        address claims
    )
        public
        onlyOwner
    {
        _claimRegistry = IHyperbaseClaimRegistry(claims);
        emit UpdatedClaimRegistry(claims);
    }
    
    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////
    
    // Checks the elligibility of batch transfer
    function checkCanTransferBatch(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            if (!checkRecieverIsElligible(to, ids[i])) {
                return false;
            }
        }
        return true;
    }
    
    // Checks the elligibility of a reciever 
    function checkRecieverIsElligible(
        address account,
        uint256 tokenId
    )
        public
        view
        returns (bool)
    {
        // Sanity checks
        if (account == address(0)) return false;

        // If no claims required or exempt return true
        if (_claimTopicsRequired[tokenId].length == 0 || _whitelisted[account] == true) return true;

        else {

            // Iterate through required claims
            for (uint256 i = 0; i < _claimTopicsRequired[tokenId].length; i++) {

                // Get claim ids by the topic of the required claim
                bytes32[] memory claimIds = _claimRegistry.getClaimIdsByTopic(account, _claimTopicsRequired[tokenId][i]);
                
                // If the subject does not have any claims corresponding to the required topics
                if (claimIds.length == 0) return false;
                
                // Iterate through claims by tokenId and check validity
                for (uint256 ii = 0; ii < claimIds.length; ii++) {

                    if (_claimRegistry.checkIsClaimValidById(account, claimIds[ii])) return true;

                    else return false; 
                    
                }
            }
            return true;
        }
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns required claims for token
    function getClaimTopicsRequired(
        uint256 tokenId
    )
        external
        view
        returns (uint256[] memory)
    {
        return _claimTopicsRequired[tokenId];
    }

}