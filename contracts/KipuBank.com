// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title KipuBank.
/// @notice Allows users to deposit and withdraw ETH with restrictions.

contract KipuBank {
   
    uint256 public immutable bankCap;
    uint256 public immutable withdrawLimit;
    uint256 public totalBankBalance;
    uint256 public depositCount;
    uint256 public withdrawalCount;
    mapping(address => uint256) public vault;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
   
    error BankCapExceeded(uint256 attempted, uint256 maxCap);
    error WithdrawalLimitExceeded(uint256 attempted, uint256 limit);
    error InsufficientBalance(uint256 requested, uint256 available);
    error TransferFailed(address to, uint256 amount);

    constructor(uint256 _bankCap, uint256 _withdrawLimit) {
        bankCap = _bankCap;
        withdrawLimit = _withdrawLimit;
    }

   
    modifier hasFunds(uint256 amount) {
        if (vault[msg.sender] < amount) {
            revert InsufficientBalance(amount, vault[msg.sender]);
        }
        _;
    }

    function deposit() public payable {
        uint256 amount = msg.value;

        uint256 newTotal = totalBankBalance + amount;
        if (newTotal > bankCap) revert BankCapExceeded(newTotal, bankCap);

        vault[msg.sender] += amount;
        totalBankBalance = newTotal;
        unchecked {
            depositCount += 1;
        }

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external hasFunds(amount) {
        if (amount > withdrawLimit) revert WithdrawalLimitExceeded(amount, withdrawLimit);

        vault[msg.sender] -= amount;
        totalBankBalance -= amount;
        unchecked {
            withdrawalCount += 1;
        }

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getVaultBalance(address user) external view returns (uint256) {
        return vault[user];
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }
}
