// SPDX-License-Identifier: MIT
// The above line specifies the license for this smart contract.

pragma solidity ^0.8.20;

// Importing necessary contracts from the OpenZeppelin library.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // To create an ERC20 Token
import "@openzeppelin/contracts/access/Ownable.sol";

// Declare the TokenM contract, inheriting from the ERC20 token contract.
contract TokenM is ERC20("TokenM", "M")
{
    // Public variable to track whether tokens have been minted.
    bool public minted = false;

    // Address of the deployer (the account that deploys this contract).
    address public deployer;

    // Constructor function that runs when the contract is deployed.
    constructor () 
    {
        // Set the deployer to the address that deployed this contract.
        deployer = msg.sender;
    }

    // Mint function to create new tokens and distribute them to an address.
    function mint(address _airdrop) public 
    {
        // Require that only the deployer can call this function.
        require(msg.sender == deployer, "Only the deployer can call this function.");
        
        // Require that tokens have not been minted before.
        require(!minted, "Tokens have already been minted.");

        // Mint 100 million tokens (with 18 decimals) to the specified _airdrop address.
        _mint(_airdrop, 100000000 * 10**18); // Mint 100 million tokens (with 18 decimals) to the specified address.

        // Mark tokens as minted to prevent further minting.
        minted = true;
    }
}
