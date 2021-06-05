pragma solidity >=0.4.22 <0.6.0;

contract TicketAuction {
    
    address deployer;
    address payable public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    mapping (address =>uint) pendingReturns;
    bool public ended;
    event HighestBidIncreased (address bidder, uint amount);
    event AuctionEnded (address winner, uint amount);
    
    constructor (address payable _beneficiary) public{
        
        deployer = msg.sender;
        beneficiary = _beneficiary;
        
    }
    
    function bid() public payable {
        
        require(now <= auctionEndTime, "The auction has ended.");
        require(msg.value > highestBid, "A higher bid has been placed.");
        
        if(highestBid != 0) {
            
            pendingReturns[highestBidder] +=highestBid;
            
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    
    }
    
    function pendingReturn(address sender)public view returns (uint) {
        
        return pendingReturns[sender];
        
    }
    
    function withdraw() public returns(bool) {
        
        uint amount = pendingReturns[msg.sender];
        
        if (amount > 0) {
            
            pendingReturns[msg.sender] = 0;
            
            if(!msg.sender.send(amount)) {
                
                pendingReturns[msg.sender] = amount;
                return false;
                
            }
            
        }
        
        return true;
    }
    
    function auctionEnd() public {
        
        require(!ended, "The auction has ended.");
        require(msg.sender == deployer, "This is not your ticket.");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
        
    }
    
    
    
    
    
    
}











