pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";

contract EventCoin is ERC721Full, Ownable {
    
    constructor() ERC721Full("EventToken", "EVNT") public {}
    
    using SafeMath for uint;
    using Counters for Counters.Counter;
    
    Counters.Counter token_ids;
    
    struct Event {
        string EventName;
        string EventOwner;
        address payable Issuer;
        address payable CurrentOwner;
        uint EventDate;
        uint SeatNum;
        uint OriginalValue;
        uint CurrentValue;
        uint MaxValue;
        bool Resale;
    }
    
    mapping(uint => Event) public event_tokens;
    
    
    function registerEvent(address payable owner, string memory EventName, string memory EventOwner, uint EventDate, uint SeatNum, uint OriginalValue, uint MaxValue, bool Resale) public returns(uint) {
        
        token_ids.increment();
        uint token_id = token_ids.current();
        
        _mint(owner, token_id);
        
        event_tokens[token_id] = Event(EventName, EventOwner, owner, owner, EventDate, SeatNum, OriginalValue, OriginalValue, MaxValue, Resale);
        
        return token_id;
        
    }
    
    
    function registerEventMultiSeat(address payable owner, string memory EventName, string memory EventOwner, uint EventDate, uint FirstSeatNum, uint LastSeatNum, uint OriginalValue, uint MaxValue, bool Resale) public {
        
        uint Seat = FirstSeatNum;
        
        while (Seat <= LastSeatNum) {
            
            registerEvent(owner, EventName, EventOwner, EventDate, Seat, OriginalValue, MaxValue, Resale);
            
            Seat += 1;
            
        }
    
    }    
    
    function initialSale(uint token_id) payable public returns(bool) {
        
        uint value = event_tokens[token_id].CurrentValue;
        uint Mvalue = event_tokens[token_id].OriginalValue;
        address payable Owner = event_tokens[token_id].CurrentOwner;
        address payable buyer = msg.sender;
        
        require(msg.value >= value, "You do not have enough to purchase this event token.");
        require(msg.value > Mvalue, "The amount offered is greater than the maximum amount this event token is allowed to be sold for.");
        
        Owner.transfer(msg.value);
        
        event_tokens[token_id].CurrentOwner = buyer;
            
        safeTransferFrom(Owner, buyer, token_id);
        
        
    }
    
    function resale(uint token_id) payable public {
        
        require(event_tokens[token_id].Resale == true, "This event token can not be resold.");
        
        uint value = event_tokens[token_id].CurrentValue;
        uint Ovalue = event_tokens[token_id].OriginalValue;
        uint Mvalue = event_tokens[token_id].OriginalValue;
        address payable OriginalIssuer = event_tokens[token_id].Issuer;
        address payable Owner = event_tokens[token_id].CurrentOwner;
        address payable buyer = msg.sender;
        
        require(msg.value >= value, "You do not have enough to purchase this event token.");
        require(msg.value > Mvalue, "The amount offered is greater than the maximum amount this event token is allowed to be sold for.");
        
        uint appreciation = msg.value - Ovalue;
        uint toOriginalIssuer = appreciation * 20 / 100;
        uint toHolder = (appreciation * 80 / 100) + (appreciation - ((appreciation * 80 / 100) + (appreciation * 20 / 100))) + Ovalue;
        
        OriginalIssuer.transfer(toOriginalIssuer);
        Owner.transfer(toHolder);
        
        event_tokens[token_id].CurrentOwner = buyer;
            
        safeTransferFrom(Owner, buyer, token_id);
            
        
        
    }   
    
    function redeem_token(uint token_id) payable public {
        
        address payable OriginalIssuer = event_tokens[token_id].Issuer;
        address payable Owner = event_tokens[token_id].CurrentOwner;
        
        require(event_tokens[token_id].EventDate >= now, "This event has not yet occured.");
        require(msg.sender == Owner, "You are not the owner of this event token.");
        
        event_tokens[token_id].CurrentValue = 0;
        event_tokens[token_id].OriginalValue = 0;
        event_tokens[token_id].CurrentOwner = OriginalIssuer;
        event_tokens[token_id].Resale = false;
        
        safeTransferFrom(Owner, OriginalIssuer, token_id);
        
        
    }
    
    
    

}
