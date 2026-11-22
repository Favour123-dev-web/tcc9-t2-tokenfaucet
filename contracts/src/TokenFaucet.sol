// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TokenFaucet
/// @notice Simple faucet that lets users claim a fixed amount of ERC20 tokens
/// @dev Faucet must be funded with tokens before users can claim
contract TokenFaucet {
    IERC20 public immutable token;
    address public owner;

    uint256 public dripAmount;
    uint256 public cooldown;

    mapping(address => uint256) public lastClaimedAt;

    event Claimed(address indexed user, uint256 amount);
    event Funded(address indexed funder, uint256 amount);
    event DripAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event CooldownUpdated(uint256 oldCooldown, uint256 newCooldown);
    event Withdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token, uint256 _dripAmount, uint256 _cooldown) {
        require(_token != address(0), "Zero token address");
        token = IERC20(_token);
        owner = msg.sender;
        dripAmount = _dripAmount;
        cooldown = _cooldown;
    }

    function claim() external {
        require(dripAmount > 0, "Drip amount is zero");
        require(
            block.timestamp >= lastClaimedAt[msg.sender] + cooldown,
            "Cooldown: wait before next claim"
        );
        require(
            token.balanceOf(address(this)) >= dripAmount,
            "Faucet is empty"
        );

        lastClaimedAt[msg.sender] = block.timestamp;

        require(token.transfer(msg.sender, dripAmount), "Transfer failed");

        emit Claimed(msg.sender, dripAmount);
    }

    function fund(uint256 amount) external {
        require(amount > 0, "Amount is zero");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Funding failed"
        );
        emit Funded(msg.sender, amount);
    }

    function setDripAmount(uint256 _newAmount) external onlyOwner {
        uint256 oldAmount = dripAmount;
        dripAmount = _newAmount;
        emit DripAmountUpdated(oldAmount, _newAmount);
    }

    function setCooldown(uint256 _newCooldown) external onlyOwner {
        uint256 oldCooldown = cooldown;
        cooldown = _newCooldown;
        emit CooldownUpdated(oldCooldown, _newCooldown);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount is zero");
        require(token.transfer(owner, amount), "Withdraw failed");
        emit Withdrawn(owner, amount);
    }

    function faucetBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function canClaim(address user) external view returns (bool) {
        if (dripAmount == 0) return false;
        if (token.balanceOf(address(this)) < dripAmount) return false;
        return block.timestamp >= lastClaimedAt[user] + cooldown;
    }
}
