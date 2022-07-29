// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./erc4907/ERC4907.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./LeaseAgreement.sol";
import "./IGoldToken.sol";

contract LeaseNFT is ERC4907, IERC721Receiver {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event RentalEvent(address from, uint256 tokenId, uint256 price);
    event LeaseEvent(address pariAddress, uint256 tokenId);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    IGoldToken goldToken;
    IERC721 nft;
    constructor(address nftToken, address _goldToken) ERC4907(){
        nft = IERC721(nftToken);
        goldToken = IGoldToken(_goldToken);
    }

    struct RentalInfo{
        uint tokenId;
        address owner;
        uint256 price;
    }

    struct LeaseInfo{
        uint tokenId;
        address owner;
        address user;
        uint expires;
        address agreement; 
    }

    mapping (uint256  => RentalInfo) public _rentals;
    mapping (uint256 => address) public _owners;

    mapping (uint256  => LeaseInfo) public _leases;

    //保证金
    mapping (address => uint256) public  balanceOf;

    //充值保证金
    function deposit(uint256 value, uint256 deadline,uint8 v,bytes32 r,bytes32 s) public {
        permitTransfer(value, deadline, v, r, s, msg.sender, address(this));
        balanceOf[msg.sender] += value;
        emit Deposit(msg.sender, value);
    }

    //保证金提现
    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        goldToken.transfer(msg.sender, wad);
        emit Withdrawal(msg.sender, wad);
    }

    //授权
    function permitTransfer(uint256 value, uint256 deadline,uint8 v,bytes32 r,bytes32 s, address from, address to) private{
        goldToken.permit(msg.sender, address(this), value, deadline, v, r, s);
        goldToken.transferFrom(from, to, value); 
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    //委托出租
    function entrustedRental(uint256 tokenId, uint256 price) external callerIsUser{
        require(msg.sender == nft.ownerOf(tokenId) || msg.sender == ownerOf(tokenId), "lessor caller is not owner");
        //转移NFT
        if(msg.sender == nft.ownerOf(tokenId)){
            require(address(this) == nft.getApproved(tokenId), "transfer caller is not approved");
            nft.safeTransferFrom(msg.sender, address(this), tokenId);
        }

        //记录委托信息
        RentalInfo storage rental = _rentals[tokenId];
        rental.tokenId = tokenId;
        rental.owner = msg.sender;
        rental.price = price;

        //记录出租人
        _owners[tokenId] = msg.sender;
        emit RentalEvent(msg.sender, tokenId, price);
    }

    //查询出租人
    function ownerOf(uint256 tokenId) public view returns(address){
        return _owners[tokenId];
    }
    
    //取消出租
    function cancelRental(uint256 tokenId) external callerIsUser{
        require(msg.sender == ownerOf(tokenId), "lessor caller is not owner");
        require(address(0) == userOf(tokenId), "NFTs are being rented");

        delete _rentals[tokenId];
        delete _owners[tokenId];

        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit RentalEvent(msg.sender, tokenId, 0);
    }
    
    //承租NFT 使用保证金
    function leaseNFTbyPrepaid(uint256 tokenId, uint64 expires) external callerIsUser{
        require(address(0) != ownerOf(tokenId), "NFT does not entrust the lease");
        require(address(0) == userOf(tokenId), "NFT has been leased");
        
        RentalInfo memory ri = _rentals[tokenId];
        //检查保证金是否足够支付
        require(balanceOf[msg.sender] >= ri.price, "Insufficient balance");

         //使用保证金预支付，创建租借合约。
        bytes32 salt = keccak256(abi.encodePacked(ri.owner, msg.sender, tokenId, expires));
        LeaseAgreement la = new LeaseAgreement{salt: salt}(goldToken, ri.owner, msg.sender, expires, tokenId, ri.price);
        //扣除保证金并转移保证金到协议中
        balanceOf[msg.sender] -= ri.price;

        //授权协议有mint金币的权限
        goldToken.grantRole(MINTER_ROLE, address(la));
        goldToken.transfer(address(la), ri.price);

        LeaseInfo storage li = _leases[tokenId];
        li.owner = ri.owner;
        li.expires = expires;
        li.tokenId = tokenId;
        li.agreement = address(la);
        li.user = msg.sender;

        //出租授权
        setUser(tokenId,msg.sender, expires);
        emit LeaseEvent(address(la), tokenId);
    }

     //承租NFT一次性付清
    function leaseNFT(uint256 tokenId, uint64 expires,
        uint256 value, uint256 deadline,uint8 v,bytes32 r,bytes32 s) external callerIsUser{
        require(address(0) != ownerOf(tokenId), "NFT does not entrust the lease");
        RentalInfo memory ri = _rentals[tokenId];
         //检查保证金是否足够支付
        require(value >= ri.price, "Insufficient balance");
        permitTransfer(value, deadline, v, r, s, msg.sender, ri.owner);

        //出租授权
        setUser(tokenId,msg.sender, expires);
        emit LeaseEvent(address(0), tokenId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}