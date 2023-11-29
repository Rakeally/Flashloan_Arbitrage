// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "hardhat/console.sol";

//FlashLoanSimpleReceiverBase implement this interface so our contract can be a receiver of a flash loan
//IPoolAddressesProvider ***
//IERC20 used to call the approved function on the token we're receiving

interface IDex {
    function depositUsdc(uint _amount) external;

    function depositDAI(uint _amount) external;

    function buyDai() external;

    function sellDAI() external;
}

contract FlashLoanArbitrage is FlashLoanSimpleReceiverBase {
    address public owner;
    IERC20 private daiAddress;
    IERC20 private usdcAddress;
    IDex private dexContract;
    address private dexContractAddress;

    constructor(
        address _addressProvider,
        address _daiAddress,
        address _usdcAddress,
        address _dexContract
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        owner = payable(msg.sender);
        daiAddress = IERC20(_daiAddress);
        usdcAddress = IERC20(_usdcAddress);
        dexContract = IDex(_dexContract);
        dexContractAddress = _dexContract;
    }

    function executeOperation(
        address asset, //asset being borrowed ERC20
        uint amount, // amount of asset borrowed
        uint premuim, // fee for asset
        address initiator, //who initiated the operation
        bytes calldata params
    ) external override returns (bool) {
        //we have the borrowed funds
        //custom login
        dexContract.depositUsdc(1000000000);
        dexContract.buyDai();
        dexContract.depositDAI(daiAddress.balanceOf(address(this)));
        dexContract.sellDAI();

        uint amountOwned = amount + premuim;
        IERC20(asset).approve(address(POOL), amountOwned);

        return true;
    }

    function requestFlashLoan(address _token, uint _amount) public {
        address receiverAddress = address(this);
        address asset = _token;
        uint amount = _amount;
        bytes memory params = "";
        uint16 referalCode = 0;
        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referalCode
        );
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
            "Only contract owner can call this function"
        );
        _;
    }

    receive() external payable {}

    function approveUSDC(uint _amount) external {
        usdcAddress.approve(dexContractAddress, _amount);
    }

    function approveDAI(uint _amount) external {
        daiAddress.approve(dexContractAddress, _amount);
    }

    function allowanceUSDC() external view returns (uint) {
        return usdcAddress.allowance(address(this), dexContractAddress);
    }

    function allowanceDAI() external view returns (uint) {
        return daiAddress.allowance(address(this), dexContractAddress);
    }
}

//USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8
//DAI = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357
//DEX = 0xe3f51f343B29664A87899D4D98beaC3ae290d85b
//FLA = 0xD257B3a882c2DE0aF71de315dcA423484490B21B
