ragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";

contract EventCoin is ERC721Full, Ownable {
    
    constructor() ERC721Full("EventToken", "EVNT") public {}
    
    using SafeMath for uint;
    using Counters for Counters.Counter;
    
    uint eventtoken_count;
    uint AmountHold;
    uint TokenidHold;
    address payable BuyerHold;
    event EventTokenOwner(address owner, uint token_id);
    event ForSale(uint token_id, uint SeatNum, uint CurrentValue, address owner);
    
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
        bool AvailableResale;
        uint ResalePercentage;
    }
    
    mapping(uint => Event) public event_tokens;
    
    
    function registerEvent(address payable owner, string memory EventName, string memory EventOwner, uint EventDate, uint SeatNum, uint OriginalValue, uint MaxValue, bool Resale, uint ResalePercentage) private returns(uint) {
        
        token_ids.increment();
        uint token_id = token_ids.current();
        
        _mint(owner, token_id);
        
        eventtoken_count += 1;
        
        event_tokens[token_id] = Event(EventName, EventOwner, owner, owner, EventDate, SeatNum, OriginalValue, OriginalValue, MaxValue, Resale, false, ResalePercentage);
        
        emit EventTokenOwner(owner, token_id);
        return token_id;
        
    }
    
    
    function registerEventMultiSeat(address payable owner, string memory EventName, string memory EventOwner, uint EventDate, uint FirstSeatNum, uint LastSeatNum, uint OriginalValue, uint MaxValue, bool Resale, uint ResalePercentage) public {
        
        require(ResalePercentage >= 0 && ResalePercentage <= 50, "The percentage of resale profits must be between 0% and 50%.");
        
        uint Seat = FirstSeatNum;
        
        OriginalValue = OriginalValue * 1000000000000000000;
        MaxValue = MaxValue * 1000000000000000000;
        
        while (Seat <= LastSeatNum) {
            
            registerEvent(owner, EventName, EventOwner, EventDate, Seat, OriginalValue, MaxValue, Resale, ResalePercentage);
            
            Seat += 1;
            
        }
    
    }    
    
    function Purchase(uint token_id) payable public {
        
        uint value = event_tokens[token_id].CurrentValue;
        uint Mvalue = event_tokens[token_id].MaxValue;
        
        require(msg.value >= value, "You do not have enough to purchase this event token.");
        require(msg.value <= Mvalue, "The amount offered is greater than the maximum amount this event token is allowed to be sold for.");
        require(event_tokens[token_id].Issuer == event_tokens[token_id].CurrentOwner, "This event token has already been sold.  You can check and see if it is available for resale.");
        
        AmountHold = msg.value;
        TokenidHold = token_id;
        BuyerHold = msg.sender;
        
    }
    
    
    function AcceptPurchase() payable public {
        uint token_id = TokenidHold;
        require(msg.sender == event_tokens[token_id].CurrentOwner,"You are not the owner of this event token.");
         
        address payable Owner = event_tokens[token_id].CurrentOwner;
        address payable buyer = BuyerHold;
        uint value = AmountHold;
        
        delete AmountHold;
        delete TokenidHold;
        delete BuyerHold;
        
        event_tokens[token_id].CurrentOwner = buyer;
        event_tokens[token_id].CurrentValue = value;
        event_tokens[token_id].AvailableResale = false;
        
        safeTransferFrom(Owner, buyer, token_id);
        emit EventTokenOwner(buyer, token_id);
        
        Owner.transfer(value);
        
    }
    
    function MakeAvailableSale(uint token_id) public {
        require(msg.sender == event_tokens[token_id].CurrentOwner,"You are not the owner of this event token.");
        require(event_tokens[token_id].Resale = true, "This event token can not be resold.");
        
        event_tokens[token_id].AvailableResale = true;
    }
    
    function UnavailableForSale(uint token_id) public {
        require(msg.sender == event_tokens[token_id].CurrentOwner,"You are not the owner of this event token.");
        
        event_tokens[token_id].AvailableResale = false;
    }
    
    
    function ThirdPartyPurchase(uint token_id) payable public {
        uint value = event_tokens[token_id].CurrentValue;
        uint Mvalue = event_tokens[token_id].MaxValue;
        
        require(event_tokens[token_id].Resale == true, "This event token can not be resold.");
        require(event_tokens[token_id].AvailableResale == true, "This event token is not available for resale at this time.");
        require(msg.value >= value, "You do not have enough to purchase this event token.");
        require(msg.value <= Mvalue, "The amount offered is greater than the maximum amount this event token is allowed to be sold for.");
        
        AmountHold = msg.value;
        TokenidHold = token_id;
        BuyerHold = msg.sender;
        
    }
    
    function ThirdPartyAccept() payable public {
        
        uint token_id = TokenidHold;
        require(msg.sender == event_tokens[token_id].CurrentOwner,"You are not the owner of this event token.");
        
        address payable Owner = event_tokens[token_id].CurrentOwner;
        address payable buyer = BuyerHold;
        address payable OriginalIssuer = event_tokens[token_id].Issuer;
        uint value = AmountHold;
        uint Cvalue = event_tokens[token_id].CurrentValue;
        uint PerIssuer = event_tokens[token_id].ResalePercentage;
        uint PerOwner = 100 - PerIssuer;
        
        delete AmountHold;
        delete TokenidHold;
        delete BuyerHold;
        
        uint appreciation = value - Cvalue;
        uint toOriginalIssuer = appreciation * PerIssuer / 100;
        uint toHolder = (appreciation * PerOwner / 100) + (appreciation - ((appreciation * PerOwner / 100) + (appreciation * PerIssuer / 100))) + Cvalue;
        
        event_tokens[token_id].CurrentOwner = buyer;
        event_tokens[token_id].CurrentValue = value;
        event_tokens[token_id].AvailableResale = false;
        
        safeTransferFrom(Owner, buyer, token_id);
        emit EventTokenOwner(buyer, token_id);
        
        OriginalIssuer.transfer(toOriginalIssuer);
        Owner.transfer(toHolder);
        
    }
    
    function ThirdPartyReject() payable public {
        
        uint token_id = TokenidHold;
        require(msg.sender == event_tokens[token_id].CurrentOwner,"You are not the owner of this event token.");
        
        address payable buyer = BuyerHold;
        uint value = AmountHold;
        
        delete AmountHold;
        delete TokenidHold;
        delete BuyerHold;
        
        buyer.transfer(value);
    }
    
        
    
    function AvailableForSale () public {
        
        uint num = 1;
        
        while (num >= eventtoken_count) {
            
            if(event_tokens[num].Issuer == event_tokens[num].CurrentOwner) {
                
                emit ForSale(num, event_tokens[num].SeatNum, event_tokens[num].CurrentValue, event_tokens[num].CurrentOwner);
            }
            
            if(event_tokens[num].Resale == true && event_tokens[num].AvailableResale == true) {
                
                emit ForSale(num, event_tokens[num].SeatNum, event_tokens[num].CurrentValue, event_tokens[num].CurrentOwner);
                
            }
            
            num += 1;
            
        }
        
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