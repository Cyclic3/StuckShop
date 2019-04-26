pragma solidity ^0.5.0;

import './quorum.sol';

contract ElectoralCouncil is Quorate {
    mapping (address => bool) private is_on_roll;
    uint term_length_blocks;
    
    event voterAdded(address indexed voter);
    event voterRemoved(address indexed voter);
    
    function termLength() public view returns (uint) {
        return term_length_blocks;
    }
    
    function isRegistered(address voter) public view returns (bool) {
        return is_on_roll[voter];
    }
    
    function setTermLength(uint length_blocks) public quorate {
        term_length_blocks = length_blocks;
    }
    
    function register(address voter) public quorate returns (bool) {
        if (isRegistered(voter)) return false;
        is_on_roll[voter] = true;
        emit voterAdded(voter);
        return true;
    }
    
    function unregister(address voter) public quorate returns (bool) {
        if (!isRegistered(voter)) return false;
        is_on_roll[voter] = false;
        emit voterRemoved(voter);
        return true;
    }
    
    constructor(Quorum council) public Quorate(council) {}
}

contract ElectoralCouncilAddVotersProposal is SimpleQuorumProposal {
    address[] targets;
    
    function body() private {
        ElectoralCouncil council = ElectoralCouncil(quorum);
        for (uint i = 0; i < targets.length; ++i)
            council.register(targets[i]);
    }
    
    constructor(address council, address[] memory voters) public SimpleQuorumProposal(council) {
        targets = voters;
    }
}

contract ElectoralCouncilRemoveVotersProposal is SimpleQuorumProposal {
    address[] targets;
    
    function body() private {
        ElectoralCouncil council = ElectoralCouncil(quorum);
        for (uint i = 0; i < targets.length; ++i)
            council.unregister(targets[i]);
    }
    
    constructor(address council, address[] memory voters) public SimpleQuorumProposal(council) {
        targets = voters;
    }
}

contract ElectoralCouncilSetTermLengthProposal is SimpleQuorumProposal {
    uint new_length_blocks;
    
    function body() private {
        ElectoralCouncil council = ElectoralCouncil(quorum);
        council.setTermLength(new_length_blocks);
    }
    
    constructor(address council, uint length_blocks) public SimpleQuorumProposal(council) {
        new_length_blocks = length_blocks;
    }
}

/// A token-based first-past-the-post election system
contract ElectionToken {
    mapping (address => uint256) private balances;
    uint256 public totalSupply;
    address election;
    ElectoralCouncil council;
    
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
    
    modifier ownerOnly() { require(msg.sender == election); _; }
    
    function kill() public ownerOnly {
        selfdestruct(msg.sender);
    }
    
    function hasWon(address candidate) public view returns (bool)  { 
        return balances[candidate] > totalSupply / 2;
    }
    
    function registerOp(address voter) private {
        balances[voter] = 1;
        emit Transfer(address(this), voter, 1);
    }
    
    function tryRegister(address voter) public returns (bool) {
        if (council.isRegistered(voter)) return false;
        
        registerOp(voter);
        
        return true;
    }
    
    function register(address voter) public {
        require(!council.isRegistered(voter));
        registerOp(voter);
    }
    
    constructor(address owner, ElectoralCouncil controlling_council) public { 
        council = controlling_council;
        election = owner; 
    }
}

/// XXX: Make sure that you pass the Election before running, or it won't work after you win
contract Election is Quorate, QuorumProposal {
    Quorate parliament;
    ElectoralCouncil council = new ElectoralCouncil(Quorum(quorum));
    
    uint private last_election_block;
    
    ElectionToken private current_ballot;
    
    event elected(address indexed);
    
    //
    // Views
    //
    function canElect() public view returns (bool) { 
        return block.timestamp >= (last_election_block + council.termLength());
    }
    function currentBallot() public view returns (ElectionToken) {
        return current_ballot;
    }
    function electoralCouncil() public view returns (ElectoralCouncil) {
        return council;
    }
    
    //
    // Some party inspection tools
    //
    function isAttemptedCoup(Quorum q) view public returns (bool) {
        // Assumes that one cannot unpass the election
        return !q.isPassed(address(this));
    }
    
    //
    // Restricted functions
    //
    function coup() public quorate {
        selfdestruct(msg.sender);
    }
    /// Resets the election
    function itsNotFair() public quorate {
        current_ballot.kill();
        current_ballot = new ElectionToken(address(this), council);
    }
    
    //
    // Public functions
    //
    function declareVictory() public {
        // Check if it is time to pass another election
        require(canElect());
        require(current_ballot.hasWon(msg.sender));
        parliament.changeQuorum(Quorum(msg.sender));
        itsNotFair();
    }
    
    //
    // Interface
    //
    function onCarried() private {}
}