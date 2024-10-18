// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC314} from "./interface/IERC314.sol";
import {IPledge} from "./interface/IPledge.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MMM314 is ERC20, IERC314, Ownable
{
    bool public liquidityAdded;

    bool public tradingEnable;

    bool public pledgeTrigger;

    bool public lpBurnEnabled = true;

    bool public airdropEnabled;

    uint32 public lpBurnFrequency = 1 hours;

    uint32 public burnLpFee = 30;

    uint32 constant public BASE_FEE = 1e4;

    uint32 constant public officialFee = 100;

    uint32 constant public deadFee = 300;

    uint32 constant public dividendsFee = 600;

    uint256 public lastLpBurnTime;

    uint256 public maximumBuyAmountRate = 1000;

    uint256 public maximumHolding = 21e4 ether;

    uint256 public blockToUnlockLiquidity;

    uint256 public airdropAmount;

    address public liquidityProvider;

    address public officialAddress;

    address public pledgeAddress;

    address public deadAddress = address(0xdEaD);

    address public airdropAddress = address(0x314);

    mapping(address => bool) public airdropFlag;

    mapping(address => uint256) private lastTransaction;

    event Airdrop(address indexed account, uint256 indexed amount);

    modifier onlyLiquidityProvider() {
        require(
            _msgSender() == liquidityProvider,
            "You are not the liquidity provider"
        );
        _;
    }

    modifier swapRule(address account) {
        require(block.timestamp >= lastTransaction[account] + 60, "Sender must wait 60 seconds for swap time to cool down");
        lastTransaction[account] = block.timestamp;
        _;
    }

    constructor(
        address _pledgeAddress,
        address _officialAddress
    ) ERC20("MMM314", "MMM314")
    Ownable(_msgSender())
    {
        uint256 totalSupply_ = 21e6 ether;
        _mint(_msgSender(), totalSupply_ * 10 / 100);
        _mint(address(this), totalSupply_ * 90 / 100);
        pledgeAddress = _pledgeAddress;
        officialAddress = _officialAddress;
        lastLpBurnTime = block.timestamp;
    }

    function addLiquidity(
        uint256 _blockToUnlockLiquidity
    ) public override payable onlyOwner {
        require(liquidityAdded == false, "Liquidity already added");

        liquidityAdded = true;

        require(msg.value > 0, "No ETH sent");

        require(block.number < _blockToUnlockLiquidity, "Block number too low");

        blockToUnlockLiquidity = _blockToUnlockLiquidity;

        tradingEnable = true;

        liquidityProvider = _msgSender();

        emit AddLiquidity(_blockToUnlockLiquidity, msg.value);
    }

    function removeLiquidity() public override onlyLiquidityProvider {
        require(block.number > blockToUnlockLiquidity, "Liquidity locked");

        tradingEnable = false;

        payable(_msgSender()).transfer(address(this).balance);

        emit RemoveLiquidity(address(this).balance);
    }

    function extendLiquidityLock(
        uint256 _blockToUnlockLiquidity
    ) public override onlyLiquidityProvider {
        require(
            blockToUnlockLiquidity < _blockToUnlockLiquidity,
            "You can't shorten duration"
        );
        blockToUnlockLiquidity = _blockToUnlockLiquidity;
    }

    function getReserves() public override view returns (uint256, uint256) {
        return (address(this).balance, balanceOf(address(this)));
    }

    function getFeeTotal(uint256 value) public pure returns (uint256 amount)
    {
        uint256 officialFeeAmount = (value * officialFee) / BASE_FEE;
        uint256 deadFeeAmount = (value * deadFee) / BASE_FEE;
        uint256 dividendsFeeAmount = (value * dividendsFee) / BASE_FEE;
        if (officialFeeAmount > 0) {
            value -= officialFeeAmount;
        }
        if (deadFeeAmount > 0) {
            value -= deadFeeAmount;
        }
        if (dividendsFeeAmount > 0) {
            value -= dividendsFeeAmount;
        }
        return value;
    }


    function _officialFeeHandle(uint256 value) internal returns (uint256)
    {
        uint256 officialFeeAmount = (value * officialFee) / BASE_FEE;
        if (officialFeeAmount > 0) {
            _transfer(address(this), officialAddress, officialFeeAmount);
        }
        return officialFeeAmount;
    }

    function _deadFeeHandle(uint256 value) internal returns (uint256)
    {
        uint256 deadFeeAmount = (value * deadFee) / BASE_FEE;
        if (deadFeeAmount > 0) {
            _transfer(address(this), deadAddress, deadFeeAmount);
        }
        return deadFeeAmount;
    }

    function _dividendsFeeHandle(uint256 value) internal returns (uint256)
    {
        uint256 dividendsFeeAmount = (value * dividendsFee) / BASE_FEE;
        if (dividendsFeeAmount > 0) {
            if (pledgeTrigger) {
                _transfer(address(this), pledgeAddress, dividendsFeeAmount);
                IPledge(pledgeAddress).dividendHandle(dividendsFeeAmount);
            } else {
                _transfer(address(this), officialAddress, dividendsFeeAmount);
            }
        }
        return dividendsFeeAmount;
    }

    function _feeHandle(uint256 tokenAmount) internal returns (uint256)
    {
        uint256 officialFeeAmount = _officialFeeHandle(tokenAmount);

        uint256 deadFeeAmount = _deadFeeHandle(tokenAmount);

        uint256 dividendsFeeAmount = _dividendsFeeHandle(tokenAmount);

        if (officialFeeAmount > 0) {
            tokenAmount -= officialFeeAmount;
        }
        if (deadFeeAmount > 0) {
            tokenAmount -= deadFeeAmount;
        }
        if (dividendsFeeAmount > 0) {
            tokenAmount -= dividendsFeeAmount;
        }
        return tokenAmount;
    }

    function _pledgeHandle(address account, uint256 amount) internal {
        _transfer(account, pledgeAddress, amount);
        IPledge(pledgeAddress).pledgeHandle(account, amount);
        if (!pledgeTrigger) {
            pledgeTrigger = true;
        }
    }

    function getAmountOut(uint256 value, bool buy_) public override view returns (uint256 amount) {
        if (value == 0) {
            return value;
        }
        (uint256 ethAmount, uint256 tokenAmount) = getReserves();
        if (buy_) {
            amount = (value * tokenAmount) / (ethAmount + value);
            amount = getFeeTotal(amount);
        } else {
            value = getFeeTotal(value);
            amount = (value * ethAmount) / (tokenAmount + value);
        }
    }

    function _buy() internal swapRule(_msgSender()) {
        require(tradingEnable, 'Trading not enable');

        uint256 ethAmount = msg.value;

        uint256 ethContractAmount = address(this).balance;

        require(ethAmount <= ((ethContractAmount - ethAmount) * maximumBuyAmountRate / BASE_FEE), 'Buy amount too high');

        uint256 buyAmount = ethAmount * balanceOf(address(this)) / ethContractAmount;

        buyAmount = _feeHandle(buyAmount);

        require(buyAmount + balanceOf(_msgSender()) <= maximumHolding, 'Max wallet exceeded');

        _transfer(address(this), _msgSender(), buyAmount);

        emit Swap(_msgSender(), ethAmount, 0, 0, buyAmount);
    }

    function _sell(address account, uint256 sellAmount) internal swapRule(account) {
        require(tradingEnable, 'Trading not enable');

        _transfer(account, address(this), sellAmount);

        sellAmount = _feeHandle(sellAmount);

        uint256 ethAmount = sellAmount * address(this).balance / balanceOf(address(this));

        require(ethAmount > 0, 'Sell amount too low');

        require(address(this).balance >= ethAmount, 'Insufficient ETH in reserves');

        payable(account).transfer(ethAmount);

        emit Swap(account, 0, sellAmount, ethAmount, 0);
    }

    function setAutoLPBurnSettings(
        uint32 _lpBurnFrequency,
        uint32 _burnLpFee,
        bool _Enabled
    ) external onlyLiquidityProvider {
        require(_burnLpFee <= burnLpFee, "fee too high");
        require(_lpBurnFrequency >= lpBurnFrequency, "frequency too short");
        lpBurnFrequency = _lpBurnFrequency;
        burnLpFee = _burnLpFee;
        lpBurnEnabled = _Enabled;
    }

    function setPledgeAddress(address pledgeAddress_) public onlyLiquidityProvider {
        require(pledgeAddress_ != pledgeAddress, "set pledgeAddress error");
        pledgeAddress = pledgeAddress_;
    }

    function addAirdrop(uint256 amount,uint256 count, bool airdropEnabled_) public onlyLiquidityProvider
    {
        if(airdropEnabled_){
            airdropAmount = amount;
            _transfer(_msgSender(), airdropAddress, amount * count);
        }
        airdropEnabled = airdropEnabled_;
    }

    function _airdropHandle(address account) internal
    {
        require(airdropEnabled, "airdrop not enabled");
        require(airdropAmount > 0, "airdrop amount error");
        require(!airdropFlag[account], "Airdrop has been received");
        require(balanceOf(airdropAddress) >= airdropAmount, "airdrop amount error");
        _transfer(airdropAddress, account, airdropAmount);
        if(balanceOf(airdropAddress) < airdropAmount){
            airdropEnabled = false;
        }
        emit Airdrop(account, airdropAmount);
    }

    function _autoBurnLiquidityPairTokens() internal {
        if (lpBurnEnabled && block.timestamp >= lastLpBurnTime + lpBurnFrequency) {
            lastLpBurnTime = block.timestamp;
            uint256 liquidityPairBalance = balanceOf(address(this));

            uint256 amountToBurn = liquidityPairBalance * burnLpFee / BASE_FEE;
            if (amountToBurn > 0) {
                _transfer(address(this), deadAddress, amountToBurn);
                emit AutoBurnLP(liquidityPairBalance, amountToBurn, block.timestamp);
            }
        }
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        if (to == address(this)) {
            _sell(from, value);
        } else if (to == pledgeAddress) {
            _pledgeHandle(from, value);
        } else if (to == airdropAddress) {
            _airdropHandle(from);
        } else {
            _transfer(from, to, value);
        }
        _autoBurnLiquidityPairTokens();
        return true;
    }


    function transfer(address to, uint256 value) public override returns (bool)
    {
        if (to == address(this)) {
            _sell(_msgSender(), value);
        } else if (to == pledgeAddress) {
            _pledgeHandle(_msgSender(), value);
        } else if (to == airdropAddress) {
            _airdropHandle(_msgSender());
        } else {
            _transfer(_msgSender(), to, value);
        }
        _autoBurnLiquidityPairTokens();
        return true;
    }


    receive() external payable {
        _buy();
    }
}