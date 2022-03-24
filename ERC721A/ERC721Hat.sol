// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";


/*
- bytes32 is used to store raw data, it is cheaper that using string
- using 'tx.origin' allows to prevent other contract to call to prevent re entrency attack
but only external owned address can call the contract
- Calldata special data location that contains functions arguments
- totalSupply() return the tokens stored by the contracts
*/


contract ERC721AHat is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;
    string public baseURI;

    // enum is to define a collection of options availble
    enum Step {
        Before, 
        WhitelistSale, 
        PublicSale,
        SoldOut, 
        Reveal 
    }

    // create a variables types of enum Step
    Step public sellingStep;

    // Constant are values that can not be modifed 
    // Their values are hardcoded and using constans can save gas cost

    uint private constant MAX_SUPPLY = 10000;
    uint private constant MAX_WHITELIST = 3000;
    uint private constant MAX_PUBLIC = 6000;
    uint private constant MAX_GIFT = 1000; // => royalties


    // Prices 
    uint public wlSalePrice = 0.0025 ether;
    uint public publicSalePrice = 0.003 ether;

    bytes32 public merkleRoot;

    // timestamp allows to keep track of a changes of a specific files
    uint public saleMintStartTime = 1648645200;

    uint private teamLength;

    // to keep track of whitelisted people who minted an NFT
    mapping(address => uint ) public amountNFTsperWalletWhitelistSale;

    constructor (address[] memory _team,
                 uint[] memory _teamShares,
                 bytes32 _merkleRoot,
                 string memory _baseURI) ERC721A("Happy Hat", "HPT")
                 PaymentSplitter(_team, _teamShares) {
        
                merkleRoot =  _merkleRoot;  
                baseURI = _baseURI;
                teamLength = _team.length;
                }

    modifier onlyUserCall {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // function to mint in the whitelist
    function whitelistSaleMint(address _account, uint _quantity, bytes32 calldata _proof) onlyUserCall payable external {
            uint price = wlSalePrice;
            require(price != 0, "price cannot be 0");
            require(currentTime() >= saleMintStartTime, "Whitelist mint sale has not start yet");
            require(currentTime() < saleMintStartTime + 300 minutes, "Whitelist sale is finished");
            require(sellingStep == Step.WhitelistSale, "The white list is not activated yet");
            // to prevent to user to mint more than 1 NFt with his address
            require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= 1, "You can only mint 1 NFT");
            require(totalSupply() + _quantity <= MAX_WHITELIST, "WHITELIST supply exceeded");
            require(msg.sender >= price * _quantity, "not enough funds");
            amountNFTsperWalletWhitelistSale[msg.sender] += _quantity; 
            _safeMint(_account, _quantity);
    }

    // function to mint in public sale step
    function publicSaleMint (address _account, uint _quantity) external onlyUserCall payable {
            uint price = publicSalePrice;
            require(price != 0, "price cannot be 0");
            require(sellingStep == Step.PublicSale, "Public Sale is not activated yet");
            require(msg.value >= price * _quantity, "Not enough funds ");
            require(totalSupply() + _quantity <= MAX_WHITELIST + MAX_PUBLIC, "Max supply exceeded");
            _safeMint(_account, _quantity);
    }


    // royalties for users
    function sendGift(address _to, uint256 _quantity) external onlyOwner {
        require(sellingStep > Step.PublicSale,"Gift is after the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_to, _quantity);
    }

    //set start time function
    function setSaleStartTime(uint _setSaleStartTime) external onlyOwner {
        saleMintStartTime = _setSaleStartTime;
    }

    // set the base URI
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // set step 
    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    // get the current time
    function currentTime() internal view returns (uint) {
        return block.timestamp;
    }


}