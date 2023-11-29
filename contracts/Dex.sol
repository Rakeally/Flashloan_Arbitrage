// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "hardhat/console.sol";

//Decentralize exchange
contract Dex {
    address public owner;
    IERC20 public usdcAddress;
    IERC20 public daiAddress;

    constructor(address _usdcAddress, address _daiAddress) {
        owner = msg.sender;
        usdcAddress = IERC20(_usdcAddress);
        daiAddress = IERC20(_daiAddress);
    }

    //conversion rate from usdc to dai
    uint public dexARate = 80;
    uint public dexBRate = 100;

    mapping(address => uint) public daiBalance;
    mapping(address => uint) public usdcBalance;

    function depositUsdc(uint _amount) external {
        console.log("sender: ", msg.sender);
        usdcBalance[msg.sender] += _amount;
        require(_amount > 0, "Amount must be greater than 0");
        uint allowance = usdcAddress.allowance(msg.sender, address(this));
        console.log("allowance: ", allowance);

        require(allowance >= _amount, "Insufficient allowance");
        bool s = usdcAddress.transferFrom(msg.sender, address(this), _amount);
        require(s);
    }

    function depositDAI(uint _amount) external {
        daiBalance[msg.sender] += _amount;
        require(_amount > 0, "Amount must be greater than 0");
        uint allowance = daiAddress.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");
        bool s = daiAddress.transferFrom(msg.sender, address(this), _amount);
        require(s);
    }

    function buyDai() external {
        console.log("buy sender: ", msg.sender);

        require(usdcBalance[msg.sender] > 0, "Insufficient balance");
        uint daiAmount = ((usdcBalance[msg.sender] / dexARate) * 100) *
            (10 ** 12);
        console.log("daiAmount: ", daiAmount);

        bool s = daiAddress.transfer(msg.sender, daiAmount);
        require(s);
    }

    function sellDAI() external {
        console.log("sell sender: ", msg.sender);

        require(daiBalance[msg.sender] > 0, "Insufficient balance");
        uint usdcToReceive = ((daiBalance[msg.sender] * dexBRate) / 100) /
            (10 ** 12);
        console.log("usdcToReceive: ", usdcToReceive);

        bool s = usdcAddress.transfer(msg.sender, usdcToReceive);
        require(s);
    }

    function getBalance(address _tokenAddress) external view returns (uint) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}
