// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract TradeFinance is Ownable {
    // struct of parties & assets

    // Bank Structure
    struct bank {
        string name;
        address bankAddress;
    }

    // Sales Contract Structure
    // agreement between buyer and seller
    struct salesContract {
        string importer;
        string exporter;
        string issuingBank;
        string advisingBank;
        address issuingBankAddress;
        address advisingBankAddress;
        string commodity;
        string price;
        string paymentMethod;
        string additionalInfo;
        uint deadline; // expired time of this LC (timestamp)
    }

    // Letter of Credit Structure
    struct letterOfCredit {
        uint salesContractID;
        string invoiceHash;
        string billOfExchangeHash;
        string billOfLadingHash;
        string otherDocHash;
        string lcStatus;
        string startDate;
    }

    // manage parties quantity
    uint numOfBanks = 0;
    uint numOfSalesContracts = 0;
    uint numOfletterOfCredits = 0;

    // store parties
    mapping(uint => bank) banks;
    mapping(uint => salesContract) salesContracts;
    mapping(uint => letterOfCredit) letterOfCredits;

    // Events
    event SalesContractCreated(uint salesContractID);
    event LcCreated(uint lcID, uint salesContractID);
    event DocUploaded(uint lcID);

    //add bank to contract
    function addBank(
        string memory name,
        address bankAddress
    ) public returns (uint bankID) {
        bankID = numOfBanks++;
        bank storage newBank = banks[bankID];
        newBank.name = name;
        newBank.bankAddress = bankAddress;
    }

    function getAllBankAddress()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        address[] memory bankList = new address[](numOfBanks);
        for (uint i = 0; i < numOfBanks; i++) {
            bankList[i] = banks[i].bankAddress;
        }
        return bankList;
    }

    function getBank(
        uint id
    ) public view returns (address bankAddress, string memory name) {
        bankAddress = banks[id].bankAddress;
        name = banks[id].name;
    }

    // create an agreement between buyer and seller
    function createSalesContract(
        string memory importer,
        string memory exporter,
        string memory issuingBank,
        string memory advisingBank,
        address issuingBankAddress,
        address advisingBankAddress,
        string memory commodity,
        string memory price,
        string memory paymentMethod,
        string memory additionalInfo,
        uint deadline
    ) public returns (uint salesContractID) {
        require(
            msg.sender == issuingBankAddress,
            "Only issuing bank can create new salescontract on blockchain"
        );
        salesContractID = numOfSalesContracts++;
        salesContracts[salesContractID] = salesContract(
            importer,
            exporter,
            issuingBank,
            advisingBank,
            issuingBankAddress,
            advisingBankAddress,
            commodity,
            price,
            paymentMethod,
            additionalInfo,
            deadline
        );
        emit SalesContractCreated(salesContractID);
    }

    // buyer-bank create LC
    function createLC(
        uint salesContractID,
        string memory startDate
    ) public returns (uint lcID) {
        require(
            msg.sender == salesContracts[salesContractID].issuingBankAddress,
            "Only issuing bank can create a LC"
        );
        lcID = numOfletterOfCredits++;
        letterOfCredits[lcID] = letterOfCredit(
            salesContractID,
            "",
            "",
            "",
            "",
            "created",
            startDate
        );
        emit LcCreated(lcID, salesContractID);
    }

    function approveLC(uint lcID) public returns (bool sucess) {
        letterOfCredit storage lc = letterOfCredits[lcID];
        salesContract storage sc = salesContracts[lc.salesContractID];
        require(
            msg.sender == sc.advisingBankAddress,
            "Only advissing bank can change this LC status."
        );
        lc.lcStatus = "advising_bank_approved";
        return true;
    }

    function rejectLC(uint lcID) public returns (bool sucess) {
        letterOfCredit storage lc = letterOfCredits[lcID];
        salesContract storage sc = salesContracts[lc.salesContractID];
        require(
            msg.sender == sc.advisingBankAddress,
            "Only advissing bank can change this LC status."
        );
        lc.lcStatus = "advising_bank_rejected";
        return true;
    }

    // advising bank accept LC
    function changeLcStatus(
        uint lcID,
        string memory status
    ) public returns (bool success) {
        letterOfCredit storage lc = letterOfCredits[lcID];
        salesContract storage sc = salesContracts[lc.salesContractID];
        require(
            msg.sender == sc.advisingBankAddress,
            "Only advissing bank can change this LC status."
        );
        lc.lcStatus = status;
        return true;
    }

    function uploadDocument(
        uint lcID,
        string memory invoice,
        string memory exchange,
        string memory lading,
        string memory other
    ) public returns (bool success) {
        letterOfCredit storage lc = letterOfCredits[lcID];
        salesContract storage sc = salesContracts[lc.salesContractID];
        require(
            (msg.sender == sc.advisingBankAddress) ||
                (msg.sender == sc.issuingBankAddress),
            "Only bank can upload these document."
        );
        lc.invoiceHash = invoice;
        lc.billOfExchangeHash = exchange;
        lc.billOfLadingHash = lading;
        lc.otherDocHash = other;
        return true;
    }
}
