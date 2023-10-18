// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LC is Ownable {
    using SafeMath for uint;

    address buyer; 
    address seller; 
    address buyer_bank;
    address seller_bank;
    address transport;

    uint256 public startTime;
    uint deadline;

    mapping(address => string) document_hash;
    
    enum contract_status {
        ON, // create contract
        LC_CREATED, // create LC
        DOC_UPLOADED, // upload doc
        SHIPPED, // notify shipped
        PAID, // finish payment
        CLOSED // close contract
    }
    contract_status public status;

    event ContractDeployed(address deployer, address contract_address);
    event CreateLC(address creator, string doc_hash);
    event SellerUploaded(address seller, string doc_hash);
    event Shipped();
    event Paid();
    event ContractClosed(address bank, address contract_address);
    event ContractExpired(address contract_address);
    event SetDeadline(uint deadline);
    event TimeLeft(uint time_left);

    modifier onlyBuyer {
        require(msg.sender == buyer, "Only buyer can perform this function");
        _;
    }
    modifier onlySeller {
        require(msg.sender == seller, "Only seller can perform this function");
        _;
    }
    modifier onlyBank {
        require(msg.sender == seller_bank || msg.sender == buyer_bank, "Only bank can perform this function");
        _;
    }
    modifier onlyTransport {
        require(msg.sender == transport, "Only transport department can perform this function");
        _;
    }
    modifier notClosed {
        require(deadline > contractElapsedTime() && status != contract_status.CLOSED, "Contract closed. Cannot access");
        _;
    }

    function contractElapsedTime() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - startTime;
        return elapsedTime;
    }

    constructor(address _buyer, address _seller, address _buyer_bank, address _seller_bank, address _transport, uint _deadline) {
        status = contract_status.ON;
        buyer = _buyer;
        seller = _seller;
        buyer_bank = _buyer_bank;
        seller_bank = _seller_bank;
        transport = _transport;
        deadline = _deadline;
        startTime = block.timestamp;
        emit ContractDeployed(msg.sender, address(this));
        emit SetDeadline(deadline);
    }

    // close contract
    function closeContract() public onlyBank {
        require(status == contract_status.PAID || checkContractAvail() == false, "Contract is still valid. Cannot close");
        status = contract_status.CLOSED;
        emit ContractClosed(msg.sender, address(this));
    }

    // check contract is not expired or not
    function checkContractAvail() public returns (bool) {
        if(deadline < contractElapsedTime()) {
            emit ContractExpired(address(this));
            return false;
        }
        emit TimeLeft(deadline - contractElapsedTime());
        return true;
    }

    function setShipped() external onlyTransport {
        status = contract_status.SHIPPED;
        emit Shipped();
    }

    function setPaid() external onlyBank {    
        status = contract_status.PAID;
        emit Paid();
    }

    // Bank create LC after approving buyer request
    function createLC(string memory _doc_hash) external onlyBank notClosed {
        status = contract_status.LC_CREATED;
        document_hash[buyer] = _doc_hash;
        emit CreateLC(buyer, _doc_hash);
    }

    // bank approve and upload doc (from seller) for shipment and payment
    function uploadDoc(string memory _doc_hash) external onlyBank notClosed {
        status = contract_status.DOC_UPLOADED;
        document_hash[seller] = _doc_hash;
        emit SellerUploaded(seller, _doc_hash);
    }

    // get document cid
    function getDocument(address _user) public view returns (string memory) {
        require(msg.sender == buyer || msg.sender == seller || 
            msg.sender == buyer_bank || msg.sender == seller_bank || msg.sender == transport);
        return document_hash[_user];
    } 

    // get contract status
    function getContractStatus() public view returns (contract_status) {
        return status; 
    }
}
