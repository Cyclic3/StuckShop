pragma solidity ^0.5.7;

import './quorum.sol';

contract SimpleQuorumProposal is QuorumProposal {
    function body(Quorum carrying_quorum) public;
    
    function onCarried(address carrying_quorum) public {
        Quorum q = Quorum(carrying_quorum);
        body(q);
        selfdestruct(msg.sender);
    }
}

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

contract CommonQuorumProposalFactory {
    function killProposal() public returns (QuorumProposal) {
        return new KillQuorumProposal();
    }
    function addVoterProposal(address target) public returns (QuorumProposal) {
        return new AddVoterQuorumProposal(target);
    }
    function removeVoterProposal(address target) public returns (QuorumProposal) {
        return new RemoveVoterQuorumProposal(target);
    }
    function transferProposal(address payable receiver, uint256 amount) public returns (QuorumProposal) {
        return new TransferQuorumProposal(receiver, amount);
    }
}