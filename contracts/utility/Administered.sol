pragma solidity 0.4.21;
import "./Owned.sol";


contract Administered is Owned {
    address public admin;
    address public newAdmin;
    
    function Administered(address _admin) public { 
        if (_admin == address(0)) {
            admin = msg.sender;
        } else {
            admin = _admin;
        }
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }
    
    function transferAdminPrivileges(address _newAdmin) public onlyAdmin {
        require(_newAdmin != admin);
        newAdmin = _newAdmin;
    }

    function acceptAdminPrivileges() public {
        require(msg.sender == newAdmin);
        admin = newAdmin;
        newAdmin = address(0);
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        owner = _newOwner;
    }
}
