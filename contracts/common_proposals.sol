pragma solidity ^0.5.7;

import './quorum.sol';

contract KillQuorumProposal is SimpleQuorumProposal {
    function body(Quorum carrying_quorum) public {
        carrying_quorum.kill();
    }
}

contract AddVoterQuorumProposal is SimpleQuorumProposal {
    address public target;
    function body(Quorum carrying_quorum) public {
        carrying_quorum.addVoter(target);
    }
    constructor(address candidate) public { 
        target = candidate;
    }
}

contract RemoveVoterQuorumProposal is SimpleQuorumProposal {
    address public target;
    function body(Quorum carrying_quorum) public {
        carrying_quorum.removeVoter(target);
    }
    constructor(address candidate) public { 
        target = candidate;
    }
}

contract TransferQuorumProposal is SimpleQuorumProposal {
    address payable public target;
    uint256 public value;
    
    function body(Quorum carrying_quorum) public {
        carrying_quorum.transfer(target, value);
    }
    constructor(address payable receiver, uint256 amount) public { 
        target = receiver;
        value = amount;
    }
}
