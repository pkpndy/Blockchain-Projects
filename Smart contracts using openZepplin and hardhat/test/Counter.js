const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Counter', () => {
    let counter;

    // beforeEach function basically runs before each test example runs
    beforeEach(async () => {
        // Fetch the contract
        let Counter = await ethers.getContractFactory('Counter');
        // Deploy the contract
        counter = await Counter.deploy('My Counter', 1);
    });

    describe('deployment', () => {
        it('sets the initial count', async () => {
            //Fetch the count then check the count
            //Step1=> Fetch the contract
            // const Counter = await ethers.getContractFactory('Counter');

            //Step2=>Deploy the contract
            //This deploy function takes arguments for the constructor function
            // const counter = await Counter.deploy('My Counter', 1);

            //Step3=>Bring the count function from the deployed contract 
            const count = await counter.count();

            //Step4=>Finally checking what we expect the count function to do after calling it once
            expect(count).to.equal(1);
        });

        it('sets the initial name', async () => {
            const name = await counter.name();
            expect(name).to.equal('My Counter');
        });
    });

    describe('operationals', () => {
        let transaction;
        it('checks increment', async () => {
            transaction = await counter.increment();
            await transaction.wait();
            let count = await counter.count();
            expect(count).to.equal(2);

            transaction = await counter.increment();
            await transaction.wait();
            count = await counter.count();
            expect(count).to.equal(3);
        })

        it('checks decrement', async () => {
            transaction = await counter.decrement();
            await transaction.wait();
            let count = await counter.count();
            expect(count).to.equal(0);

            //revert the transaction - exception handling
            //cannot decrement the count below zero
            await expect(counter.decrement()).to.be.reverted;
        })

        it('reads the "count" from the public variable', async () => {
            expect(await counter.count()).to.equal(1);
        })

        it('reads the "count" using getCount() function', async () => {
            expect(await counter.getCount()).to.equal(1);
        })

        it('updates the name using setName() function', async () => {
            transaction = await counter.setName('NewName');
            await transaction.wait();
            expect(await counter.getName()).to.equal('NewName');
        })
    });




});