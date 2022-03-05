// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract ERC20 {
    
    using SafeMath for uint256;
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    string public symbol;
    uint8 public decimals;
    string public  name;
    uint256 private _totalSupply;

    constructor(uint8 _decimals, string memory _symbol, string memory _name, uint256 _total_supply) public{
        decimals = _decimals;
        symbol = _symbol;
        name = _name;
        _totalSupply = _total_supply;
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }    

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function getSummary() public view returns(string memory,string memory, uint256) {
        return (symbol, name, _totalSupply);
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}




contract newERC20 is ERC20 {
    address public manager;


    constructor(uint8 decimals,string memory symbol,string memory name,uint256 initialSupply) public ERC20(decimals,symbol,name,initialSupply) {
        manager =msg.sender;
        }
        
    function getSummary2() public view returns(address) {
        return(manager);
    }
        
    
        
}

contract ERC20Factory {
    address[] tokenAddress;

    function deployCoin(uint8 decimals, string calldata symbol,string calldata name,uint256 initialSupply)external returns (newERC20 creditsAddress) {
        newERC20 newCoin = new newERC20(decimals,symbol,name,initialSupply);
        tokenAddress.push(address(newCoin));
        return newCoin;
    }

    function getDeployedCoin() public view returns (address[] memory) {
        return tokenAddress;
    }



    

}




