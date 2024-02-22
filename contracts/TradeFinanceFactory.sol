//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./TradeFinanceContract.sol";
import {Ownable} from "@openzepplin/contracts/access/Ownable.sol";

contract TradeFinanceFactory is Ownable {
    mapping(address => TradeFinance) private listTradeFinance;
    struct LetterOfCredit {
        address importer;
        address exporter;
        address issuingBank;
        address advisingBank;
        string commodity;
        string price;
        string paymentMethod;
        string additionalInfo;
        uint deadline;
        string status;
    }
    constructor() {
        transferOwnership(msg.sender);
    }
    event CreateLetterOfCredit(address );
    event ApproveLetterOfCredit();
    event RejectLetterOfCredit();
    event DocumentUploaded();
    event DeactiveLC();
    event ActivateLC();
    event FundEscrowed();
    event FundPaid();
    event FundRefunded();

    function createLetterOfCredit(LetterOfCredit newLC) external onlyOwner returns (address) {
        require();
        TradeFinance newTradeFinance = new TradeFinance(newLC.issuingBank);
        listTradeFinance[address(newTradeFinance)] = newTradeFinance;
        emit CreateLetterOfCredit();
        return address(newTradeFinance);
    }
    function approveLetterOfCredit(address letterOfCreditAddress) public {
        require();
        TradeFinance LCEntity = listTradeFinance[letterOfCreditAddress];
        LCEntity.approveLetterOfCredit();
        emit ApproveLetterOfCredit();
    }

    function rejectLetterOfCredit(address letterOfCreditAddress) public {
        require();
        TradeFinance LCEntity = listTradeFinance[letterOfCreditAddress];
        LCEntity.rejectLetterOfCredit();
        emit RejectLetterOfCredit();
    }

    function uploadDocument(address letterOfCreditAddress, string docHash) public {
        require();
        TradeFinance LCEntity = listTradeFinance[letterOfCreditAddress];
        LCEntity.uploadDocument(docHash);
        emit DocumentUploaded();
    }

    function deactiveLC(address letterOfCreditAddress) public {
        require();
        TradeFinance LCEntity = listTradeFinance[letterOfCreditAddress];
        LCEntity.deactivateLC();
        emit DeactiveLC();
    }

    function activeLC(address letterOfCreditAddress) public {
        require();
        TradeFinance LCEntity = listTradeFinance[letterOfCreditAddress];
        LCEntity.activateLC();
        emit ActivateLC();
    }

    function escrowFund(address letterOfCreditAddress) public {
        require();
        TradeFinance LCEntity = listTradeFinance[letterOfCreditAddress];
        LCEntity.escrowFund();
        emit FundEscrowed();
    }

    function payFund(address letterOfCreditAddress) public {
        require();
        TradeFinance LCEntity = listTradeFinance[letterOfCreditAddress];
        LCEntity.payFund();
        emit FundPaid();
    }

    function refundFund(address letterOfCreditAddress) public {
        require();
        TradeFinance LCEntity = listTradeFinance[letterOfCreditAddress];
        LCEntity.refundFund();
        emit FundRefunded();
    }

    
}
