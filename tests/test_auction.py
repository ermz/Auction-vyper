import pytest
from brownie import accounts, auction, Contract
import brownie

def test_register(_auction, bob):
    with brownie.reverts("You must pay 1 ether in order to register to sell"):
        _auction.register({"from": bob})
    _auction.register({"from": bob, "value": "1 ether"})
    with brownie.reverts("You are already registered"):
        _auction.register({"from": bob, "value": "1 ether"})

def test_create_auction(_auction, bob):
    assert _auction.viewAuction(bob)["startingBid"] == 0
    with brownie.reverts("Only registered sellers can create auctions"):
        _auction.createAuction("Air Jordan 1[mitn]", 150, 450, 604_800, {"from": bob})
    _auction.register({"from": bob, "value": "1 ether"})
    with brownie.reverts("BuyItNow price can't be lower than you starting bid"):
        _auction.createAuction("Vintage coke bottle", 120, 110, 604_800, {"from": bob})
    _auction.createAuction("Harry Potter collection", 80, 0, 604_800, {"from": bob})
    assert _auction.viewAuction(bob)["buyItNow"] == 0

def test_bid(bid_started, bob, charles):
    with brownie.reverts("Your bid has to be higher than the starting bid and winning bid"):
        bid_started.bid(bob, 2, {"from": charles})
    bid_started.bid(bob, 10, {"from": charles})
    assert bid_started.viewAuction(bob)["winningBid"] == 10
    with brownie.reverts("You can't oubid yourself. You're winning"):
        bid_started.bid(bob, 12, {"from": charles})

def test_buy_it(bid_started, bob, charles):
    assert bid_started.viewAuction(bob)["paid"] == False
    with brownie.reverts("Insufficient funds for purchase"):
        bid_started.buyIt(bob, {"from": charles, "value": "12 ether"})
    bid_started.buyIt(bob, {"from": charles, "value": "15 ether"})
    assert bid_started.viewAuction(bob)["paid"] == True
    with brownie.reverts("The auction has ended"):
        bid_started.bid(bob, 16, {"from": accounts[4]})

def test_pay_for_auction(bid_ended, bob, charles):
    assert bid_ended.viewAuction(bob)["paid"] == False
    with brownie.reverts("You are not the winner of this auction"):
        bid_ended.payForAuction(bob, {"from": accounts[4], "value": "5 ether"})
    with brownie.reverts("Insufficient funds for auction"):
        bid_ended.payForAuction(bob, {"from": charles, "value": "3 ether"})
    bid_ended.payForAuction(bob, {"from": charles, "value": "5 ether"})
    assert bid_ended.viewAuction(bob)["paid"] == True

def test_item_receive(bid_ended, bob, charles):
    with brownie.reverts("Must have paid for winning auction"):
        bid_ended.itemReceived(bob, {"from": charles})
    bid_ended.payForAuction(bob, {"from": charles, "value": "5 ether"})
    assert bid_ended.itemReceived.call(bob, {"from": charles}) == True


def test_withdraw_earnings(bid_ended, alice, bob, charles):
    bid_ended.payForAuction(bob, {"from": charles, "value": "5 ether"})
    with brownie.reverts("Either buyer approved item or two weeks have passed since being paid"):
        bid_ended.withdrawEarnings({"from": bob})
    bid_ended.itemReceived(bob, {"from": charles})
    current_contract_balance = bid_ended.balance()
    bid_ended.withdrawEarnings({"from": bob})
    assert bid_ended.balance() <= current_contract_balance
    next_contract_balance = bid_ended.balance()
    bid_ended.adminWithdraw({"from": alice})
    assert next_contract_balance > bid_ended.balance()