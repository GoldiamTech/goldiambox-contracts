pragma solidity 0.4.21;
import "./Owned.sol";


contract Managed is Owned {
    address public manager;
    
    function Managed(address _manager) public { 
        require(_manager != address(0));
        manager = _manager;
    }
    
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }
}
