pragma solidity 0.4.21;


contract Owned {
    address public owner;

    function Owned() public { 
        owner = msg.sender; 
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}
