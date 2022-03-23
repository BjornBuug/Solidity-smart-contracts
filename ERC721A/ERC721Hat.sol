// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";


contract ERC721ASunShine is Ownable, ERC721A, PaymentSplitter {

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


    // prices 
    uint public wlSalePrice = 0.0025 ether;
    uint public publicSalePrice = 0.003 ether;

    bytes32 public merkleRoot;

    // timestamp allows to keep track of a changes of a specific files
    uint public saleStartTime = 1648645200;

    uint private teamLength;

    // to keep track of whitelisted people who minted an NFT
    mapping(address => uint ) public amountNFTsperWalletWhitelistSale;




}