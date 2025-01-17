// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.28;
import {Token} from "./Token.sol";

contract Factory {
    uint256 public constant TARGET= 3 ether;
    uint256 public constant TOKEN_LIMIT= 500_000 ether;
    
    uint256 public immutable fee;
    address public owner;

    uint256 public totalTokens;
    address[] public tokens;
    mapping(address => TokenSale) public tokenToSale;
    struct TokenSale {
        address token;
        string name;
        address creator;
        uint256 sold;   //This is total number of tokens sold, 1 token is 1 ether
        uint256 raised; //This is money raised by the contract in wei
        bool isOpen;
    }

    event Created(address indexed token);
    event Buy(address indexed token, uint256 amount);

    constructor(uint256 _fee) {
        fee= _fee;
        owner= msg.sender;
    }

    function getTokenSale(uint256 _index) public view returns (TokenSale memory) {
        return tokenToSale[tokens[_index]];
    }
    function create(string memory _name, string memory _symbol) external payable {
        //Make sure the fee is paid
        require(msg.value >= fee, "Factory: creator fee not met");
        // Create a new token
        Token token = new Token(msg.sender, _name, _symbol, 1_000_000 ether);

        // Save the token for later use
        tokens.push(address(token));
        totalTokens++;

        // List the token for sale
            // address token;
            // string name;
            // address creator;
            // uint256 sold;
            // uint256 raised;
            // bool isOpen;
        TokenSale memory sale= TokenSale(
            address(token),
            _name,
            msg.sender,
            0,
            0,
            true
        );

        tokenToSale[address(token)]= sale;

        // Tell people it's live
        emit Created(address(token));
    }
    function getCost(uint256 _sold) public pure returns(uint256) {
        uint256 floor = 0.0001 ether;
        uint256 step = 0.0001 ether;
        uint256 increment = 10000 ether;

        uint256 cost = (step * (_sold/increment)) + floor;
        return cost;
    }
    function buy(address _token, uint256 _amount) external payable {
        TokenSale storage sale= tokenToSale[_token];

        //Check conditions
        require(sale.isOpen == true, "Factory: Sale is not open");
        require(_amount >= 1 ether, "Factory: Amount is too low");
        require(_amount <= 10000 ether, "Factory: Amount exceeded");
        //Calculate the contract fee of 1 token based upon total bought
        uint256 cost = getCost(sale.sold);
        uint256 price= cost* (_amount / 10 ** 18);

        //Make sure enough eth are sent
        require(msg.value >= price, "Factory: Insufficient ETH received");

        //Update the sale
        sale.sold+= _amount;
        sale.raised+= price;

        //Make sure fund raising goal is not met
        if(sale.sold >= TOKEN_LIMIT || sale.raised >= TARGET){
            sale.isOpen = false;
        }

        //Transfer the tokens
        Token(_token).transfer(msg.sender, _amount);

        //Emit the purchase
        emit Buy(_token, _amount);

    }
    function deposit(address _token) external {
        // The remaining token balance and the ETH raised
        // Would go into a liquidity pool like Uniswap V3
        // For simplicity, I am just transferring remaining
        // Tokens and ETH raised to the creator

        Token token = Token(_token); // This is type casting 
        TokenSale memory sale = tokenToSale[_token];

        require(!sale.isOpen, "Factory: Target not reached yet");

        // Transfer leftover tokens to creator
        token.transfer(sale.creator, token.balanceOf(address(this)));

        // Transfer raised ETH to creator
        (bool success, ) = payable(sale.creator).call{value: sale.raised}("");
        require(success, "Factory: ETH Transfer failed");
    }
    //For the developer to withdraw the fee they have earned
    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "Factory: Not owner");

        (bool success, ) = payable(owner).call{value: _amount}("");
        require(success, "Factory: Fee withdrawal failed");
    }
}