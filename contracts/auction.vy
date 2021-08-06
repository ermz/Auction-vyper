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
    
admin: address    

registeredSeller: HashMap[address, bool]

ownerToAuction: HashMap[address, Auction]

buyerReceived: HashMap[address, HashMap[address, bool]]

contractEarnings: uint256

@external
def __init__():
    self.admin = msg.sender

@external
@view
def viewAuction(addr: address) -> Auction:
    return self.ownerToAuction[addr]

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
    assert current_auction.startingBid <= amount and current_auction.winningBid <= amount, "Your bid has to be higher than the starting bid and winning bid"
    assert current_auction.bidder != msg.sender, "You can't oubid yourself. You're winning"

    self.ownerToAuction[addr].winningBid = amount
    self.ownerToAuction[addr].bidder = msg.sender
    return True

@external
@payable
def buyIt(addr: address) -> bool:
    current_auction: Auction = self.ownerToAuction[addr]
    assert current_auction.time > block.timestamp, "The auction has ended"
    assert current_auction.buyItNow > 0, "This product doesn't have a buy it now option"
    # msg.value is always in wei
    assert msg.value >= (current_auction.buyItNow * 1_000_000_000_000_000_000), "Insufficient funds for purchase"
    # This will basically cause the auction time to end
    # This will also start the time from once the seller was paid
    self.ownerToAuction[addr].time = block.timestamp
    self.ownerToAuction[addr].paid = True
    self.ownerToAuction[addr].bidder = msg.sender
    self.ownerToAuction[addr].winningBid = msg.value
    return True

@external
@payable
def payForAuction(addr: address):
    current_auction: Auction = self.ownerToAuction[addr]
    assert current_auction.time <= block.timestamp, "The auction has yet to end"
    assert current_auction.bidder == msg.sender, "You are not the winner of this auction"
    assert msg.value >= (current_auction.winningBid * 1_000_000_000_000_000_000), "Insufficient funds for auction"
    self.ownerToAuction[addr].time = block.timestamp
    self.ownerToAuction[addr].paid = True

@external
def itemReceived(addr: address) -> bool:
    assert self.ownerToAuction[addr].bidder == msg.sender, "Must be the winning bidder"
    assert self.ownerToAuction[addr].paid == True, "Must have paid for winning auction"
    self.buyerReceived[msg.sender][addr] = True
    return True

@external
def withdrawEarnings():
    current_auction: Auction = self.ownerToAuction[msg.sender]
    assert (current_auction.time + 1629244800) < block.timestamp or self.buyerReceived[current_auction.bidder][msg.sender] == True, "Either buyer approved item or two weeks have passed since being paid"
    # The actual earning for the seller is 90% of what was paid for the product
    # The 10% is earning for the auction smart contract
    # decimal_earnings: float = convert(current_auction.winningBid, float)
    # Have to change the decimal earnings back to uint256 for send() to work
    # contract_earnings: uint256 = convert(decimal_earnings * 0.1, uint256)
    # self.contractEarnings += contract_earnings
    send(msg.sender, 10)
    
@external
def adminWithdraw():
    assert msg.sender == self.admin, "Only the admin may withdraw contract earnings"
    assert self.contractEarnings > 0, "There is nothing to withdraw"
    send(msg.sender, self.contractEarnings)

    