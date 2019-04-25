pragma solidity ^0.5.0;

import './quorum.sol';

contract KillQuorumProposal is SimpleQuorumProposal {
    function body() private {
        Quorum(quorum).kill();
    }
    
    constructor(address parent) public SimpleQuorumProposal(parent) {}
}

contract AddVoterQuorumProposal is SimpleQuorumProposal {
    address public voter;
    function body() private {
        Quorum(quorum).addVoter(voter);
    }
    constructor(address parent, address candidate) public SimpleQuorumProposal(parent) { 
        voter = candidate;
    }
}

contract RemoveVoterQuorumProposal is SimpleQuorumProposal {
    address public voter;
    function body() private {
        Quorum(quorum).removeVoter(voter);
    }
    constructor(address parent, address candidate) public SimpleQuorumProposal(parent) { 
        voter = candidate;
    }
}

contract TransferQuorumProposal is SimpleQuorumProposal {
    address payable public target;
    uint256 public value;
    
    function body() private {
        Quorum(quorum).transfer(target, value);
    }
    constructor(address parent, address payable receiver, uint256 amount) public SimpleQuorumProposal(parent) { 
        target = receiver;
        value = amount;
    }
}

contract CommonQuorumProposalFactory {
    function killProposal(address parent) public returns (QuorumProposalBase) {
        return new KillQuorumProposal(parent);
    }
    function addVoterProposal(address parent, address target) public returns (QuorumProposalBase) {
        return new AddVoterQuorumProposal(parent, target);
    }
    function removeVoterProposal(address parent, address target) public returns (QuorumProposalBase) {
        return new RemoveVoterQuorumProposal(parent, target);
    }
    function transferProposal(address parent, address payable receiver, uint256 amount) public returns (QuorumProposalBase) {
        return new TransferQuorumProposal(parent, receiver, amount);
    }
}