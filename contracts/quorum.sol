pragma solidity ^0.5.0;

//import 'https://github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol';
import './SafeMath.sol';

contract QuorumProposalBase {
    function onSupposedlyCarried() public;
}

// We use a smart contract which we delegate to as a proposal
// This ensures security as well as complete flexibilty as to the effect of the proposal
contract Quorum {
    // A highly composite number
    uint private quorum_numerator = 1;
    uint private quorum_denominator = 2;
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
    function quorumThreshold() public view returns (uint) {
        return SafeMath.div(SafeMath.mul(voter_count, quorum_numerator), quorum_denominator);
    }
    function quorumReached(address proposal) public view returns (bool) { 
        return votesFor(proposal) > quorumThreshold();
    }
    function isPassed(address proposal) public view returns (bool) { return passed[proposal]; }
    function quorumNumerator(address) public view returns (uint) { return quorum_numerator; }
    function quorumDenominator(address) public view returns (uint) { return quorum_denominator; }
    function isQuorumPossible() public view returns (bool) { 
        if (quorum_denominator == 0)
            return false;
        
        uint res = voter_count * quorum_numerator;
        
        return res / quorum_numerator == voter_count;
    }
    
    //
    // Events
    //
    event voterStatusChanged(address indexed addr, bool isVoter);
    event voted(address indexed addr, address indexed proposal);
    event unvoted(address indexed addr, address indexed proposal);
    event carried(address indexed proposal);
    
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
    /// XXX: does not check whether quorum has been reached,
    /// or if it has already been passed 
    function carryOp(address proposal) private {
        passed[proposal] = true;
        emit carried(proposal);
        QuorumProposalBase(proposal).onSupposedlyCarried();
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
        // Stop multicalling
        require(!isPassed(proposal));
        carryOp(proposal);
    }
    function resign() voterOnly public {
        removeVoterOp(msg.sender);
    }
    /// Used if for some reason a proposal breaks the quorum calculation
    function fixQuorum() voterOnly public {
        require(!isQuorumPossible());
        quorum_numerator = 1;
        quorum_denominator = 2;
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
    function setQuorum(uint numerator, uint denominator) public passedOnly { 
        quorum_numerator = numerator;
        quorum_denominator = denominator;
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

contract Quorate {
    Quorum public quorum;
    
    modifier quorate() { require(quorum.isPassed(msg.sender)); _; }
    
    function changeQuorum(Quorum new_quorum) public quorate { quorum = new_quorum; }
    
    constructor(Quorum initial_quorum) public { quorum = initial_quorum; }
}

contract QuorumProposal is QuorumProposalBase {
    address public quorum;
    
    function onCarried() private;
    
    function onSupposedlyCarried() public {
        require(msg.sender == quorum);
        onCarried();
    }
    
    constructor(address target) public { quorum = target; }
}

contract SimpleQuorumProposal is QuorumProposal {
    function body() private;
    
    function onCarried() private {
        body();
        selfdestruct(msg.sender);
    }
    
    constructor(address parent) public QuorumProposal(parent) {}
}