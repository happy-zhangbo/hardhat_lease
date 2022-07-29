// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IGoldToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LeaseAgreement is AccessControl{

    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IGoldToken goldToken;
    address public nftOwner;
    address public nftUser;
    uint64 expires;
    uint256 price;
    uint256 public tokenId;
    uint256 public repaid;



    constructor(IGoldToken _goldToken, address _nftOwner, address _nftUser, uint64 _expires, uint256 _tokenId, uint256 _price){
        goldToken = _goldToken;
        nftOwner = _nftOwner;
        nftUser = _nftUser;
        expires = _expires;
        tokenId = _tokenId;
        price = _price;

        _grantRole(USER_ROLE, _nftUser);
        _grantRole(OWNER_ROLE, _nftOwner);
    }
    event ExchangeGoldToken(address from, uint256 quantity);
    

    //需要验证官方签名
    function mint(uint256 quantity) external onlyRole(USER_ROLE){
        require(block.timestamp < expires, "Agreement expired");
        goldToken.mint(quantity);
        //分账
        if(repaid < price){
            if((repaid+quantity) < price){
                goldToken.transfer(nftOwner, quantity);
                repaid += quantity;
            }else{
                goldToken.transfer(nftOwner, price-repaid);
                repaid += price-repaid;
            }
        }else{
            goldToken.transfer(nftUser, quantity);
        }
        emit ExchangeGoldToken(msg.sender, quantity);
    }
}