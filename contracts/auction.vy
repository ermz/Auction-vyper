# @version ^0.2.0

# function list
# 1. createAuction
# 2. bid
# 3. retractBid
# 4. buyItNow
# 5. withdrawEarnings (this function will also deduct % for use of service)
# 6. viewHighestBid
# 7. viewItemSpecifics
# 8. registerSeller
# 9. itemReceived (Or if a certain time has elapsed / similar to mercari)

struct Auction:
    description: String[50]
    startingBid: uint256
    buyItNow: uint256
    time: uint256
    winningBid: uint256
    bidder: address
    paid: bool
    

registeredSeller: HashMap[address, bool]

ownerToAuction: HashMap[address, Auction]

# user keeps track of last winner
# outbid: HashMap[address, HashMap[address, ]]

@external
@payable
def register() -> bool:
    assert msg.value > 1, "You must pay 1 ether in order to register to sell"
    assert self.registeredSeller[msg.sender] == False, "You are already registered"
    self.registeredSeller[msg.sender] = True
    return True

@external
def createAuction(_description: String[50], _startingBid: uint256, _buyItNow: uint256, _time: uint256) -> bool:
    assert self.registeredSeller[msg.sender] == True, "Only registered sellers can create auctions"
    
    if _buyItNow == 0:
        self.ownerToAuction[msg.sender] = Auction({
            description: _description,
            startingBid: _startingBid,
            buyItNow: _buyItNow,
            time: block.timestamp + _time,
            winningBid: 0,
            bidder: ZERO_ADDRESS,
            paid: False
        })
        return True

    assert _buyItNow > _startingBid, "BuyItNow price can't be lower than you starting bid"
    self.ownerToAuction[msg.sender] = Auction({
        description: _description,
        startingBid: _startingBid,
        buyItNow: _buyItNow,
        time: block.timestamp + _time,
        winningBid: 0,
        bidder: ZERO_ADDRESS,
        paid: False
    })
    return True    

@external
def bid(addr: address, amount: uint256) -> bool:
    current_auction: Auction = self.ownerToAuction[addr]
    assert current_auction.time > block.timestamp, "The auction has ended"
    assert current_auction.startingBid >= amount, "Your bid has to be higher than the starting bid"
    assert current_auction.winningBid >= amount, "Your bid has to be higher then the current highest bid"
    assert current_auction.bidder != msg.sender, "You can't oubid yourself. You're winning"

    current_auction.winningBid = amount
    current_auction.bidder = msg.sender
    return True

@external
@payable
def buyIt(addr: address) -> bool:
    current_auction: Auction = self.ownerToAuction[addr]
    assert current_auction.time > block.timestamp, "The auction has ended"
    assert current_auction.buyItNow > 0, "This product doesn't have a buy it now option"
    assert msg.value >= current_auction.buyItNow, "Insufficient funds for purchase"
    # This will basically cause the auction time to end
    current_auction.time = block.timestamp
    return True

@external
@payable
def payForAuction(addr: address) -> bool:
    current_auction: Auction = self.ownerToAuction[addr]
    assert current_auction.time <= block.timestamp, "The auction has yet to end"
    assert current_auction.bidder == msg.sender, "You are not the winner of this auction"
    assert msg.value >= current_auction.winningBid, "Insufficient funds for auction"
    current_auction.paid = True
    return True





    