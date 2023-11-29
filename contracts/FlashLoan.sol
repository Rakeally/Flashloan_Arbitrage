// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

//FlashLoanSimpleReceiverBase implement this interface so our contract can be a receiver of a flash loan
//IPoolAddressesProvider ***
//IERC20 used to call the approved function on the token we're receiving

contract FlashLoan is FlashLoanSimpleReceiverBase {
    address public owner;

    constructor(
        address _addressProvider
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        owner = payable(msg.sender);
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
}
