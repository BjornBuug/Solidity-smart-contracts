
const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const Hat = await hre.ethers.getContractFactory("ERC721AHat");
  const greeterHat = await Hat.deploy(["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"],
    [60,20,20],
    "0x2e95d9b220e054ce1ffa9e0698bcf436f445e88fc75ef6e9126b547e21356c6e", "test/", "test/");

  await greeterHat.deployed();

  console.log("greeterHat deployed to:", greeterHat.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
