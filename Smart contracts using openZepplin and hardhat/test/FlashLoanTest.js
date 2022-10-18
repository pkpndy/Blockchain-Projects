const { expect } = require('chai');
const { ethers } = require('hardhat');

const ether = (n) => {
    return ethers.utils.parseUnits(n.toString(), 'ether');
};

describe('FlashLoan', () => {
    let transaction, token, flashloan, flashloanReceiver;
    beforeEach(async () => {
        // Setup accounts
        const accounts = await ethers.getSigners();
        deployer = accounts[0];

        // Load accounts
        const FlashLoan = await ethers.getContractFactory('FlashLoan');
        const FlashLoanReceiver = await ethers.getContractFactory('FlashLoanReceiver');
        const Token = await ethers.getContractFactory('Token');

        //Deploy the token
        token = await Token.deploy('Prakash', 'PRK', 1000000)

        //Deploy FlashLoan
        flashloan = await FlashLoan.deploy(token.address);

        // Approve tokens without depositing
        transaction = await token.connect(deployer).approve(flashloan.address, ether(1000000));
        await transaction.wait();

        // Deploy flash loan receiver 
        flashloanReceiver = await FlashLoanReceiver.deploy(flashloan.address);

        // Deposit tokens
        transaction = await flashloan.connect(deployer).depositTokens(ether(1000000));
        await transaction.wait();
    })

    describe('Deployment', () => {
        it('sends token to flash loan pool contract', async () => {
            expect(await token.balanceOf(flashloan.address)).to.equal(ether(1000000));
        })
    })

    describe('Borrowing funds', () => {
        it('borrows funds from the pool', async () => {
            let amount = ether(100);
            let transaction = await flashloanReceiver.connect(deployer).executeFlashLoan(amount);
            let result = await transaction.wait();

            await expect(transaction).to.emit(flashloanReceiver, 'LoanReceived')
                .withArgs(token.address, amount);
        })
    })
})