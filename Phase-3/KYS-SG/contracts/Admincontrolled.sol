// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

contract admincontrolled{
    address owner;
    bool public isKycGoing;

    constructor(address _owner, bool _isKycGoing) public {
        owner = _owner;
        isKycGoing = _isKycGoing;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only ownr is allowed here");
        _;
    }
    modifier processClosed(){
        require(!isKycGoing, "The Kyc process is still open");
        _;
    }
}