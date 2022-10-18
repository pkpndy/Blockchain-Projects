// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

    function depositTokens(uint _amount) external nonReentrant {
        require(_amount > 0, "Must deposit atleast one token");
        //transFrom(from, to, value)
        token.transferFrom(msg.sender, address(this), _amount);
        poolBalance = poolBalance.add(_amount);
    }

    function flashLoan(uint _borrowAmount) external nonReentrant {
        require(_borrowAmount > 0, "must atleast borrow 1 token");

        uint balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= _borrowAmount, "Not enough tokens in pool");

        assert(poolBalance == balanceBefore);

        //send tokens to receiver
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
