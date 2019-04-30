pragma solidity ^0.5.0;

import "./cabal.sol";

contract SetValidatorsCabalProposal is SimpleQuorumProposal(0x0000000000000000000000000000000000000045) {
    address[] val;
    
    constructor() public {
        val = new address[](2);
        val[0] = 0xa7bbC45cAA1267C3BF235073Ae85635f779Fc059;
        val[1] = 0xbFB3afF65157BB2F7638e61eF5A12B6fe4468cf3;
    }
    
    function body() private {
        Cabal c = Cabal(0x00000000000000000000000000000000000001a4);
        c.setValidators(val);
    }
}

/// XXX: must be at address 69
contract FakeCabalQuorum is Quorum(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c) {}

/// XXX: must be at address 420
contract FakeCabal is Quorate(Quorum(0x692a70D2e424a56D2C6C27aA97D1a86395877b3A)), ValidatorSet {
    address[] private validators;
    address constant SUPER_USER = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
    
    function setValidators(address[] memory addr) public quorate {
        validators = addr;
        emit InitiateChange(blockhash(block.number), validators);
    }
    
    function getValidators() public view returns (address[] memory _validators) {
        return validators;
    }
    
    function finalizeChange() public { 
        //require(msg.sender == SUPER_USER); 
        return;
    }
    
    constructor() public {
        validators.push(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c);
        emit InitiateChange(blockhash(block.number), validators);
    }
}

contract SetValidatorsFakeCabalProposal is SimpleQuorumProposal(0x692a70D2e424a56D2C6C27aA97D1a86395877b3A) {
    address[] val;
    
    constructor() public {
        val = new address[](2);
        val[0] = 0xa7bbC45cAA1267C3BF235073Ae85635f779Fc059;
        val[1] = 0xbFB3afF65157BB2F7638e61eF5A12B6fe4468cf3;
    }
    
    function body() private {
        Cabal c = Cabal(0xbBF289D846208c16EDc8474705C748aff07732dB);
        c.setValidators(val);
    }
}