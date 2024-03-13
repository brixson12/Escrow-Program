// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public owner;
    uint256 public releaseTime;
    mapping(address => uint256) public balances;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier afterReleaseTime() {
        require(block.timestamp >= releaseTime, "Timelock not expired");
        _;
    }

    modifier onlyDepositor() {
        require(balances[msg.sender] > 0, "Only depositors can call this function");
        _;
    }

    constructor(uint256 _releaseTime) {
        owner = msg.sender;
        releaseTime = _releaseTime;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner afterReleaseTime {
        payable(owner).transfer(address(this).balance);
        emit Withdrawal(owner, address(this).balance);
    }

    function withdrawAsDepositor() external onlyDepositor afterReleaseTime {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
}
