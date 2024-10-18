// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/IPledge.sol";

contract MMM314Pledge is ERC20, Ownable, IPledge {

    uint32 constant public BASE_FEE = 1e4;

    uint32 public withdrawalFee = 300;

    uint256 public totalDividends;

    uint256 public pledgeCount;

    uint256 private _inactivatedTotal;

    uint256 public minimumPledgeAmount = 21000 ether;

    uint256 public pledgeCapacity = 7e6 ether;

    uint32 public maximumPledgeAddressCount = 300;

    address public tokenContract;

    mapping(address => bool) public isPledge;

    mapping(address => uint256) public ownerDividends;

    mapping(address => uint256) private _inactivatedBalance;


    modifier onlyTokenContract() {
        require(
            msg.sender == tokenContract,
            "You are not the tokenContract"
        );
        _;
    }

    constructor()
    ERC20("MMM314 Ancillary Pledge ", "MMM314Pledge")
    Ownable(_msgSender())
    {

    }
    function inactivatedTotalSupply() public view returns (uint256) {
        return _inactivatedTotal;
    }

    function _mintInactivated(address account, uint256 value) internal
    {
        _inactivatedTotal += value;
        _inactivatedBalance[account] += value;
        emit Transfer(address(0), account, value);
        emit Inactivated(account, value, true);
    }

    function _burnInactivated(address account, uint256 value) internal
    {
        uint256 accountBalance = inactivatedBalanceOf(account);
        if (accountBalance < value) {
            revert ERC20InsufficientBalance(account, accountBalance, value);
        }
        unchecked{
            _inactivatedTotal -= value;
            _inactivatedBalance[account] -= value;
        }
        emit Transfer(account, address(0), value);
        emit Inactivated(account, value, false);
    }

    function setTokenContract(address tokenContract_) public onlyOwner
    {
        tokenContract = tokenContract_;
    }

    function setPledgeLimit(uint256 minimumPledgeAmount_, uint256 pledgeCapacity_, uint32 maximumPledgeAddressCount_) public onlyOwner
    {
        require(minimumPledgeAmount_ < minimumPledgeAmount, "minimumPledgeAmount set error");
        require(pledgeCapacity_ < pledgeCapacity, "pledgeCapacity set error");
        require(maximumPledgeAddressCount_ < maximumPledgeAddressCount, "maximumPledgeAddressCount set error");
        minimumPledgeAmount = minimumPledgeAmount_;
        pledgeCapacity = pledgeCapacity_;
        maximumPledgeAddressCount = maximumPledgeAddressCount_;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (isPledge[account]) {
            return super.balanceOf(account) + getDividend(account);
        }
        return inactivatedBalanceOf(account);
    }

    function inactivatedBalanceOf(address account) public view returns (uint256){
        return _inactivatedBalance[account];
    }

    function dividendHandle(uint256 dividend) public override onlyTokenContract
    {
        _addDividends(dividend);
    }

    function ownerAddDividends(uint256 dividend) public onlyOwner
    {
        IERC20(tokenContract).transferFrom(_msgSender(), address(this), dividend);
        _addDividends(dividend);
    }

    function _addDividends(uint256 dividend) internal
    {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            uint256 dividends = dividend * 1 ether / _totalSupply;
            totalDividends += dividends;
            emit Dividend(dividend, dividends, totalDividends, _totalSupply, block.number);
        } else {
            IERC20(tokenContract).transfer(owner(), dividend);
        }
    }

    function pledgeHandle(address account, uint256 amount) public override onlyTokenContract
    {
        if(account != owner()){
            uint256 accountBalance = amount;
            uint256 pledgeAmount = amount;
            if (!isPledge[account]) {
                pledgeAmount = accountBalance = inactivatedBalanceOf(account) + amount;
                require(accountBalance >= minimumPledgeAmount, "The pledge amount is too low");
            }
            require(totalSupply() + pledgeAmount <= pledgeCapacity, "The pledge capacity is full");
            _withdrawDividend(account);
            if (pledgeAmount > amount) {
                _burnInactivated(account, inactivatedBalanceOf(account));
                _mint(account, pledgeAmount);
            } else {
                _mint(account, amount);
            }
            emit Pledge(account, pledgeAmount);
            if (!isPledge[account]) {
                pledgeCount++;
                require(pledgeCount <= maximumPledgeAddressCount, "The pledge address count is full");
                isPledge[account] = true;
            }
        }
    }

    function getDividend(address account) public view returns (uint256 dividend){
        uint256 balance = super.balanceOf(account);
        uint256 dividends = ownerDividends[account];
        if (balance > 0) {
            dividends = totalDividends - dividends;
            dividend = (balance * dividends) / 1 ether;
        }
    }

    function _withdrawDividend(address account) internal {
        uint256 dividend = getDividend(account);
        if (dividend > 0) {
            _mint(account, dividend);
            emit DividendWithdrawal(account, dividend);
        }
        emit OwnerDividends(account, totalDividends, ownerDividends[account]);
        ownerDividends[account] = totalDividends;
    }

    function transfer(address to, uint256 value) public override returns (bool)
    {
        _transferHandle(_msgSender(), to, value);
        _transferAfter(_msgSender());
        return true;
    }

    function _transferHandle(address from, address to, uint256 value) internal
    {
        require(value > 0, "Amount must be greater than zero");
        if (!isPledge[from]) {
            _burnInactivated(from, value);
            emit InactivatedTransfer(from, to, value);
        } else {
            _withdrawDividend(from);
            _burn(from, value);
        }
        uint256 dividend = value * withdrawalFee / BASE_FEE;
        value -= dividend;
        IERC20(tokenContract).transfer(to, value);
        _addDividends(dividend);
        emit Withdrawal(from, to, value, dividend);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool)
    {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transferHandle(from, to, value);
        _transferAfter(from);
        return true;
    }


    function _transferAfter(address account) internal
    {
        uint256 balance = super.balanceOf(account);
        if (balance <= minimumPledgeAmount && isPledge[account]) {
            isPledge[account] = false;
            pledgeCount--;
            _burn(account, balance);
            _mintInactivated(account, balance);
        }
    }

}
