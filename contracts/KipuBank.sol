// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title KipuBank gmoli
/// @notice A minimalistic vault that allows users to deposit and withdraw native ETH with certain limits.
/// @dev Implements best practices: custom errors, CEI pattern, reentrancy guard, and full NatSpec documentation.
contract KipuBank {
    /*//////////////////////////////////////////////////////////////
                            IMMUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The total maximum amount of ETH that can be deposited in the contract (in wei).
    uint256 public immutable bankCap;

    /// @notice The maximum amount a user can withdraw per transaction (in wei).
    uint256 public immutable withdrawLimit;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The current total ETH balance held by the contract (in wei).
    uint256 public totalBankBalance;

    /// @notice Total number of deposits made in the contract.
    uint256 public depositCount;

    /// @notice Total number of withdrawals made in the contract.
    uint256 public withdrawalCount;

    /// @notice Mapping of user addresses to their deposited ETH balance (in wei).
    mapping(address => uint256) public vault;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a user successfully deposits ETH.
    /// @param user The address of the depositor.
    /// @param amount The amount of ETH deposited (in wei).
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user successfully withdraws ETH.
    /// @param user The address of the withdrawing user.
    /// @param amount The amount of ETH withdrawn (in wei).
    event Withdrawn(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a deposit exceeds the total bank cap.
    /// @param attempted The total amount after the attempted deposit.
    /// @param maxCap The maximum allowed total balance.
    error BankCapExceeded(uint256 attempted, uint256 maxCap);

    /// @notice Thrown when a withdrawal exceeds the per-transaction limit.
    /// @param attempted The attempted withdrawal amount.
    /// @param limit The maximum allowed per withdrawal.
    error WithdrawalLimitExceeded(uint256 attempted, uint256 limit);

    /// @notice Thrown when a user tries to withdraw more than their vault balance.
    /// @param requested The requested withdrawal amount.
    /// @param available The user's available balance.
    error InsufficientBalance(uint256 requested, uint256 available);

    /// @notice Thrown when a low-level ETH transfer fails.
    /// @param to The address of the intended recipient.
    /// @param amount The amount of ETH that failed to transfer.
    error TransferFailed(address to, uint256 amount);

    /// @notice Thrown when a reentrant call is detected.
    error ReentrantCall();

    /*//////////////////////////////////////////////////////////////
                            REENTRANCY GUARD
    //////////////////////////////////////////////////////////////*/

    uint8 private _entered = 0;

    /// @notice Prevents reentrant function calls.
    modifier nonReentrant() {
        if (_entered == 1) revert ReentrantCall();
        _entered = 1;
        _;
        _entered = 0;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param _bankCap The maximum total ETH that can be deposited into the bank (in wei).
    /// @param _withdrawLimit The per-transaction withdrawal limit (in wei).
    constructor(uint256 _bankCap, uint256 _withdrawLimit) {
        bankCap = _bankCap;
        withdrawLimit = _withdrawLimit;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Ensures that the caller has at least `amount` of ETH in their vault.
    /// @param amount The minimum required balance (in wei).
    modifier hasFunds(uint256 amount) {
        if (vault[msg.sender] < amount) {
            revert InsufficientBalance(amount, vault[msg.sender]);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the caller to deposit ETH into their vault.
    /// @dev Follows the checks-effects-interactions pattern. Emits a {Deposited} event.
    function deposit() public payable {
        uint256 amount = msg.value;
        uint256 newTotal = totalBankBalance + amount;

        if (newTotal > bankCap) revert BankCapExceeded(newTotal, bankCap);

        // Effects
        vault[msg.sender] = vault[msg.sender] + amount;
        totalBankBalance = newTotal;
        depositCount = depositCount + 1;

        emit Deposited(msg.sender, amount);
    }

    /// @notice Allows the caller to withdraw ETH from their vault.
    /// @dev Uses the checks-effects-interactions pattern and reentrancy protection.
    /// @param amount The amount of ETH to withdraw (in wei).
    function withdraw(uint256 amount) external nonReentrant hasFunds(amount) {
        if (amount > withdrawLimit) revert WithdrawalLimitExceeded(amount, withdrawLimit);

  
        vault[msg.sender] = vault[msg.sender] - amount;
        totalBankBalance = totalBankBalance - amount;
        withdrawalCount = withdrawalCount + 1;

    
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Returns the current ETH balance for a given user.
    /// @param user The address to query.
    /// @return balance The user's current vault balance (in wei).
    function getVaultBalance(address user) external view returns (uint256 balance) {
        return vault[user];
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVE / FALLBACK
    //////////////////////////////////////////////////////////////*/

    /// @notice Handles plain ETH transfers and treats them as deposits.
    receive() external payable {
        deposit();
    }

    /// @notice Handles fallback calls and treats them as deposits.
    fallback() external payable {
        deposit();
    }
}
