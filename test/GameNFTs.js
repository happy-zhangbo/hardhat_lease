// const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const sigUtil = require("eth-sig-util")

describe("LeaseNFTs", function () {

    let gameItems;
    let goldCoin;
    let leaseNft;

    let wallet = ethers.Wallet.createRandom();
    let privateKey = wallet.privateKey;
    privateKey = privateKey.substring(2,privateKey.length);
    var privateKeyHex = Buffer.from(privateKey, 'hex');
    wallet =  wallet.connect(ethers.provider);

    var deadline = (parseInt(new Date().getTime()/1000)) + 600;

    async function deployTokenFixture() {
        const [ owner ] = await ethers.getSigners();
        await owner.sendTransaction({to: wallet.address, value: ethers.utils.parseEther("10")});
                
        const NFTs = await ethers.getContractFactory("GameItems");
        gameItems = await NFTs.deploy();
        console.log(`NFTs：${gameItems.address}`);

        const Gold = await ethers.getContractFactory("GoldToken");
        goldCoin = await Gold.deploy("Gold","G");
        console.log(`Gold Coin: ${goldCoin.address}`);

        const LeaseNFT = await ethers.getContractFactory("LeaseNFT");
        leaseNft = await LeaseNFT.deploy(gameItems.address, goldCoin.address);
        console.log(`LeaseNFT: ${leaseNft.address}`);

    }
    
    it("devClaim", async function () {
        await loadFixture(deployTokenFixture);
        const [ owner ] = await ethers.getSigners();
        await gameItems.devClaim(owner.address, 1 , ["123"]);
        expect(await gameItems.ownerOf(0)).to.equal(owner.address);
    });

    it("approve", async function () {
        await gameItems.approve(leaseNft.address,0);
        expect(await gameItems.getApproved(0)).to.equal(leaseNft.address);
    });

    it("EntrustedRental", async function () {
        const [ owner ] = await ethers.getSigners();
        await leaseNft.entrustedRental(0, 100);
        expect(await leaseNft.ownerOf(0)).to.equal(owner.address);
    });

    it("Authorize Mint Role", async function() {
        const [ owner ] = await ethers.getSigners();
        const mintRole = await goldCoin.MINTER_ROLE();
        await goldCoin.grantRole(mintRole, owner.address);
        expect(await goldCoin.hasRole(mintRole,owner.address)).to.true
    });
    
    it("Mint Gold Coin", async function() {
        const [ owner ] = await ethers.getSigners();
        await goldCoin.mint(1000);
        expect(await goldCoin.balanceOf(owner.address)).to.equal(1000);
    }) 

    it("Gold Transfer", async function() {
        const [ owner ] = await ethers.getSigners();
        await expect(goldCoin.transfer(wallet.address, 1000)).to.changeTokenBalances(goldCoin, [owner, wallet], [-1000, 1000]);
    })
    async function getSignature(){
        var chainid = await goldCoin.blockId();
        const typedData = {
            "types": {
                "EIP712Domain": [
                    {"name": "name", "type": "string"},
                    {"name": "version", "type": "string"},
                    {"name": "chainId", "type": "uint256"},
                    {"name": "verifyingContract", "type": "address"}
                ],
                "Permit": [
                    {
                        "name": "owner",
                        "type": "address"
                    },
                    {
                        "name": "spender",
                        "type": "address"
                    },
                    {
                        "name": "value",
                        "type": "uint256"
                    },
                    {
                        "name": "nonce",
                        "type": "uint256"
                    },
                    {
                        "name": "deadline",
                        "type": "uint256"
                    }
                ]
            },
            "primaryType": "Permit",
            "domain": {
                "name": "Gold",
                "version": "1",
                "chainId": chainid.toNumber(),
                "verifyingContract": goldCoin.address
            },
            "message": {
                "owner": wallet.address,
                "spender": leaseNft.address,
                "value": 100,
                "nonce": 0,
                "deadline": deadline
            }
        };
        const signature = sigUtil.signTypedData_v4(privateKeyHex, { data: typedData });
        let sign = signature.substring(2, signature.length);
        let hexV = sign.substring(sign.length-2,sign.length)
        let data = {
            v: parseInt(`0x${hexV}`),
            r: `0x${sign.substring(0,64)}`,
            s: `0x${sign.substring(64,128)}`,
            sign: signature
        }
        return data;
    }
    it("Deposit", async function() {
        const data = await loadFixture(getSignature);
        await leaseNft.connect(wallet).deposit(100, deadline, data.v, data.r, data.s);
        expect(await leaseNft.balanceOf(wallet.address)).to.equal(100);
        expect(await goldCoin.balanceOf(leaseNft.address)).to.equal(100);
    });

    it("leaseNFTbyPrepaid", async function(){
        const [ owner ] = await ethers.getSigners();
        var expires = (parseInt(new Date().getTime()/1000)) + 6000;

        const adminRole = await goldCoin.ADMIN_ROLE();
        await goldCoin.setMintRoleAdmin(leaseNft.address);
        expect(await goldCoin.hasRole(adminRole,leaseNft.address)).to.true

        await leaseNft.connect(wallet).leaseNFTbyPrepaid(0, expires);
        expect(await leaseNft.userOf(0)).to.equal(wallet.address);

        const leaseInfo = await leaseNft._leases(0);
        const leaseAgreement = await ethers.getContractFactory("LeaseAgreement");
        const agreement = await leaseAgreement.attach(leaseInfo.agreement)
        expect(await agreement.nftOwner()).to.equal(owner.address);
        expect(await agreement.nftUser()).to.equal(wallet.address);
    });


    it("Exchange Token", async function(){
        const [ owner ] = await ethers.getSigners();
        const leaseInfo = await leaseNft._leases(0);

        const leaseAgreement = await ethers.getContractFactory("LeaseAgreement");
        const agreement = await leaseAgreement.attach(leaseInfo.agreement)
        
        await agreement.connect(wallet).mint(10);
        
        expect(await goldCoin.balanceOf(owner.address)).to.equal(10);


    });










    


})