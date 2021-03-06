pragma solidity ^0.5.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./ticketauction.sol";

contract TicketMarket is ERC721Full, Ownable {
    
    constructor() ERC721Full("TicketMarket", "TICKETS") public {}
    using Counters for Counters.Counter;
    Counters.Counter token_ids;
    address payable foundation_address = msg.sender;
    
    mapping (uint => TicketAuction) public auctions;
    
    modifier Ticket(uint token_id) {     /*NOT SURE ABOUT THIS PART AND ON*/
        
        require(_exists(token_id), "No ticket found");
        _;
        
    }
    
    function createAuction(uint token_id) public onlyOwner {
        
        auctions[token_id] = new TicketAuction(foundation_address);
        
    }
    
    function registerTicket(string memory uri) public payable onlyOwner {
        
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(foundation_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id);
        
    }
    
    function endAuction(uint token_id) public onlyOwner Ticket(token_id) {
        
        TicketAuction auction = auctions[token_id];
        auction.auctionEnd();
        safeTransferFrom(owner(), auction.highestBidder(), token_id);
        
    }
    
    function auctionEnded(uint token_id) public view returns(bool) {
        
        TicketAuction auction = auctions[token_id];
        return auction.ended();
        
    } 
    
    function highestBid(uint token_id) public view Ticket(token_id) returns(uint) {
        
        TicketAuction auction = auctions[token_id];
        return auction.highestBid();
        
    }
    
    function pendingReturn(uint token_id, address sender) public view Ticket(token_id) returns(uint) {
        
        TicketAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
        
    }
    
    function bid(uint token_id) public payable Ticket(token_id) {
        
        TicketAuction auction = auctions[token_id];
        auction.bid.value(msg.value)(msg.sender);
        
    }

}
    