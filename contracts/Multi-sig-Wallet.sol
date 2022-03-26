// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



/*
 ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
  "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
  "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
*/


contract MultiSigWallet {
    address[] public owners;
    uint256 numConfirmationsRequired;

    // nested mapping
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // transaction to store data
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 validConfirmation;
    }

    // array type struct
    Transaction[] public transactions;

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txId,
        address indexed to,
        uint256 value,
        bytes data
    );

    event ConfirmTransaction(address indexed owner, uint indexed txId);
    event ExecuteTransaction(address indexed owner, uint indexed txId);
    event RevokeTransaction(address indexed owner, uint indexed txId);


    // from address to bool
    mapping(address => bool) public isOwner;

    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    //add the address inside the array
    constructor (address[] memory _owners, uint256 _numConfirmationsRequired){
        require(_owners.length > 0, "please entered at least one address");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired < _owners.length, " The num of confirmation is not unique");
        for(uint256 i = 0; i < _owners.length; i++) {
            // create variables to store each owner in the loop
            address owner = _owners[i];
            require(owner != address(0), "address is not valid");
            // check for unique owner
            require(!isOwner[owner], "Owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }


    //function to receive ether inside this contract
    receive() external payable {
        emit Deposit(msg.sender,msg.value, address(this).balance);
    }


    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
        )
        public 
        onlyOwner()
        {
    uint256 txId = transactions.length;

    transactions.push(
        Transaction ({
            to : _to,
            value : _value,
            data : _data,
            executed: false,
            validConfirmation : 0
        })
    );

    emit SubmitTransaction(msg.sender, txId, _to, _value, _data);  
    }

    modifier txExist(uint256 _txId) {
        require(_txId < transactions.length, "tx doesn't exist");
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        require(!isConfirmed[_txId][msg.sender], "tx already confirmed");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not Owner");
        _;
    }

    // Confirm transaction
    function confirmTransaction(uint256 _txId) 
    public
    onlyOwner()
    notExecuted(_txId)
    notConfirmed(_txId)
    txExist(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.validConfirmation = transaction.validConfirmation + 1;
        isConfirmed[_txId][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txId);

    } 


    // execute transaction 
    function executeTransaction(uint _txId) 
    public
    onlyOwner()
    notExecuted(_txId)
    txExist(_txId) {
        Transaction storage transaction = transactions[_txId];
        // check if we got the requirement confirmition
        require(transaction.validConfirmation >= numConfirmationsRequired, "connot execute tx");
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");
        emit ExecuteTransaction(msg.sender, _txId);
        

    }
    
    function revokeTransaction(uint256 _txId) 
    public
    onlyOwner()
    notExecuted(_txId)
    txExist(_txId) {
        require(isConfirmed[_txId][msg.sender], "tx is not confirmed");

        transactions[_txId].validConfirmation = transactions[_txId].validConfirmation - 1;
        isConfirmed[_txId][msg.sender] = false;
        emit RevokeTransaction(msg.sender, _txId);
    }


    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function transactionCount() public view returns(uint) {
        return transactions.length;
    }

    function getAllTransactions(uint256 _txId) public view returns (   
        address to,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 validConfirmation ) {
        return (
            transactions[_txId].to,
            transactions[_txId].value,
            transactions[_txId].data,
            transactions[_txId].executed,
            transactions[_txId].validConfirmation
        );
        
    }



}


