// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IGoldToken {
    function mint(uint256 counts) external;

    function permit(address owner, address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s) external;

    function transferFrom(address from,address to,uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function grantRole(bytes32 role, address account) external;

    function transferOwnership(address newOwner) external;
}