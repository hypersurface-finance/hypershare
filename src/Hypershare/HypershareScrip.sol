// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import '../Interface/IHypershare.sol';

contract Hyperwrap is ERC20, ERC1155Holder {

  	////////////////
    // ERRORS
    ////////////////

    // Token transfer invalid
    error TransferInvalid();

    ////////////////
    // CONTRACT
    ////////////////
    
    IHypershare public _share;

    ////////////////
    // STATE
    ////////////////

    // Share token id in the share contract
    uint256 public _id;

    // Metadata uri for legal contract 
	string public _uri;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        IHypershare share,
        uint256 id,
        string memory name_,
        string memory symbol_,
        string memory uri
    )
        ERC20(name_, symbol_)
    {
        _id = id;
        _uri = uri;
        _share = IHypershare(share);
    }

    //////////////////////////////////////////////
    // METADATA
    //////////////////////////////////////////////

    // Returns the address of the corresponding hypershare contract
    function hypershare()
        public
        view
        virtual
        returns (address)
    {
        return address(_share);
    }

    // Returns the token id for this wrapper token. Each wrapper is locked to a single token id
    function tokenId()
        public
        view
        virtual
        returns (uint256)
    {
        return _id;
    }

    // Returns the metadata uri for this wrapper token
    function uri()
        public
        view
        virtual
        returns (string memory)
    {
        return _uri;
    }

    //////////////////////////////////////////////
    // WRAP | UNWRAP
    //////////////////////////////////////////////
    
    // Deposit tokens and mint scrip
    function wrapTokens(
        address account,
        uint256 amount
    )
        public
    {
        // Handle deposit of ERC1155 tokens
        _share.safeTransferFrom(account, address(this), _id, amount, "" );
        
        // Mint scrip
        _mint(account, amount);

        // Event
    }

    // Withdraw tokens and burn scrip
    function unWrapTokens(
        address account, 
        uint256 amount
    )
        public
    {
        // Require _share can transfer
        require(_share.checkTransferIsValid(address(this), account, _id, amount), TransferInvalid());
        
        // Handle unwrap if done by third party
        if (msg.sender != account) {
            uint _allowance =  allowance(account, msg.sender);
            require(_allowance > amount, "ERC20: burn amount exceeds allowance");
            uint256 decreasedAllowance =  _allowance - amount; 
            _approve(account, msg.sender, decreasedAllowance);
        }
        
        // Burn the scrip
        _burn(account, amount);
        
        // Return _share
        _share.safeTransferFrom(address(this), account, _id, amount, "" );

        // Event
    }
}