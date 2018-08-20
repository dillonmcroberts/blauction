pragma solidity ^0.4.24;

contract Standard {

    uint256 highestBidAmount = 0;
    address highestBidder;
    uint minBid = 0;
    uint startBlock;
    uint endBlock;
    string itemName;
    address public seller;
    mapping(address => uint256) public bids;


    constructor (
        uint _minBid,
        uint _startBlock,
        uint _endBlock,
        string _itemName
      ) public {
      // constructor
      // check for a few conditions, make sure that start/end times are valid
      // also make sure that owner exist so we don't end up with locked funds
        require(_startBlock < _endBlock, "Invalid start or end time.");
        require(_startBlock >= block.number, "Invalid start time.");
        require(msg.sender != 0, "Invalid contract owner address.");
      // we'll take the sellers information here and instantiate a contract based on that info
        minBid = _minBid;
        startBlock = _startBlock;
        endBlock = _endBlock;
        itemName = _itemName;
        seller = msg.sender;
    }

    function () public payable {
        revert("Please specify a function when interacting with this contract");
    }

    function makeBid() 
        public
        payable
        auctionIsLive
        notSeller
      {
        // we don't want to allow bids of 0 value
        require(msg.value > 0, "Bids of 0 are not accepted.");
        uint newBid = bids[msg.sender] += msg.value;
        // only proceed with the function if the new bid amount beats the current highest
        require (newBid > highestBidAmount, "This bid does not beat the current highest bid.");
        highestBidAmount = newBid;

        // we can save on gas by not resetting the highest bidder if they are just increasing
        // their top bid
        if (msg.sender != highestBidder) {
            highestBidder = msg.sender;
        }
        emit LogBid(msg.sender, newBid, highestBidder, highestBidAmount);
    }

    function withdraw() public auctionEnded {
        require(msg.sender == seller, "This action is only available once the auction is finished.");
        address withdrawAccount;
        uint withdrawAmount;

        // seller is able to withdraw highest bid (winning bid) at end of auction
        if (msg.sender == seller) {
          // set the function to withdraw funds from highest bidders accounts 
          // this will be used to pay the seller
            withdrawAccount = highestBidder;
            withdrawAmount = highestBidAmount;
        } else {
          // all other bidders should be allowed to withdraw their funds
            withdrawAccount = msg.sender;
            withdrawAmount = bids[withdrawAccount];
        }

        require(withdrawAmount > 0, "No available funds to withdraw");
        bids[withdrawAccount] -= withdrawAmount;

        msg.sender.transfer(withdrawAmount);
        emit LogWithdrawal(msg.sender, withdrawAccount, withdrawAmount);
    }

    modifier notSeller {
        require (msg.sender != seller, "This action is only available to non-seller users");
        _;
    }

    modifier isSeller {
        require(msg.sender == seller, "This action is only available to the seller");
        _;
    }

    modifier auctionStarted {
        require(block.number >= startBlock, "This action can only be done before the auction starts.");
        _;
    }

    modifier auctionEnded {
        require(block.number > endBlock, "This action can only be done once the auction has ended.");
        _;
    }

    modifier auctionIsLive {
        require(block.number >= startBlock, "This action can only be done before the auction starts.");
        require(block.number <= endBlock, "This action can only be done while the auction is live.");
        _;
    }

    event LogBid(
      address bidder,
      uint currentBid,
      address highestBidder,
      uint highestBidAmount
    );

    event LogWithdrawal(
      address withdrawer,
      address withdrawAccount,
      address withdrawAmount
    );

}
