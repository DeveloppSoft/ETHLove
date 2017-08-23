pragma solidity ^0.4.13;

import "ds-test/test.sol";

import "./SmartLove.sol";

contract FakeParty {
    SmartLove love;

    function setLove(SmartLove smartlove) {
        love = smartlove;
    }

    function accept() {
         love.acceptUnion.value(this.balance)();
    }

    function divorce() {
         love.askDivorce.value(this.balance)();
    }

    function refund() {
         love.refund();
    }

    function() payable {}
}

contract SmartLoveTest is DSTest {
    // events to test
    event WitnessAdded(address witness);
    event Accepted(address accepter);
    event StateChanged(uint newState); // enum converted to uint

    uint constant ACCEPT_BID = 0.1 ether;
    uint constant DIVORCE_BID = 0.4 ether;

    SmartLove love;
    FakeParty party;

    function stringToBytes32(string memory source) internal constant returns (bytes32 result) {
        assembly {
             result := mload(add(source, 32))
        }
    }

    function setUp() {
        party = new FakeParty();
        love = new SmartLove(this, address(party), stringToBytes32("<url here>"), 7);
        party.setLove(love);
        party.transfer(ACCEPT_BID);
    }

    function test_basic_sanity() {
        assert(love.party_one() == address(this));
        assert(love.party_two() == address(party));
        assert(love.url_document() == stringToBytes32("<url here>"));
        assert(love.required_signatures() == 2);

        assert(!(love.isInitialized() || love.isMarried()));
    }

    function testFail_party_cannot_be_collector() {
        love = new SmartLove(0x1, 0x7726104068B4d19f416Ea7d44A15d07AB1f89980,  stringToBytes32("<url here>"), 7);
    }

    function test_party_can_add_witness() {
        // Check events too
        expectEventsExact(love);
        WitnessAdded(0x3);

        love.addWitness(0x3);

        assert(love.is_witness(0x3));

        // Should increase signatures
        assert(love.required_signatures() == 3);
    }

    function testFail_non_party_cannot_add_witness() {
        love = new SmartLove(0x1, 0x2, stringToBytes32("<url here>"), 7);

        love.addWitness(0x3);
    }

    function testFail_party_cannot_be_witness() {
        love.addWitness(this);
    }

    function testFail_cannot_add_witness_twice() {
        love.addWitness(0x3);
        love.addWitness(0x3);
    }

    function testFail_witness_cannot_be_fund_collector() {
        love.addWitness(0x7726104068B4d19f416Ea7d44A15d07AB1f89980);
    }

    function test_end_initialization_sanity() {
        expectEventsExact(love);
        StateChanged(1);

        love.endInitialization();

        assert(love.isInitialized() && !love.isMarried());
    }

    function testFail_non_party_cannot_end_initialization() {
        love = new SmartLove(0x1, 0x2, stringToBytes32("<url here>"), 7);

        love.endInitialization();
    }

    function test_accept_and_empty_balance() {
        expectEventsExact(love);
        StateChanged(1);
        Accepted(address(this));
        Accepted(address(party));
        StateChanged(2);

        love.endInitialization();

        love.acceptUnion.value(ACCEPT_BID)();
        party.accept();

        assert(love.isMarried() && love.isInitialized());
        assert(love.balance == 0);
    }

    function testFail_accept_throw_if_not_sufficient_bid() {
        love.endInitialization();
        love.acceptUnion(); // value is 0
    }

    function testFail_accept_throw_if_not_initialized() {
        love.acceptUnion.value(ACCEPT_BID)();
    }

    function test_witness_accept() {
        FakeParty witness = new FakeParty();
        witness.setLove(love);

        expectEventsExact(love);
        WitnessAdded(address(witness));
        StateChanged(1);
        Accepted(address(this));
        Accepted(address(party));
        Accepted(address(witness));
        StateChanged(2);

        love.addWitness(address(witness));

        love.endInitialization();

        witness.transfer(ACCEPT_BID);

        love.acceptUnion.value(ACCEPT_BID)();
        party.accept();
        witness.accept();

        assert(love.isMarried() && love.isInitialized());
        assert(love.balance == 0);
    }

    function test_refund() {
        uint oldBalance = this.balance;

        love = new SmartLove(this, 0x1, stringToBytes32("<url here>"), 0);

        love.endInitialization();

        love.acceptUnion.value(ACCEPT_BID)();
        assert(love.balance == ACCEPT_BID);
        assert(this.balance == oldBalance - ACCEPT_BID);

        love.refund();

        assert(love.balance == 0);
        assert(this.balance == oldBalance);
    }

    function testFail_cannot_refund_if_married() {
        love.endInitialization();

        love.acceptUnion.value(ACCEPT_BID)();
        party.accept();

        // Married!
        assert(love.isMarried());

        // Refund should fail
        love.refund();
    }

    function testFail_cannot_refund_if_not_initialized() {
        // Check state
        assert(!love.isInitialized());

        love.refund();
    }

    function testFail_refund_witness() {
        uint oldBalance = this.balance;

        love = new SmartLove(this, 0x1, stringToBytes32("<url here>"), 0);

        love.endInitialization();

        // add a witness
        FakeParty witness = new FakeParty();
        witness.setLove(love);

        witness.transfer(ACCEPT_BID);

        love.addWitness(address(witness));

        assert(love.is_witness(address(witness)));

        // Accept union
        love.acceptUnion.value(ACCEPT_BID)();

        // Witness ask refund
        witness.refund();

        assert(love.balance == 0);
        assert(this.balance == oldBalance);
    }

    function testFail_cannot_refund_if_not_party_or_witness() {
        love.endInitialization();

        love.acceptUnion.value(ACCEPT_BID)();

        // New FakeParty
        party = new FakeParty();
        party.setLove(love);

        // throw
        party.refund();
    }

    function testFail_divorce_throw_insufficient_bid() {
        love.endInitialization();

        love.acceptUnion.value(ACCEPT_BID)();

        party.accept();

        assert(love.isMarried());

        // Call with no bid
        love.askDivorce();
    }

    function testFail_only_party_can_divorce() {
        love = new SmartLove(this, address(party), stringToBytes32("<url here>"), 0);

        love.endInitialization();

        // add a witness
        FakeParty witness = new FakeParty();
        witness.setLove(love);

        witness.transfer(DIVORCE_BID);

        love.addWitness(address(witness));

        love.endInitialization();
        love.acceptUnion.value(ACCEPT_BID)();
        party.accept();

        assert(love.isMarried());

        // throw
        witness.divorce();
    }

    function test_divorce() {
        love.endInitialization();

        love.acceptUnion.value(ACCEPT_BID)();

        party.accept();

        assert(love.isMarried());

        love.askDivorce.value(DIVORCE_BID)();

        assert(love.balance == 0);

        assert(!love.isMarried());
        assert(love.isDivorced());
    }

    function () payable {
        // Used for refund
    }
}
