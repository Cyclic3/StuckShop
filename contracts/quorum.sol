pragma solidity ^0.5.7;

import 'github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol';
import 'github.com/OpenZeppelin/zeppelin-solidity/contracts/access/Roles.sol';

contract QuorumProposal {
    function onCarried(address carrying_quorum) public;
    function kill() public { selfdestruct(msg.sender); }
}

// We use a smart contract which we delegate to as a proposal
// This ensures security as well as complete flexibilty as to the effect of the proposal
//
// 360 is used as the divisor, as it is highly composite
contract Quorum {
    uint private per360_quorum = 180;
    uint private voter_count;
    mapping(address => bool) private voters;
    mapping(address => uint) private proposal_votes;
    mapping(address => mapping(address => bool)) private voted_on;
    
    mapping(address => bool) private passed;
    
    //
    // Basic checks
    //
    function voterCount() public view returns (uint) { return voter_count; }
    function isVoter(address addr) public view returns (bool) { return voters[addr]; }
    function votedOn(address addr, address proposal) public view returns (bool) { return voted_on[addr][proposal]; }
    function votesFor(address proposal) public view returns (uint) { return proposal_votes[proposal]; }
    function quorumReached(address proposal) public view returns (bool) { 
        uint per360_in_favour = SafeMath.div(SafeMath.mul(360, votesFor(proposal)), voter_count);
        return per360_in_favour > per360_quorum;
    }
    function isPassed(address proposal) public view returns (bool) { return passed[proposal]; }
    
    //
    // Events
    //
    event voterStatusChanged(address addr, bool isVoter);
    event voted(address addr, address proposal);
    event unvoted(address addr, address proposal);
    event carried(address proposal);
    event uncarried(address proposal);
    
    //
    // Basic ops
    // XXX: do not check eligible
    //
    function addVoterOp(address addr) private {
        voter_count = SafeMath.add(voter_count, 1);
        voters[addr] = true; 
        emit voterStatusChanged(addr, true);
    }
    // Even when removed, the voter gets to keep their votes. It also keeps the has voted flag
    function removeVoterOp(address addr) private { 
        voter_count = SafeMath.sub(voter_count, 1);
        voters[addr] = false; 
        emit voterStatusChanged(addr, false); 
    }
    /// XXX: does not check whether voter can vote
    function voteOp(address addr, address proposal) private { 
        proposal_votes[proposal] = SafeMath.add(proposal_votes[proposal], 1);
        voted_on[addr][proposal] = true;
        emit voted(addr, proposal);
    }
    /// XXX: does not check whether voter can vote
    function unvoteOp(address addr, address proposal) private { 
        proposal_votes[proposal] = SafeMath.sub(proposal_votes[proposal], 1);
        voted_on[addr][proposal] = false;
        emit unvoted(addr, proposal);
    }
    /// XXX: does not check whether quorum has been reached
    function carryOp(address proposal) private {
        passed[proposal] = true;
        emit carried(proposal);
        QuorumProposal(proposal).onCarried(address(this));
    }
    function uncarryOp(address proposal) private {
        // Reentrancy protection
        // Yields a false positive, but this order is ok
        passed[proposal] = false;
        QuorumProposal(proposal).kill();
        emit uncarried(proposal);
    }
    
    //
    // Modifiers
    //
    modifier voterOnly() {
        require(isVoter(msg.sender));
        _;
    }
    modifier passedOnly() {
        require(isPassed(msg.sender));
        _;
    }
    
    //
    // User functions
    //
    function vote(address proposal) public voterOnly {
        // No double voting!
        require(!votedOn(msg.sender, proposal));
        voteOp(msg.sender, proposal);
    }
    function unvote(address proposal) public voterOnly {
        // No double unvoting!
        require(votedOn(msg.sender, proposal));
        unvoteOp(msg.sender, proposal);
    }
    function carry(address proposal) public {
        require(quorumReached(proposal));
        carryOp(proposal);
    }
    function resign() voterOnly public {
        removeVoterOp(msg.sender);
    }
    
    //
    // Passed functions
    //
    function addVoter(address addr) public passedOnly { 
        if (!isVoter(addr))
            addVoterOp(addr); 
    }
    function removeVoter(address addr) public passedOnly {
        if (isVoter(addr))
            removeVoterOp(addr); 
    }
    function setQuorum(uint new_per360_quorum) public passedOnly { 
        per360_quorum = new_per360_quorum;
    }
    function finish(address addr) public passedOnly { 
        if (isPassed(addr))
            uncarryOp(addr);
    }
    function transfer(address payable addr, uint256 amount) public passedOnly { 
        addr.transfer(amount);
    }
    function kill() public passedOnly { 
        selfdestruct(msg.sender);
    }
    constructor (address founder) public {
        addVoterOp(founder);
    }
}


contract SimpleQuorumProposal is QuorumProposal {
    function body(Quorum carrying_quorum) public;
    
    function onCarried(address carrying_quorum) public {
        Quorum q = Quorum(carrying_quorum);
        body(q);
        q.finish(address(this));
    }
}
