import pytest
from brownie import accounts, auction, Contract, chain

@pytest.fixture()
def alice(accounts):
    return accounts[0]

@pytest.fixture()
def bob(accounts):
    return accounts[1]

@pytest.fixture()
def charles(accounts):
    return accounts[2]

@pytest.fixture()
def _auction(alice):
    _auction = auction.deploy({"from": alice})
    return _auction

@pytest.fixture()
def bid_started(alice, bob):
    bid_started = auction.deploy({"from": alice})
    bid_started.register({"from": bob, "value": "1 ether"})
    bid_started.createAuction("Toad sculpture", 3, 15, 604_800, {"from": bob})
    return bid_started

@pytest.fixture()
def bid_ended(alice, bob, charles):
    bid_ended = auction.deploy({"from": alice})
    bid_ended.register({"from": bob, "value": "1 ether"})
    bid_ended.createAuction("Half a pop-tart", 2, 8, 60, {"from": bob})
    bid_ended.bid(bob, 5, {"from": charles})
    chain.sleep(61)
    return bid_ended
