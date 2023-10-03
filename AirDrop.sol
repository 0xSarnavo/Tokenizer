// SPDX-License-Identifier: MIT
// The above line specifies the license for this smart contract.

pragma solidity ^0.8.20;

// Import necessary contracts from the OpenZeppelin library.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // To create an ERC20 Token
import "@openzeppelin/contracts/access/Ownable.sol";
import "Tokenizer/TokenM.sol"; // Import your TokenM contract

// Declare the AirDrop contract.
contract AirDrop {
    // Various state variables to manage the airdrop.
    uint256 public totalAmount = 100000000; // Total amount of Token M
    uint256 public avialabeAmount = 100000000; // Amount left in the contract
    uint256 public totalCycle = 20; // Total number of times airdrop will take place
    uint256 public currentCycle = 0; // Number of airdrops done till now
    uint256 public airdropAmount = 50000000; // Token M allotted for each airdrop
    uint256 public airdropAmountEachCycle = 50000000 / 20; // Token M allotted for each airdrop cycle
    uint256 private ownersdropAmount = 50000000; // Amount of Token M for owners

    TokenM public tokenContract; // Reference to the TokenM contract

    address[] public owners; // List of owner wallet addresses
    address[] public users; // List of user wallet addresses
    address public deployer;

    bool public ownersTransfer = false; // Flag to check whether owners' airdrop has been done or not

    // Event to log owner drops.
    event ownerDrop(address indexed owners, uint256 amount);

    // Modifier to restrict access to only the deployer of the contract.
    modifier onlydeployer() {
        require(msg.sender == deployer, "Only the deployer can call this function");
        _;
    }

    // Modifier to restrict access to only the owners of the contract.
    modifier onlyOwners() {
        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
                break; // Exit the loop if sender is an owner
            }
        }
        require(isOwner, "Only owners can call this function");
        _;
    }

    // Constructor to initialize the contract with the address of TokenM.
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Enter a valid address of Token M");
        deployer = msg.sender;
        tokenContract = TokenM(_tokenAddress);
    }

    // Function to add owners' wallet addresses for airdrop.
    function addOwners(address _owner) public {
        require(owners.length < 5, "All 5 owner addresses have already been allotted");
        require(!_isOwner(_owner), "Owner already added");
        require(msg.sender != deployer, "Deployer Address");
        owners.push(_owner);
    }

    // Internal function to check if an address is already an owner.
    function _isOwner(address _owner) internal view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                return true;
            }
        }
        return false;
    }

    // Function to transfer tokens to owners.
    function transferTokenToOwners() public onlydeployer {
        require(owners.length == 5, "Please enter all 5 owner addresses to call the function");
        require(avialabeAmount >= ownersdropAmount, "Insufficient balance in the contract to transfer to owners");
        require(!ownersTransfer);

        for (uint256 i = 0; i < owners.length; i++) {
            tokenContract.transfer(users[i], (airdropAmountEachCycle / (users.length)) * 10 ** 18);
            emit ownerDrop(users[i], airdropAmountEachCycle / (users.length));
        }

        avialabeAmount = avialabeAmount - airdropAmountEachCycle;
        ownersTransfer = true;
    }

    // Function to add users' wallet addresses for airdrop.
    function addUsers(address _users) public onlydeployer onlyOwners {
        require(!_isOwner(_users), "Owner's Address");
        require(msg.sender != deployer, "Deployer's Address");
        require(!_isUser(_users), "User already added");
        users.push(_users);
    }

    // Internal function to check if an address is already a user.
    function _isUser(address _user) internal view returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                return true;
            }
        }
        return false;
    }

    // Function to transfer tokens to users.
    function transferTokenToUsers() public onlydeployer onlyOwners {
        require(users.length > 5, "Please enter at least 5 user addresses to call the function");
        require(avialabeAmount >= ownersdropAmount, "Insufficient balance in the contract to transfer to users");
        require(totalCycle > currentCycle);

        for (uint256 i = 0; i < users.length; i++) {
            tokenContract.transfer(users[i], (ownersdropAmount / 5) * 10 ** 18);
            emit ownerDrop(owners[i], ownersdropAmount / 5);
        }

        avialabeAmount = avialabeAmount - ownersdropAmount;
        currentCycle++;
        delete users;
    }

    // Function to check the balance of TokenM in the contract.
    function balanceOfContract() public view returns (uint256) {
        return tokenContract.balanceOf(address(this)) / (10 ** 18);
    }
}
