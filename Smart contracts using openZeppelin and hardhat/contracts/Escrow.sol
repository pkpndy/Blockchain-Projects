// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint _id
    ) external;
}

contract Escrow {
    address public nftAddress;
    uint public nftId;
    uint public purchasePrice;
    uint public escrowAmount;
    address payable public seller;
    address payable public buyer;
    address public lender;
    address public inspector;

    bool public inspectionPassed = false;
    mapping (address=>bool) public approval;

    constructor(
        address _nftAddress,
        uint _nftId,
        uint _purchasePrice,
        uint _escrowAmount,
        address payable _seller,
        address payable _buyer,
        address _lender,
        address _inspector
    ) {
        nftAddress = _nftAddress;
        nftId = _nftId;
        purchasePrice = _purchasePrice;
        escrowAmount = _escrowAmount;
        seller = _seller;
        buyer = _buyer;
        lender = _lender;
        inspector = _inspector;
    }

    //only buyer modifier
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier onlyInspector() {
        require(
            msg.sender == inspector,
            "Only inspector can call this function"
        );
        _;
    }

    //this receive function makes the contract receive payments
    receive() external payable{}

    //passing the inspection
    function updateInspection(bool _inspection) public onlyInspector {
        inspectionPassed = _inspection;
    }

    //deposite earnest
    function depositEarnest() public payable onlyBuyer {
        require(msg.value >= escrowAmount);
    }

    //approves the transfer from whoever calls it
    function updateApproval() public {
        approval[msg.sender]=true;
    }

    //checks balance
    function getBalance() public view returns (uint) {
        //'this' refers to the smart contract itself
        return address(this).balance;
    }

    //transfer the ownership of the property
    function finalizeSale() public {
        require(inspectionPassed, "inspection needs to be passed");
        require(approval[buyer], 'buyer needs to approve');
        require(approval[seller],'seller needs to approve');
        require(approval[lender], 'lender needs to approve');

        require(address(this).balance >= purchasePrice, 'must have enough ether for sale');

        //payable called on an address sends the call to that address
        (bool success, ) = payable(seller).call{value: address(this).balance}("");
        require(success); 

        IERC721(nftAddress).transferFrom(seller, buyer, nftId);
    }
}
