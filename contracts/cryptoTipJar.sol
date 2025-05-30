// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // State variables
    address public owner;
    uint256 public totalTipsReceived;
    uint256 public totalTippers;
    
    // Mapping to track tips from each address
    mapping(address => uint256) public tipsByAddress;
    
    // Array to store all tippers (for iteration)
    address[] public tippers;
    
    // Events
    event TipReceived(address indexed tipper, uint256 amount, string message);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validTipAmount() {
        require(msg.value > 0, "Tip amount must be greater than 0");
        _;
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Send a tip with an optional message
     * @param _message Optional message from the tipper
     */
    function sendTip(string memory _message) external payable validTipAmount {
        // If this is the first tip from this address, add to tippers array
        if (tipsByAddress[msg.sender] == 0) {
            tippers.push(msg.sender);
            totalTippers++;
        }
        
        // Update tip tracking
        tipsByAddress[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        
        // Emit event
        emit TipReceived(msg.sender, msg.value, _message);
    }
    
    /**
     * @dev Core Function 2: Withdraw all accumulated tips (owner only)
     */
    function withdrawTips() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");
        
        // Transfer funds to owner
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(owner, contractBalance);
    }
    
    /**
     * @dev Core Function 3: Get tip jar statistics
     * @return contractBalance Current balance in the tip jar
     * @return totalTips Total amount of tips received
     * @return uniqueTippers Number of unique tippers
     */
    function getTipJarStats() external view returns (
        uint256 contractBalance,
        uint256 totalTips,
        uint256 uniqueTippers
    ) {
        return (
            address(this).balance,
            totalTipsReceived,
            totalTippers
        );
    }
    
    /**
     * @dev Get tip amount from a specific address
     * @param _tipper Address of the tipper
     * @return Amount tipped by the address
     */
    function getTipFromAddress(address _tipper) external view returns (uint256) {
        return tipsByAddress[_tipper];
    }
    
    /**
     * @dev Get all tippers (use with caution for large arrays)
     * @return Array of all tipper addresses
     */
    function getAllTippers() external view returns (address[] memory) {
        return tippers;
    }
    
    /**
     * @dev Transfer ownership of the tip jar
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different from current owner");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
    
    /**
     * @dev Emergency function to check contract balance
     * @return Current contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Fallback function to receive Ether
    receive() external payable {
        // Automatically treat any direct Ether transfer as a tip with empty message
        if (tipsByAddress[msg.sender] == 0) {
            tippers.push(msg.sender);
            totalTippers++;
        }
        
        tipsByAddress[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        
        emit TipReceived(msg.sender, msg.value, "Direct transfer");
    }
}
