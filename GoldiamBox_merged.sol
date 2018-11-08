pragma solidity 0.4.21;

// File: contracts/utility/Owned.sol

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

// File: contracts/PrivateBox.sol

contract PrivateBox is Owned {

    address public holder;
    GoldiamBox public goldiambox;
    uint private unqualifiedBalance;
    uint private unqualifiedBalanceTimestamp;
    
    event Withdraw (address indexed _goldiambox, address indexed _holder, address indexed _privateBox, uint256 value);

    event Deposit (
        address indexed _goldiambox,
        address indexed _from,
        address indexed _privateBox,
        address _holder,
        uint256 value
    );

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
        emit Deposit(address(goldiambox), msg.sender, address(this), address(holder), msg.value);
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
        emit Withdraw(address(goldiambox), msg.sender, address(this), amount);
    }

}

// File: contracts/GoldiamBox.sol

contract GoldiamBox is Owned {
    
    uint public qualificationPeriod = 24 hours;
    uint public roundDuration = 24 hours;
    address[] private registeredHolders;
    mapping(address => address) public privateBoxOf;
    mapping(address => address) public holderOf;

    event PrivateBoxCreation(address indexed _goldiambox, address indexed _holder, address indexed _privateBox);

    function GoldiamBox() public {
    }

    function() public {
    }
    
    function getHolderTotalBalance(address holder) external view returns (uint) {
        return PrivateBox(privateBoxOf[holder]).checkTotalBalance();
    }

    function getHolderBalanceAllocation(address holder)
        external 
        view 
        returns (uint qualifiedBalance, uint unqualifiedBalance) 
    {
        return PrivateBox(privateBoxOf[holder]).checkBalanceAllocation();
    } 

    function getPrivateBoxBalanceAllocation(address privateBox)
        external 
        view 
        returns (uint qualifiedBalance, uint unqualifiedBalance) 
    {
        return PrivateBox(privateBox).checkBalanceAllocation();
    }

    function getTotalBalance() external view returns (uint totalQualified, uint totalUnqualified) {
        uint q;
        uint u;
        for (uint i = 0; i < registeredHolders.length; i++) {
            (q, u) = PrivateBox(this.privateBoxOf(registeredHolders[i])).checkBalanceAllocation();
            totalQualified += q;
            totalUnqualified += u;
        }
    }

    function getAllRegisteredHolders() external view returns (address[]) {
        return registeredHolders;
    }

    /*
    function aproximateRewardPerRound(address _holder)
        external 
        view 
        returns (uint _wei, uint _gol) 
    {
        uint holderBalance;
        uint totalBalance;
        (holderBalance,) = this.getHolderBalanceAllocation(_holder);
        (totalBalance,) = this.getTotalBalance();
        holderBalance *= 1000000;
        uint share = holderBalance / totalBalance;
        uint blocktime = 14 seconds;
        uint rewardPerBlock = 0.16 ether;
        _wei = (((rewardPerBlock * roundDuration) / blocktime) * share) / 1000000;
        _gol = _wei / 1000000000000000000;
    }

    */
    function createPrivateBox() public {
        require(privateBoxOf[msg.sender] == address(0));
        PrivateBox box = new PrivateBox(this, msg.sender);
        privateBoxOf[msg.sender] = box;
        holderOf[address(box)] = msg.sender;
        registeredHolders.push(msg.sender);
        emit PrivateBoxCreation(address(this), msg.sender, address(box));
    }

    function setQualificationPeriod(uint _qualificationPeriod) public onlyOwner {
        require(_qualificationPeriod >= 0);
        qualificationPeriod = _qualificationPeriod;
    }

    function setRoundDuration(uint _roundDuration) public onlyOwner {
        require(_roundDuration >= 0);
        roundDuration = _roundDuration;
    }
}
