// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";
//SafeMath protects us from overflow and common math errors
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//anybody to takes loan from this pool(smart contract) must implement this receiveTokens function
interface IReceiver {
    function receiveTokens(address tokenAddress, uint amount) external;
}

contract FlashLoan is ReentrancyGuard {
    using SafeMath for uint;

    Token public token;
    uint public poolBalance;

    constructor(address _tokenaddress) {
        token = Token(_tokenaddress);
    }

    //deposite the tokens from the person's wallet to flash loan
    //The person who is sending the tokens first need to approve
    function depositTokens(uint _amount) external nonReentrant {
        require(_amount > 0, "Must deposit atleast one token");
        //transFrom(from, to, value)
        token.transferFrom(msg.sender, address(this), _amount);
        poolBalance = poolBalance.add(_amount);
    }

    //the function for giving flash loan
    function flashLoan(uint _borrowAmount) external nonReentrant {
        require(_borrowAmount > 0, "must atleast borrow 1 token");

        uint balanceBefore = token.balanceOf(address(this));
        //check if there are required amount of tokens
        require(
            balanceBefore >= _borrowAmount,
            "Not enough tokens in the pool"
        );

        //check if the pool is working or not
        assert(poolBalance == balanceBefore);

        //send tokens to receiver but they need approval
        //transfer(to, amount)
        token.transfer(msg.sender, _borrowAmount);

        //getting back the money
        IReceiver(msg.sender).receiveTokens(address(token), _borrowAmount);

        //ensure we got the money
        uint balanceAfter = token.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }
}
