// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

//hardhat/console lets us write console log statements
import "hardhat/console.sol";
import "./FlashLoan.sol";

//This contract takes the flash loan
contract FlashLoanReceiver {
    FlashLoan private pool;
    address private owner;

    event LoanReceived(address token, uint amount);

    //we save the pool address
    constructor(address _poolAddress) {
        pool = FlashLoan(_poolAddress);
        owner = msg.sender;
    }

    //this receiveTokens is called by flashloan pool to get back it's tokens
    function receiveTokens(address _tokenAddress, uint _amount) external {
        //only the pool gets back the tokens back
        require(msg.sender == address(pool), "Sender must be pool");

        //require funds to be received
        require(
            Token(_tokenAddress).balanceOf(address(this)) == _amount,
            "failed to get loan"
        );

        //do the things you want
        console.log(
            "token balance of this address",
            Token(_tokenAddress).balanceOf(address(this))
        );

        //emit the event of loan received
        emit LoanReceived(_tokenAddress, _amount);

        //return funds to the pool
        require(
            Token(_tokenAddress).transfer(msg.sender, _amount),
            "Transfer of tokens failed"
        );
    }

    // the amount of flash loan we want
    function executeFlashLoan(uint _amount) external {
        //we don't want anyone else call this function on our behalf
        require(msg.sender == owner, "only owner can execute the flashLoan");
        // since pool has the flash loan address
        pool.flashLoan(_amount);
    }
}
