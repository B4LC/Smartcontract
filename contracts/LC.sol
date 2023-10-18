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

    uint stake_amount;
    uint256 public startTime;
    uint deadline;

    mapping(address => uint) balance;
    mapping(address => string) document_hash;
    
    enum contract_status {
        ON, // create contract
        STAKED, // buyer stake to contract
        BUYER_UPLOADED, // buyer upload document
        SELLER_UPLOADED, // seller upload document
        DOC_APPROVED, // document is verified
        DOC_REJECTED, // document is rejected
        SHIPPED, // notify shipped
        PAID, // finish payment
        CLOSED // close contract
    }
    contract_status public status;

    event ContractDeployed(address deployer, address contract_address);
    event BuyerStaked(address buyer, uint amount);
    event BuyerUploaded(address buyer, string doc_hash);
    event SellerUploaded(address seller, string doc_hash);
    event ApprovedDocument(address bank, string doc_hash);
    event RejectedDocument(address bank, string doc_hash);
    event Shipped();
    event Paid();
    event ContractClosed(address bank, address contract_address);
    event ContractExpired(address contract_address);
    event BankWithdrawn(address bank, uint amount);
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
    modifier onlyStaked {
        require(status == contract_status.STAKED || address(this).balance > 0, "Buyer need to stake Eth to perform this function");
        _;
    }

    function contractElapsedTime() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - startTime;
        return elapsedTime;
    }

    function getStake() public view returns (uint) {
        return stake_amount;
    }

    // buyer stake eth to this contract (fee for bank)
    // after payment, bank can withdraw this amount
    function deposit() public payable {
        require(msg.sender.balance >= stake_amount, "Not enough balance to present transaction");
        require(address(this) != address(0), "Cannot transfer to address 0");
        status = contract_status.STAKED;
        stake_amount = msg.value;
        emit BuyerStaked(msg.sender, stake_amount);
    }

    // bank withdraw after contract closed
    function withdraw() public onlyBank {
        require(address(this).balance > 0, "No money in this contract");
        require(status == contract_status.CLOSED, "Contract opened. Cannot withdraw");
        if(msg.sender == buyer_bank) {
            uint amount = stake_amount * 7 / 10;
            payable(msg.sender).transfer(amount);
            emit BankWithdrawn(msg.sender, amount);
        }
        else {
            uint amount = stake_amount * 3 / 10;
            payable(msg.sender).transfer(amount);
            emit BankWithdrawn(msg.sender, amount);
        }
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

    // Buyer upload LC 
    function buyerUpload(string memory _doc_hash) external onlyBuyer notClosed onlyStaked {
        status = contract_status.BUYER_UPLOADED;
        document_hash[buyer] = _doc_hash;
        emit BuyerUploaded(msg.sender ,_doc_hash);
    }

    // seller upload doc for shipment and payment
    function sellerUpload(string memory _doc_hash) external onlySeller notClosed {
        status = contract_status.SELLER_UPLOADED;
        document_hash[seller] = _doc_hash;
        emit SellerUploaded(msg.sender,_doc_hash);
    }

    // bank check and approve doc
    function approveDocument(string memory _doc_hash) external onlyBank notClosed {
        require(keccak256(abi.encodePacked((document_hash[buyer]))) == keccak256(abi.encodePacked((_doc_hash))) ||
            keccak256(abi.encodePacked((document_hash[seller]))) == keccak256(abi.encodePacked((_doc_hash))), 
                "Cannot approve a undefined document");
        status = contract_status.DOC_APPROVED;
        emit ApprovedDocument(msg.sender, _doc_hash);
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

    function getBalance(address _user) public view returns (uint) {
        return _user.balance;
    }
 
    // reject doc
    function rejectDocument(string memory _doc_hash) external notClosed {
        status = contract_status.DOC_REJECTED;
        emit RejectedDocument(msg.sender, _doc_hash);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
