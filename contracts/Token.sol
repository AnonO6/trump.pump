// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.28;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    // The devs of the website that will be creating the token
    address payable public owner; 
    // The user requesting the token creation
    address public creator;
    constructor(
        address _creator,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol){
        owner = payable(msg.sender);
        creator = _creator;

        _mint(msg.sender, _totalSupply);
    }
}