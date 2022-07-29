// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract GoldToken is ERC20Permit, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(
        string memory name,
        string memory symbol
    ) ERC20Permit(name) ERC20(name, symbol) {
        _setRoleAdmin(MINTER_ROLE,ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function mint(uint256 counts) external onlyRole(MINTER_ROLE){
        _mint(msg.sender, counts);
    }

    function blockId() public view returns(uint) {
        return block.chainid;
    }

    function setMintRoleAdmin(address admin) external onlyOwner{ 
        _grantRole(ADMIN_ROLE, admin);
    }
}