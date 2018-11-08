pragma solidity 0.4.21;
import "./utility/Owned.sol";


contract PrivateBox is Owned {

    address public holder;
    GoldiamBox public goldiambox;
    uint private unqualifiedBalance;
    uint private unqualifiedBalanceTimestamp;
    
    event Withdraw (address indexed _holder, address indexed _privateBox, uint256 value);
    event Deposit (address indexed _holder, address indexed _privateBox, uint256 value);
    // event Transfer (address indexed _holder, address indexed _privateBox, address indexed _to, uint256 value);

    modifier onlyHolder() {
        require(msg.sender == holder);
        _;
    }

    function PrivateBox(address _goldiambox, address _holder) public {
        require(_goldiambox != address(0) && _holder != address(0));
        goldiambox = GoldiamBox(_goldiambox);
        holder = _holder;
    }

    function () public payable {
        deposit();
    }
 
    function checkBalanceAllocation()
        public 
        view 
        returns (uint currentQualifiedBalance, uint currentUnqualifiedBalance) 
    {
        if (now - unqualifiedBalanceTimestamp > goldiambox.qualificationPeriod()) {
            currentUnqualifiedBalance = 0;
        } else {
            currentUnqualifiedBalance = unqualifiedBalance;
        }
        currentQualifiedBalance = address(this).balance - currentUnqualifiedBalance;
    }

    function checkTotalBalance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0);
        if (now - unqualifiedBalanceTimestamp > goldiambox.qualificationPeriod()) {
            unqualifiedBalance = 0;
        }
        unqualifiedBalanceTimestamp = now;
        unqualifiedBalance += msg.value;
        emit Deposit(msg.sender, address(this), msg.value);
    }

    /*
    function transferFunds(address recipient, uint256 amount) public onlyHolder {
        require(address(this).balance >= amount);
        if (unqualifiedBalance < amount) {
            unqualifiedBalance = 0;
        } else {
            unqualifiedBalance -= amount;
        }
        address(recipient).transfer(amount);
        emit Transfer(msg.sender, address(this), address(recipient), amount);
    }
   */
    function withdrawFunds(uint amount) public onlyHolder {
        require(address(this).balance >= amount);
        if (unqualifiedBalance < amount) {
            unqualifiedBalance = 0;
        } else {
            unqualifiedBalance -= amount;
        }
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, address(this), amount);
    }

}
