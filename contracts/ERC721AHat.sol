// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";


/*
- bytes32 is used to store raw data, it is cheaper that using string
- using 'tx.origin' allows to prevent other contract to call to prevent re entrency attack
but only external owned address can call the contract
- Calldata special data location that contains functions arguments
- totalSupply() return the tokens stored by the contracts
- The diddference between pure and view is that view functions declares that no states will be changed.
in the other hand pure function declares that no states will be changed or read.
- keccak256 is a cryptographic function build into solidity, it takes an input and convert it into
32 bytes hash.
receive() external payable — for empty calldata (and any value)

- approve or setApprovalForAll allows an address to transfer an NFT to another address
*/


contract ERC721AHat is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

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
    uint public saleMintStartTime = 1648182953;

    uint private teamLength;

    // to keep track of whitelisted people who minted an NFT
    mapping(address => uint ) public amountNFTsperWalletWhitelistSale;

    // URI when the collection is revealed
    string public baseURI;

    // URI when the collection not revealed
    string public notRevealedURI;

    // extention of the file containing the metadata of the NFTS
    string public baseExtension = ".json";

    // check if the collection has been revealed or not yet
    bool public revealed = false;


    constructor (address[] memory _team,
                 uint[] memory _teamShares,
                 bytes32 _merkleRoot,
                 string memory _theBaseURI,
                 string memory _notRevealedURI) ERC721A("Happy Hat", "HPT")
                 PaymentSplitter(_team, _teamShares) {
        
                merkleRoot =  _merkleRoot;  
                baseURI = _theBaseURI;
                notRevealedURI = _notRevealedURI;
                teamLength = _team.length;

                }


    modifier callerIsUser {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // function to mint in the whitelist
    function whitelistSaleMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
            uint price = wlSalePrice;
            require(price != 0, "price cannot be 0");
            require(currentTime() >= saleMintStartTime, "Whitelist mint sale has not start yet");
            require(currentTime() < saleMintStartTime + 300 minutes, "Whitelist sale is finished");
            require(sellingStep == Step.WhitelistSale, "The white list is not activated yet");
            require(isWhiteListed(msg.sender,_proof), "Not whitelisted");
            // to prevent to user to mint more than 1 NFt with his address
            require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= 1, "You can only mint 1 NFT");
            require(totalSupply() + _quantity <= MAX_WHITELIST, "WHITELIST supply exceeded");
            require(msg.value >= price * _quantity, "not enough funds");
            amountNFTsperWalletWhitelistSale[msg.sender] += _quantity; 
            _safeMint(_account, _quantity);
    }


    // function to mint in public sale step
    function publicSaleMint (address _account, uint _quantity) external callerIsUser payable {
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



    // Change the base URI
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // return the baseURi of the collection when it revealed
    function _baseURI() internal view override virtual  returns(string memory) {
        return baseURI;
    }

    // change the not revealed URI
    function setNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    // Allows to set the revealed variable to true
    function reveal() external onlyOwner {
        revealed = true;
    }

    function tokenURI(uint _nftId) public view virtual override returns(string memory) {
        require(_exists(_nftId), "This NFT doesn't exist");
        if(revealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
                : "";

    }


    // set step 
    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    // get the current time
    function currentTime() internal view returns (uint) {
        return block.timestamp;
    }

    // White list
    function setMerleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // These functions deal with verification of Merkle trees
    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    // check if is whiteListed or not
    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns (bool) {
        return _verify(leaf(_account), _proof);
    }

    // release the payment
    function releaseAll() external {
        for(uint i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert ("Only if you mint");
    }

    
/*

// _Team
[
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"
]

_TEAMSHARES 
2500000000000000
[
    60,
    20,
    20,
]

_MERKLEROOT : 0x2e95d9b220e054ce1ffa9e0698bcf436f445e88fc75ef6e9126b547e21356c6e

contract address : 0xfdF898643b1D2F8523a62645058B3BF3F622dF43

_proof

[
    "0x04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54",
    "0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb"
]


*/  

}
