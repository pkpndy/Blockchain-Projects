// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

//hardhat/console lets us write console log statements
import "hardhat/console.sol";
import "./FlashLoan.sol";

contract FlashLoanReceiver {
    FlashLoan private pool;
    address private owner;

    event LoanReceived(address token, uint amount);

    constructor(address _poolAddress) {
        pool = FlashLoan(_poolAddress);
        owner = msg.sender;
    }

    function receiveTokens(address _tokenAddress, uint _amount) external {
        require(msg.sender == address(pool), "Sender must be pool");
        //require funds to be received
        require(
            Token(_tokenAddress).balanceOf(address(this)) == _amount,
            "failed to get loan"
        );

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

    function executeFlashLoan(uint _amount) external {
        require(msg.sender == owner, "only owner can execute the flashLoan");
        pool.flashLoan(_amount);
    }
}
