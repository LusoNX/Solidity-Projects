pragma solidity ^0.6.0;


contract OptionExchangeFactory {
    address[] deployedOptions;
    
    function deployOption(
        //address _payToken,
        address _sellToken,
        //address _tokenFeed
        string memory sellTokenSymbol
        //string memory buyTokenSymbol
        ) public {
        OptionExchange newOption = new OptionExchange(msg.sender,0xD92E713d051C37EbB2561803a3b5FBAbc4962431,_sellToken,sellTokenSymbol,"USDT");
        deployedOptions.push(address(newOption));
    }
    
        
    function getDeployedOptions() public view returns(address[] memory) {
        return deployedOptions;
    }
    
}


//TEHTER 0xd92e713d051c37ebb2561803a3b5fbabc4962431
// DROGO: 0x19AE1748278EF399c18188b7F06e3AD66D895716
//LINK :0x01BE23585060835E02B77ef475b0Cc51aA1e0709
//LINK TOKEN FEED:0x6292aA9a6650aE14fbf974E5029f36F95a1848Fd

contract OptionExchange {
    using SafeMath for uint;

    //AggregatorV3Interface internal linkFeed;
    bytes32 sellHash;
    bytes32 buyHash;
    
    LinkTokenInterface internal payToken;
    LinkTokenInterface internal sellToken;

    address public payTokenAddress;
    address public sellTokenAddress;
    
    string public sellTokenSymbol;
    string public buyTokenSymbol;

    address public owner;
    uint public exerciseVal;
    
    address payable contractAddress;
    
    //Option saved into a struct
    
    struct option {
        uint strike; //Price in USD (18 decimal places) option allows buyer to purchase tokens at
        uint premium; //Fee in contract token that option writer charges
        uint expiry; //Unix timestamp of expiration time
        uint amount; //Amount of tokens the option contract is for
        bool exercised; //Has option been exercised
        bool canceled; //Has option been canceled
        //uint id; //Unique ID of option, also array index
        address payable writer; //Issuer of option
        address payable buyer; //Buyer of option
    }
    
    option public TokenOpts;
    
    enum State {Deployed, Available,Sold}
    State public OptionState;
    
    //constructor(address payToken, address sellToken) public {
    constructor(
        address _owner,
        address _payTokenAddress,
        address _sellTokenAddress,
        string memory _sellTokenSymbol,
        string memory _buyTokenSymbol
        ) public {
            OptionState = State.Deployed;
            owner = _owner;
            payTokenAddress = _payTokenAddress;
            sellTokenAddress = _sellTokenAddress;
            sellTokenSymbol = _sellTokenSymbol;
            buyTokenSymbol = _buyTokenSymbol;
            sellHash = keccak256(abi.encodePacked(sellTokenSymbol));
            buyHash = keccak256(abi.encodePacked(buyTokenSymbol));
            //TokenFeed = AggregatorV3Interface(_tokenFeed);
            payToken = LinkTokenInterface(payTokenAddress);
            sellToken = LinkTokenInterface(sellTokenAddress);
        
            contractAddress = payable(address(this));

    }
    
    //function OptionContract() {}
    
    modifier onlyOwner()  {
        require(msg.sender== owner);
        _;
    }

 
    // Write the call option
    
    function writeOption( uint strike, uint premium, uint expiry, uint tokenAmount) public onlyOwner payable {
        require(OptionState == State.Deployed);
        uint tokenDecimals = sellToken.decimals();
        require(sellToken.transfer(contractAddress,tokenAmount.mul(10**tokenDecimals)),"Incorrect Amount of Token supplied"); // In this alternative you need to use the instructions in this website "https://blog.chain.link/defi-call-option-exchange-in-solidity/"
        uint buyTokenDecimals = payToken.decimals();
        TokenOpts = option(strike.mul(10**buyTokenDecimals), premium.mul(10**buyTokenDecimals), expiry, tokenAmount.mul(10**tokenDecimals), false, false, msg.sender, address(0));
        OptionState = State.Available;
    }
    
    // Purchase a call option
    
    function buyOption() public payable {
        require(OptionState ==State.Available);
        require(payToken.transferFrom(msg.sender,owner, TokenOpts.premium), "Incorrect amount of USDT sent for premium");
        TokenOpts.buyer = msg.sender;
        OptionState = State.Sold;
        
    }
    

    // Exercising the option
    
    function exercise() public payable {
        require(OptionState == State.Sold);
        require(TokenOpts.buyer == msg.sender,"You are not the owner of the Option");
        require(!TokenOpts.exercised, "Option already exercised expired");
        require(TokenOpts.expiry >now,"Option has expired");
        uint selltokenDecimals = sellToken.decimals();
        uint buyTokenDecimals = payToken.decimals();
        exerciseVal = TokenOpts.strike*TokenOpts.amount/(10**selltokenDecimals);
        
        //require(sellToken.transferFrom(msg.sender,TokenOpts.writer, exerciseVal); "Incorrect LINK amount sent to exercise");
        require(payToken.transferFrom(msg.sender,contractAddress, TokenOpts.strike), "Error: buyer has not paid");
        sellToken.transferFrom(contractAddress,msg.sender,exerciseVal);
        payToken.transferFrom(contractAddress,owner,TokenOpts.strike);
        
        TokenOpts.exercised = true;   
    }


    function getSummary() public view returns(address,address,address,string memory,string memory) {
        return(sellTokenAddress,payTokenAddress,owner,buyTokenSymbol,sellTokenSymbol);
    }
    
    function getShowSummary() public view returns(State,uint,uint,uint,uint,bool,bool,address, address,uint) {
        return(
            
            OptionState,
            TokenOpts.strike,
            TokenOpts.premium,
            TokenOpts.expiry,
            TokenOpts.amount,
            TokenOpts.exercised,
            TokenOpts.canceled,
            TokenOpts.writer,
            TokenOpts.buyer,
            exerciseVal);
            

    }

} 


interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



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


