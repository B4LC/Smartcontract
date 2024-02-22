//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AccessControl} from "@openzepplin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TradeFinance is AccessControl, IERC20 {
    bytes32 public constant IMPORTER_ROLE = keccak256("IMPORTER_ROLE");
    bytes32 public constant EXPORTER_ROLE = keccak256("EXPORTER_ROLE");
    bytes32 public constant ISSUING_BANK_ROLE = keccak256("ISSUING_BANK_ROLE");
    bytes32 public constant ADVISING_BANK_ROLE = keccak256("ADVISING_BANK_ROLE");
    address private factory;

    struct Commodity {
        string description;
        string quantity;
        uint unit;
    }

    struct ShipmentInformation {
        string from;
        string to;
        bool partialShipment; // true for permitted, false for prohibited
        bool transhipment; // true for permitted, false for prohibited
        uint latestShipmentDate;
    }

    address importer;
    address exporter;
    address issuingBank;
    address advisingBank;
    Commodity[] commodity;
    string price;
    string paymentMethod;
    string additionalInfo;
    uint deadline;
    string status;
    string documentHash;
    ShipmentInformation[] shipmentInformation;
    bool private activate;

    enum LetterOfCreditStatus {
        CREATED, 
        ADVISING_BANK_APPROVED,
        ADVISING_BANK_REJECTED,
        FUND_ESCROWED,
        FUND_PAID,
        FUND_REFUNDED,
        DOCUMENT_UPLOADED,
        PAUSED,
        ENDED
    }

    constructor(address importer, address exporter, address issuingBank, address advisingBank) {
        _grantRole(IMPORTER_ROLE, importer);
        _grantRole(EXPORTER_ROLE, exporter);
        _grantRole(ISSUING_BANK_ROLE, issuingBank);
        _grantRole(ADVISING_BANK_ROLE, advisingBank);
    }

    function approveLetterOfCredit() public onlyRole(ADVISING_BANK_ROLE) returns (bool success) {
        status = LetterOfCreditStatus.ADVISING_BANK_APPROVED;
        return success;
    }

    function rejectLetterOfCredit() public onlyRole(ADVISING_BANK_ROLE) returns (bool success) {
        status = LetterOfCreditStatus.ADVISING_BANK_REJECTED;
        return success;
    }

    function uploadDocument(string docHash) public onlyRole(ISSUING_BANK_ROLE) returns (bool success) {
        documentHash = docHash;
        return success;
    }

    function escrowFund() public payable onlyRole(IMPORTER_ROLE) returns (bool success) {
        transfer(this, msg.value);
        Transfer(importer, this, msg.value);
        return success;
    }

    function refundFund() public payable onlyRole(ISSUING_BANK_ROLE) returns (bool success) {
        transfer(importer, msg.value);
        Transfer(this, importer, msg.value);
        return success;
    }

    function payFund() public payable onlyRole(ISSUING_BANK_ROLE) returns (bool success) {
        transfer(exporter, msg.value);
        Transfer(this, exporter, msg.value);
        return success;
    }

    function deactivateLC() public onlyRole(ISSUING_BANK_ROLE) {
        activate = true;
    }

    function activateLC() public onlyRole(ISSUING_BANK_ROLE) {
        activate = false;
    }

    function getAllEntities() public {
        return (
            importer,
            exporter,
            issuingBank,
            advisingBank
        );
    }
}
