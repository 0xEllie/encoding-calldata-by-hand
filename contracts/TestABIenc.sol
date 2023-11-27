// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title TestABIencode
 * @author Ellie (ellie.xyz1991@gmail.com)
 */
 
contract TestABIencode {

struct Person{
    string name;
    bool isTrue;
    uint[] balances;
}

function result1(uint amount, bytes[] calldata codes, address to) public pure returns(uint , bytes[] calldata , address){
    return(amount, codes, to);
}

function result2(Person calldata  user, bytes[4] calldata codes, uint8 number) public pure returns(Person calldata , bytes[4] calldata , uint8 ){
    return(user, codes, number);
}
}