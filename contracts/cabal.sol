pragma solidity ^0.5.7;

import './quorum.sol';

contract ValidatorSet {
    /// Issue this log event to signal a desired change in validator set.
    /// This will not lead to a change in active validator set until
    /// finalizeChange is called.
    ///
    /// Only the last log event of any block can take effect.
    /// If a signal is issued while another is being finalized it may never
    /// take effect.
    ///
    /// _parent_hash here should be the parent block hash, or the
    /// signal will not be recognized.
    event InitiateChange(bytes32 indexed _parent_hash, address[] _new_set);

    /// Get current validator set (last enacted or initial if no changes ever made)
    function getValidators() public view returns (address[] memory _validators);

    /// Called when an initiated change reaches finality and is activated.
    /// Only valid when msg.sender == SUPER_USER (EIP96, 2**160 - 2)
    ///
    /// Also called when the contract is first enabled for consensus. In this case,
    /// the "change" finalized is the activation of the initial set.
    function finalizeChange() public;
}

contract Cabal is Quorum, ValidatorSet {
    address[] private validators;
    
    function setValidators(address[] memory addr) public {
        validators = addr;
        emit InitiateChange(blockhash(block.number - 1), validators);
    }
    
    function getValidators() public view returns (address[] memory _validators) {
        return validators;
    }
    
    function finalizeChange() public { return; }
    
    constructor(address founder) public Quorum(founder) {
        validators = [founder];
    }
}