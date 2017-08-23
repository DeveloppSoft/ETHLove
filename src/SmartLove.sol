pragma solidity ^0.4.13;

import "./SafeMath.sol";

/// @title Smartlove
/// @author Eliott Teissonniere
/// A DAPP that allows you to get married on the blockchain. 

contract SmartLove is SafeMath {
  enum State { Initialization, WaitingConfirmations, Married, Divorced }

  State current_state;

  address constant public SEND_FUNDS_TO = 0x7726104068B4d19f416Ea7d44A15d07AB1f89980;
  uint constant public ACCEPT_BID = 0.1 ether;
  uint constant public DIVORCE_BID = 0.4 ether;

  address public party_one;
  address public party_two;

  bytes32 public url_document;

  uint public refund_on;

  uint public required_signatures;

  mapping (address => bool) public is_witness;

  address[] bidders;

  event WitnessAdded(address witness);
  event Accepted(address accepter);
  event StateChanged(State newState);

  /// @notice used to start the marriage agreement
  /// @param first_party party one
  /// @param second_party party two
  /// @param url marriage contract document
  /// @param days_before_refund if that amount of days elapsed before the union is agreed, parties can refund their bid
  function SmartLove(address first_party, address second_party, bytes32 url, uint days_before_refund) {
    require(first_party != SEND_FUNDS_TO);
    require(second_party != SEND_FUNDS_TO);

    party_one = first_party;
    party_two = second_party;
    url_document = url;

    refund_on = safeAdd(now, safeMul(days_before_refund, 1 days));

    required_signatures = 2;

    current_state = State.Initialization;
  }

  /// @notice used by one of the parties to add a witness, the more witnesses, the more "value" has the contract
  /// @param witness address of the witness
  /// @dev we do not require both parties to accept the operation, indeed if one disagree it can just refuse to accept the union
  function addWitness(address witness) {
    require(witness != SEND_FUNDS_TO);
    require(witness != party_one);
    require(witness != party_two);
    require(msg.sender == party_one || msg.sender == party_two);
    require(!is_witness[witness]);
    require(!isInitialized());

    is_witness[witness] = true;

    required_signatures = safeAdd(required_signatures, 1);

    WitnessAdded(witness);
  }

  /// @notice end the initialization phase, goes to WaitingConfirmations one
  function endInitialization() {
    require(msg.sender == party_one || msg.sender == party_two);
    require(!isInitialized());

    setState(State.WaitingConfirmations);
  }

  /// @notice accept the union, all parties and witnesses need to call that, a bid is required to make sure everyone thought carefully about doing the union
  function acceptUnion() payable {
    require(msg.value == ACCEPT_BID);
    require(msg.sender == party_one || msg.sender == party_two || is_witness[msg.sender]);
    require(isInitialized() && !isMarried());

    required_signatures = safeSub(required_signatures, 1);

    // Add to bidders, used for refund
    bidders.push(msg.sender);

    Accepted(msg.sender);

    // Does everyone accepted?
    if (required_signatures == 0) {
      setState(State.Married); // Congratulations to both parties :)

      // Withdraw bids
      SEND_FUNDS_TO.transfer(this.balance);
    }
  }

  /// @notice refund everyone, make the union fail
  function refund() {
    require(refund_on <= now);
    require(isInitialized() && !isMarried());

    // Only a party or witness can call that
    require(msg.sender == party_one || msg.sender == party_two || is_witness[msg.sender]);

    // Now refund
    for (uint i = 0; i < bidders.length; i++) {
      bidders[i].transfer(ACCEPT_BID);
    }

    // Union failed
    selfdestruct(SEND_FUNDS_TO); // At that point contract deosn't hae any ETH
  }

  /// @notice ask divorce, can be called by any of both parties
  function askDivorce() payable {
    require(msg.sender == party_one || msg.sender == party_two);
    require(msg.value == DIVORCE_BID);
    require(isMarried());

    // Just in case (used in unit tests)
    setState(State.Divorced);

    // Break contract
    selfdestruct(SEND_FUNDS_TO);
  }

  // HELPERS

  function setState(State newState) internal {
    current_state = newState;
    StateChanged(newState);
  }

  function isInitialized() constant returns (bool) {
    return current_state > State.Initialization;
  }

  function isMarried() constant returns (bool) {
    return current_state == State.Married;
  }

  function isDivorced() constant returns (bool) {
    return current_state == State.Divorced;
  }
}
