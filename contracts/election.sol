pragma solidity ^0.5.0;

import './quorum.sol';

/// A token-based first-past-the-post election system
contract ElectionToken {
    mapping (address => uint256) private balances;
    uint256 public totalSupply;
    address election;
    mapping (address => bool) private is_registered;
    
    string public constant name = "Election Token";
    string public constant symbol = "ELCTN";
    uint8 public constant decimals = 0;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    function balanceOf(address who) view public returns (uint256) {
        return balances[who];
    }

    function allowance(address, address) public pure returns (uint256 remaining) {
        return 0;
    }

    function approve(address, uint256) public pure returns (bool success) {
        return false;
    }

    function transferFrom(address, address, uint256) public pure returns (bool success) {
        return false;
    }

    function transfer(address to, uint256 value) public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);
        emit Transfer(msg.sender, to, value);
    }
    
    modifier electionFixing() { require(msg.sender == election); _; }
    
    function kill() public electionFixing {
        selfdestruct(msg.sender);
    }
    
    function hasWon(address candidate) public view returns (bool)  { 
        return balances[candidate] > totalSupply / 2;
    }
    
    function isRegistered(address voter) public view returns (bool) {
        return is_registered[voter];
    }
    
    function registerOp(address voter) private {
        is_registered[voter] = true;
        balances[voter] = 1;
        emit Transfer(address(this), voter, 1);
    }
    
    function tryRegister(address voter) public electionFixing returns (bool) {
        if (isRegistered(voter)) return false;
        
        registerOp(voter);
        
        return true;
    }
    
    function register(address voter) public electionFixing {
        require(!isRegistered(voter));
        registerOp(voter);
    }
    
    constructor(address owner) public { election = owner; }
}

/// XXX: Make sure that you pass the Election before running, or it won't work after you win
contract Election is Quorate, QuorumProposal {
    Quorate parliament;
    
    uint private last_election_timestamp;
    uint private term_length_seconds;
    
    ElectionToken currentBallot;
    
    event elected(address indexed);
    
    //
    // Views
    //
    function canElect() public view returns (bool) { 
        return block.timestamp >= (last_election_timestamp + term_length_seconds);
    }
    
    //
    // Some party inspection tools
    //
    function isAttemptedCoup(Quorum q) view public returns (bool) {
        // Assumes that one cannot unpass the election
        return !q.isPassed(address(this));
    }
    
    //
    // Ops
    //
    
    //
    // Restricted functions
    //
    function coup() public quorate {
        selfdestruct(msg.sender);
    }
    /// Resets the election
    function itsNotFair() public quorate() {
        currentBallot = new ElectionToken(address(this));
    }
    function register(address voter) public quorate {
        currentBallot.register(voter);
    }
    function tryRegister(address voter) public quorate {
        currentBallot.tryRegister(voter);
    }
    function changeTermLength(uint newLength) public quorate {
        term_length_seconds = newLength;
    }
    
    //
    // Public functions
    //
    function declareVictory() public {
        // Check if it is time to pass another election
        require(canElect());
        require(currentBallot.hasWon(msg.sender));
        parliament.changeQuorum(Quorum(msg.sender));
        currentBallot.kill();
        currentBallot = new ElectionToken(address(this));
    }
    
    //
    // Interface
    //
    function onCarried(address) public {}
}
contract ElectoralRoll is SimpleQuorumProposal {
    address[] newVoters;
    
    function body() private {
        Election election = Election(quorum);
        for (uint i = 0; i < newVoters.length; ++i)
            election.tryRegister(newVoters[i]);
    }
}