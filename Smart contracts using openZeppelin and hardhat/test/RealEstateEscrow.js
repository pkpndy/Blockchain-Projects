const { expect } = require('chai');
const { ethers } = require('hardhat');

const ether = (n) => {
    return ethers.utils.parseUnits(n.toString(), 'ether');
};

describe('RealEstateEscrow', () => {
    let buyer, seller;
    let realEstate, escrow;
    let lender, inspector;
    let nftId = 1;
    let pricePayable = ether(100);
    let earnestAmount = ether(20);
    beforeEach(async () => {
        //setup accouonts
        let accounts = await ethers.getSigners();
        let deployer = accounts[0];
        buyer = accounts[1];
        seller = deployer;
        lender = accounts[2];
        inspector = accounts[3];

        //Load the contracts
        const Escrow = await ethers.getContractFactory('Escrow');
        const RealEstateNFT = await ethers.getContractFactory('RealEstate');

        //Deploying the contracts
        realEstate = await RealEstateNFT.deploy();
        escrow = await Escrow.deploy(
            realEstate.address,
            nftId,
            pricePayable,
            earnestAmount,
            seller.address,
            buyer.address,
            lender.address,
            inspector.address
        );

        //seller approves as approval is needed from the very begining
        let transaction = await realEstate.connect(seller).approve(escrow.address, nftId);
        await transaction.wait();
    })
    describe('Deployment', async () => {
        it('sends an NFT to the seller', async () => {
            expect(await realEstate.ownerOf(nftId)).to.equal(seller.address);
        })
    })

    describe('Selling real estate', async () => {
        let transaction, balance;
        //Expects the seller to be owner before sale
        it('expects a successful transaction', async () => {
            expect(await realEstate.ownerOf(nftId)).to.equal(seller.address);

            //buyer deposits earnest
            transaction = await escrow.connect(buyer).depositEarnest({ value: earnestAmount });

            //check escrow balance 
            balance = await escrow.getBalance();
            console.log("escrow balance", ethers.utils.formatEther(balance));

            //passing the inspection
            transaction = await escrow.connect(inspector).updateInspection(true);
            await transaction.wait();
            console.log('Inspection passed');

            //approval by buyer
            transaction = await escrow.connect(buyer).updateApproval();
            await transaction.wait();
            console.log('buyer approves sale');

            //approval by seller
            transaction = await escrow.connect(seller).updateApproval();
            await transaction.wait();
            console.log('seller approves sale');

            //approval by lender
            transaction = await escrow.connect(lender).updateApproval();
            await transaction.wait();
            console.log('lender approves sale');

            //lender funds the escrow
            transaction = await lender.sendTransaction({ to: escrow.address, value: ether(80) });
            console.log('lender funds the escrow');

            //finalizeSale
            // contractName.connect connects the smart contract to that address
            transaction = await escrow.connect(buyer).finalizeSale();
            await transaction.wait();
            console.log("Buyer finalizes the sale");

            //check seller balance
            balance = await ethers.provider.getBalance(seller.address);
            console.log("seller balance", ethers.utils.formatEther(balance));
            expect(balance).to.be.above(ether(10099));

            //check escrow balance 
            balance = await escrow.getBalance();
            console.log("escrow balance", ethers.utils.formatEther(balance));

            //Expects the buyer to the owner after the sale
            expect(await realEstate.ownerOf(nftId)).to.equal(buyer.address);
        })

    })
})