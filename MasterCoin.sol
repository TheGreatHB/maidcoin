// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MasterCoinInterface.sol";
import "./MaidCoinInterface.sol";

contract MasterCoin is MasterCoinInterface {

    string constant private NAME = "MasterCoin";
    string constant private SYMBOL = "MASTER";
	uint8 constant private DECIMALS = 18;
    uint256 constant public COIN = 10 ** uint256(DECIMALS);
	uint256 constant private INITIAL_SUPPLY = 100 * COIN;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => mapping(uint256 => uint256[])) private burned;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) private minted;

	MaidCoinInterface public override maidCoin;

    struct MaidProposal {
		uint256 power;
        uint256 price;
        uint256 voteAmount;
        uint256 voteEndBlock;
	}
	MaidProposal[] public maidProposals;
    mapping(uint256 => mapping(address => bool)) public maidProposalVoted;

    struct NurseClassProposal {
		uint256 partsCount;
		uint256 destroyReturn;
		uint256 originPower;
        uint256 voteAmount;
        uint256 voteEndBlock;
	}
	NurseClassProposal[] public nurseClassProposals;
    mapping(uint256 => mapping(address => bool)) public nurseClassProposalVoted;

    struct NurseRaidProposal {
		uint256 entranceFee;
        uint256 nurseType;
        uint256 endBlock;
        uint256 voteAmount;
        uint256 voteEndBlock;
	}
	NurseRaidProposal[] public nurseRaidProposals;
    mapping(uint256 => mapping(address => bool)) public nurseRaidProposalVoted;

    constructor(address maidCoinAddr) {
		maidCoin = MaidCoinInterface(maidCoinAddr);
		balances[msg.sender] = INITIAL_SUPPLY;
		_totalSupply = INITIAL_SUPPLY;
	}

    function name() external pure override returns (string memory) { return NAME; }
    function symbol() external pure override returns (string memory) { return SYMBOL; }
    function decimals() external pure override returns (uint8) { return DECIMALS; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }

    function balanceOf(address user) external view override returns (uint256 balance) {
        return balances[user];
    }

    function transfer(address to, uint256 amount) public override returns (bool success) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address user, address spender) external view override returns (uint256 remaining) {
        return allowed[user][spender];
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool success) {
        uint256 _allowance = allowed[from][msg.sender];
        if (_allowance != type(uint256).max) {
            allowed[from][msg.sender] = _allowance - amount;
        }
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function claimCoinAmount() external override view returns (uint256) {
        //TODO: amount - maidCoin.initialSupply();
    }

    function claim() external override {
        //TODO: amount - maidCoin.initialSupply();
    }
}
