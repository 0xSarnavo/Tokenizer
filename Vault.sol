// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary contracts from OpenZeppelin and other custom contracts.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "Tokenizer/TokenM.sol";
import "Tokenizer/CoinM.sol";
import "Tokenizer/MultiSig.sol";

contract Vault {
    // Various state variables to track the token and coin balances, allocations, and other parameters.
    uint256 public totalCoinM = 1000000;
    uint256 public availableCoinM = 1000000;
    uint256 public promoterCoinM = 250000;
    uint256 public investorCoinM = 10000;
    uint256 public investorCoinMAvailable  = 200000;
    uint256 public noOfInvestor = 25;
    bool public promoterAlloted = false;

    // Instances of imported contracts.
    TokenM         public tokenM;
    CoinM          public coinM;
    MultiSigWallet public multiSigWallet;

    // Arrays and addresses to store owners, deployer, and promoter.
    address[] public owners;
    address   public deployer;
    address   public promoter;

    // Mapping to track allotted tokens, lock times, deposited tokens, and exchanged tokens.
    mapping(address => uint256) public alloted;
    mapping(address => uint256) public lockTime;
    mapping(address => uint256) public exchangeLockTime;
    mapping(address => uint256) public tokenMDeposit;
    mapping(address => uint256) public totalExchanged;

    // Events to log important contract actions.
    event OwnerAdded(address indexed owner);
    event PromoterAlloted(address indexed promoter);
    event InvestorAlloted(address indexed promoter);
    event TokensDeposited(address indexed depositor, uint256 amount);
    event TokensWithdrawn(address indexed withdrawer, uint256 amount);
    event TokensExchanged(address indexed exchanger, uint256 amount);

    // Modifier to ensure that certain functions can only be called by owners after all owners are added.
    modifier onlyOwnersWhenAllAdded() {
        require(owners.length == 3, "All owners have not been added");
        require(_isOwner(msg.sender), "Only owners can call this function");
        _;
    }

    // Modifier to prevent reentrant calls.
    modifier preventReentrancy() {
        require(!inFunction, "Reentrant call");
        inFunction = true;
        _;
        inFunction = false;
    }

    bool private inFunction = false;

    // Constructor to initialize the contract with token and coin addresses.
    constructor(address _tokenM, address _coinM, address payable  _multiSigWallet) {
        require(_tokenM != address(0), "Enter a valid address of Token M");
        require(_coinM != address(0), "Enter a valid address of Coin M");
        deployer = msg.sender;
        tokenM = TokenM(_tokenM);
        coinM = CoinM(_coinM);
        multiSigWallet = MultiSigWallet(_multiSigWallet);
    }

    // Function to add owners. Can only be called by the deployer.
    function addOwners(address _owner) public preventReentrancy {
        require(msg.sender == deployer);
        require(owners.length < 3, "All 3 owner addresses have been allotted");
        require(!_isOwner(_owner), "Owner already added");
        require(_owner != deployer, "Deployer Address");
        owners.push(_owner);
        totalCoinM=totalCoinM-promoterCoinM;
        emit OwnerAdded(_owner);
    }

    // Function to allot a promoter. Can only be called by owners after all owners are added.
    function allotPromoter(address _promoterAddress) public onlyOwnersWhenAllAdded preventReentrancy {
        require(!_isOwner(_promoterAddress), "Owner's Address");
        require(_promoterAddress != deployer, "Deployer's Address");
        alloted[_promoterAddress] = promoterCoinM;
        lockTime[_promoterAddress] = block.timestamp + 730 days;
        promoterAlloted = true;
        totalCoinM=totalCoinM-investorCoinM;
        emit PromoterAlloted(_promoterAddress);
    }

    // Function to allot investors. Can only be called by owners after all owners are added.
    function allotInvestors(address _investorAddress) public onlyOwnersWhenAllAdded preventReentrancy {
        require(_investorAddress==deployer,"Deployer's Address");
        require(!_isOwner(_investorAddress), "Owner's Address");
        alloted[_investorAddress]=investorCoinM;
        lockTime[_investorAddress] = block.timestamp + 45 days;
        noOfInvestor = noOfInvestor-1;
        investorCoinMAvailable = investorCoinMAvailable - investorCoinM;
        multiSigWallet.submitTransaction(address(this), 0, "");
        emit InvestorAlloted(_investorAddress);
     } 

    // Function to deposit Token M into the contract.
    function depositTokenM(uint256 amount) public preventReentrancy {
        require(amount > 0, "Amount must be greater than zero");
        require(tokenM.transferFrom(msg.sender, address(this), amount), "TokenM transfer failed");
        tokenMDeposit[msg.sender] += amount;
        emit TokensDeposited(msg.sender, amount);
    }

    // Function to withdraw Token M from the contract.
    function withdrawTokenM() public preventReentrancy {
        require(tokenMDeposit[msg.sender] > 0, "The sender has no Token M deposited");
        uint256 amount = tokenMDeposit[msg.sender];
        tokenMDeposit[msg.sender] = 0;
        require(tokenM.transfer(msg.sender, amount), "Token M transfer failed");
        emit TokensWithdrawn(msg.sender, amount);
    }

    // Function to exchange tokens.
    function exchange(uint256 amount) public preventReentrancy {
        require(tokenMDeposit[msg.sender] > 0, "The sender has no Token M deposited");
        require(amount > 0 && amount <= 5000, "Amount should be between 1 and 5000");
        require(tokenMDeposit[msg.sender] >= amount * 100, "Not enough Token M deposited");
        require(block.timestamp >= exchangeLockTime[msg.sender], "Tokens are locked");
        require(totalExchanged[msg.sender] + amount <= 20000, "Total exchanged exceeds the limit");

        alloted[msg.sender] += amount;
        tokenMDeposit[msg.sender] -= amount * 100;
        exchangeLockTime[msg.sender] = block.timestamp + 10 days;
        totalExchanged[msg.sender] += amount;

        emit TokensExchanged(msg.sender, amount);
    }

    // Function to check the balance of Token M in the contract.
    function balanceOfTokenM() public view returns (uint256) {
        return tokenM.balanceOf(address(this)) / (10 ** 18);
    }

    // Function to check the balance of Coin M in the contract.
    function balanceOfCoinM() public view returns (uint256) {
        return coinM.balanceOf(address(this)) / (10 ** 18);
    }

    // Internal function to check if an address is an owner.
    function _isOwner(address _owner) internal view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                return true;
            }
        }
        return false;
    }
}
