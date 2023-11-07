// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoC is Ownable {
    // struct of parties & assets

    // Sales Contract Structure
    // agreement between buyer and seller
    struct salesContract {
        uint id;
        string importer;
        string exporter;
        string issuingBank;
        string advisingBank;
        string commodity;
        string price;
        string paymentMethod;
        string additionalInfo;
        uint deadline; // expired time of this LC (timestamp)
    }

    // Letter of Credit Structure
    struct letterOfCredit {
        uint id;
        uint salesContractID;
        string invoiceHash;
        string billOfExchangeHash;
        string billOfLadingHash;
        string otherDocHash;
        string lcStatus;
        string startDate;
    }

    // manage parties quantity
    uint numOfSalesContracts = 0;
    uint numOfletterOfCredits = 0;

    // store parties
    mapping(uint => salesContract) salesContracts;
    mapping(uint => letterOfCredit) letterOfCredits;

    // Events
    event SalesContractCreated(
        uint salesContractID, string importer, 
        string exporter, string issuingBank, string advisingBank, 
        string commodity, string price, string paymentMethod, 
        string additionalInfo, uint deadline
    );
    event LcCreated(
        uint lcID, uint salesContractID, string invoiceHash, 
        string billOfExchangeHash, string billOfLadingHash, 
        string otherDocHash, string lcStatus, string startDate
    );
    event LcApproved(uint lcID);
    event LcRejected(uint lcID);
    event LcStatusChanged(uint lcID, string status);
    event DocUploaded(uint lcID, string invoice, string BoE, string BoL, string other);

    // create an agreement between buyer and seller
    function createSalesContract(
        string memory importer,
        string memory exporter,
        string memory issuingBank,
        string memory advisingBank,
        string memory commodity,
        string memory price,
        string memory paymentMethod,
        string memory additionalInfo,
        uint deadline
    ) public returns (uint salesContractID) {
        salesContractID = numOfSalesContracts++;
        salesContracts[salesContractID] = salesContract(
            salesContractID,
            importer,
            exporter,
            issuingBank,
            advisingBank,
            commodity,
            price,
            paymentMethod,
            additionalInfo,
            deadline
        );
        emit SalesContractCreated(
            salesContractID, importer, exporter, issuingBank, 
            advisingBank, commodity, price, paymentMethod, 
            additionalInfo, deadline
        );
    }

    // buyer-bank create LC
    function createLC(
        uint salesContractID,
        string memory startDate
    ) public returns (uint lcID) {
        lcID = numOfletterOfCredits++;
        letterOfCredits[lcID] = letterOfCredit(
            lcID,
            salesContractID,
            "",
            "",
            "",
            "",
            "created",
            startDate
        );
        emit LcCreated(lcID, salesContractID, "", "", "", "", "created", startDate);
    }

    function approveLC(uint lcID) public returns (bool sucess) {
        letterOfCredit storage lc = letterOfCredits[lcID];
        lc.lcStatus = "advising_bank_approved";
        emit LcApproved(lcID);
        return true;
    }

    function rejectLC(uint lcID) public returns (bool sucess) {
        letterOfCredit storage lc = letterOfCredits[lcID];
        lc.lcStatus = "advising_bank_rejected";
        emit LcRejected(lcID);
        return true;
    }

    // advising bank accept LC
    function changeLcStatus(
        uint lcID,
        string memory status
    ) public returns (bool success) {
        letterOfCredit storage lc = letterOfCredits[lcID];
        lc.lcStatus = status;
        emit LcStatusChanged(lcID, lc.lcStatus);
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
        lc.invoiceHash = invoice;
        lc.billOfExchangeHash = exchange;
        lc.billOfLadingHash = lading;
        lc.otherDocHash = other;
        emit DocUploaded(lcID, invoice, exchange, lading, other);
        return true;
    }
}
