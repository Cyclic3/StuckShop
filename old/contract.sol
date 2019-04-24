pragma solidity ^0.5.0;

import 'github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol';
import 'github.com/OpenZeppelin/zeppelin-solidity/contracts/access/Roles.sol';
import './balance_sheet.sol';
// Large poritions of this are shameless stolen from OpenZeppelin

contract YeeterRole {
    using Roles for Roles.Role;
    event YeeterAdded(address indexed account);
    event YeeterRemoved(address indexed account);
    
    Roles.Role private _yeeters;
    
    constructor () internal {
        _addYeeter(msg.sender);
    }
    
    modifier onlyYeeter() {
        require(isYeeter(msg.sender));
        _;
    }

    function isYeeter(address account) public view returns (bool) {
        return _yeeters.has(account);
    }

    function addYeeter(address account) public onlyYeeter {
        _addYeeter(account);
    }

    function renounceYeeter() public {
        _removeYeeter(msg.sender);
    }

    function _addYeeter(address account) internal {
        _yeeters.add(account);
        emit YeeterAdded(account);
    }

    function _removeYeeter(address account) internal {
        _yeeters.remove(account);
        emit YeeterRemoved(account);
    }
}

/**
 * @title Yeetable
 * @dev A command-economy token which can be controlled by a cabal
 */
contract AnnCoin is YeeterRole {
    using SafeMath for uint256;
    
    string public constant name = "AnnCoin";
    string public constant symbol = "ATS";
    uint8 public constant decimals = 2;
    
    uint256 private _totalSupply;
    
    BalanceSheet.itmap private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    function _transfer(address src, address dst, uint256 value) private {
        require(src != address(0));
        
        // Will throw on underflow
        BalanceSheet.insert(_balances, src, SafeMath.sub(balanceOf(src), value));
        // Check for burn
        if (dst != address(0)) {
            BalanceSheet.insert(_balances, dst, SafeMath.add(balanceOf(dst), value));
        }
        else {
           _totalSupply = SafeMath.sub(_totalSupply, value);
        }
        if (balanceOf(src) == 0) {
            BalanceSheet.remove(_balances, src);
        }
        emit Transfer(src, dst, value);
    }
    
    //
    // Yeeter-only functions
    //
    
    function mint(uint value) public onlyYeeter{
        BalanceSheet.insert(_balances, msg.sender, SafeMath.add(balanceOf(msg.sender), value));
        
        _totalSupply = SafeMath.add(_totalSupply, value);
        
        emit Transfer(address(0), msg.sender, value);
    }
    
    function burn(address target, uint256 amount) onlyYeeter public {
        _transfer(target, address(0), amount);
    }
    function steal(address target, uint256 amount) onlyYeeter public {
        _transfer(target, msg.sender, amount);
    }
    function yeet() onlyYeeter public {
        for (uint i = BalanceSheet.iterate_start(_balances); 
             BalanceSheet.iterate_valid(_balances, i); 
             i = BalanceSheet.iterate_next(_balances, i)) 
        {
            (address key, uint256 value) = BalanceSheet.iterate_get(_balances, i);
            // Is this ok?
            burn(key, value);
        }
    }
    function kill() onlyYeeter public { selfdestruct(msg.sender); }
    function _approve(address src, address dst, uint256 new_value) public {
        // Stopping people messing with known elephant 0
        require(src != address(0));
        require(dst != address(0));
        
        _allowed[src][dst] = new_value;
        emit Approval(src, dst, new_value);
    }
    constructor() public {}
    
    //
    // ERC20 interface
    //
    
    function totalSupply() public view returns (uint) { return _totalSupply; }

    function balanceOf(address who) view public returns (uint256) {
        return BalanceSheet.get(_balances, who);
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }

    function approve(address dst, uint tokens) public returns (bool success) {
        _approve(msg.sender, dst, tokens);
        return true;
    }

    function transferFrom(address src, address dst, uint tokens) public returns (bool success) {
        // Will be reverted on failure
        _transfer(src, dst, tokens);
        _approve(src, msg.sender, SafeMath.sub(_allowed[src][dst], tokens));
        return true;
    }

    function transfer(address to, uint value) public {
        _transfer(msg.sender, to, value);
    }
    
    //
    // Some extra useful ERC20 functions
    //
    function increaseAllowance(address dst, uint256 value) public returns (bool) {
        _approve(msg.sender, dst, _allowed[msg.sender][dst].add(value));
        return true;
    }
    function decreaseAllowance(address dst, uint256 value) public returns (bool) {
        _approve(msg.sender, dst, _allowed[msg.sender][dst].sub(value));
        return true;
    }
}
