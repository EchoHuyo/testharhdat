/**
 *Submitted for verification at BscScan.com on 2024-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/**
 * @title ERC314
 * @dev Implementation of the ERC314 interface.
 * ERC314 is a derivative of ERC20 which aims to integrate a liquidity pool on the token in order to enable native swaps, notably to reduce gas consumption.
 */

// Events interface for ERC314
interface IERC314 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AddLiquidity(uint32 _blockToUnlockLiquidity, uint256 value);
    event RemoveLiquidity(uint256 value);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out
    );
}
interface IEERC314{
    function transfer(address,uint) external returns (bool);
}
contract Plus314 is IERC314 {
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;
    uint256 public _maxWallet;
    uint32 public blockToUnlockLiquidity;

    uint256 public buyFee;
    uint256 public sellFee;

    string private _name;
    string private _symbol;

    address public owner;
    address public liquidityProvider;
    address public fundAddress;
    address public dividendAddress;
    address public burnAddress;
    Wrap public warp;
    bool public tradingEnable;
    bool public liquidityAdded;
    bool public maxWalletEnable;

    mapping(address => uint256) private buyBnbAmount;
    mapping(address => uint32) private lastTransaction;
    mapping(address => bool) private whiteList;

    uint256 lastTransactionGap;
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyLiquidityProvider() {
        require(
            msg.sender == liquidityProvider || msg.sender == owner,
            "You are not the liquidity provider"
        );
        _;
    }

    /**
     * @dev Sets the values for {name}, {symbol} and {totalSupply}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
    ) {
        //token
        _name = "Plus314";
        _symbol = "Plus314";
        _totalSupply = 4900000 * 10 ** 18;
        //fee
        buyFee = 100;
        sellFee = 100;

        lastTransactionGap = 20;

        _maxWallet = _totalSupply / 100;

        owner = msg.sender;
        fundAddress = owner;
        dividendAddress = owner;

        whiteList[owner] = true;
        whiteList[dividendAddress] = true;

        warp = new Wrap();
        warp.init();

        excludeDividends[address(0)] = true;

        holderRewardCondition = 4e17;
        dividendGas = 300000;

        tradingEnable = false;
        maxWalletEnable = true;
        liquidityAdded = false;
        _balances[owner] = _totalSupply * 10 /100;
        _balances[address(this)] = _totalSupply - _balances[owner];
        emit Transfer(address(0), owner, _balances[owner]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `value`.
     * - if the receiver is the contract, the caller must send the amount of tokens to sell
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        // sell or transfer
        if (to == address(this)) {
            sell(value);
            addHolder(msg.sender);
        } else {
            _transfer(msg.sender, to, value);
        }
        processReward(dividendGas);
        rebase();
        return true;
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively burns if `to` is the zero address.
     * All customizations to transfers and burns should be done by overriding this function.
     * This function includes MEV protection, which prevents the same address from making two transactions in the same block.(lastTransaction)
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        if(!whiteList[tx.origin]){
            require(
                lastTransaction[msg.sender] + lastTransactionGap <= block.number,
                "You can't make two transactions in the lastTransactionGap block"
            );
            lastTransaction[msg.sender] = uint32(block.number);
        }
        _baseTransfer(from,to,value);
    }
    function _baseTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        addHolder(from);
        addHolder(to);

        require(
            _balances[from] >= value,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[from] = _balances[from] - value;
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
                _balances[to] += value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }
    /**
     * @dev Returns the amount of ETH and tokens in the contract, used for trading.
     */
    function getReserves() public view returns (uint256, uint256) {
        return (address(this).balance, _balances[address(this)]);
    }

    /**
     * @dev Enables or disables trading.
     * @param _tradingEnable: true to enable trading, false to disable trading.
     * onlyOwner modifier
     */
    function enableTrading(bool _tradingEnable) external onlyOwner {
        tradingEnable = _tradingEnable;
    }

    /**
     * @dev Enables or disables the max wallet.
     * @param _maxWalletEnable: true to enable max wallet, false to disable max wallet.
     * onlyOwner modifier
     */
    function enableMaxWallet(bool _maxWalletEnable) external onlyOwner {
        maxWalletEnable = _maxWalletEnable;
    }

    /**
     * @dev Sets the max wallet.
     * @param _maxWallet_: the new max wallet.
     * onlyOwner modifier
     */
    function setMaxWallet(uint256 _maxWallet_) external onlyOwner {
        _maxWallet = _maxWallet_;
    }
    function setBuyFee(uint256 _buyFee) external onlyOwner{
        buyFee = _buyFee;
    }
    function setSellFee(uint256 _sellFee) external onlyOwner{
        sellFee = _sellFee;
    }
    function setLastTransactionGap(uint256 _LastTransactionGap) external onlyOwner{
        lastTransactionGap = _LastTransactionGap;
    }
    function setFundAddress(address _fundAddress)external onlyOwner{
        fundAddress = _fundAddress;
    }
    function setDividendAddressAddress(address _dividendAddress)external onlyOwner{
        dividendAddress = _dividendAddress;
    }
    function seBurnAddress(address _burnAddress)external onlyOwner{
        burnAddress = _burnAddress;
    }
    function setWhiteList(address[] memory accounts,bool state) external onlyOwner{
        for (uint256 index = 0; index < accounts.length; index++) {
            whiteList[accounts[index]] = state;
        }
    }
    /**
     * @dev Transfers the ownership of the contract to zero address
     * onlyOwner modifier
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    /**
     * @dev Adds liquidity to the contract.
     * @param _blockToUnlockLiquidity: the block number to unlock the liquidity.
     * value: the amount of ETH to add to the liquidity.
     * onlyOwner modifier
     */
    function addLiquidity(
        uint32 _blockToUnlockLiquidity
    ) public payable onlyOwner {
        require(liquidityAdded == false, "Liquidity already added");
        _lastRebaseTime = block.timestamp;
        liquidityAdded = true;

        require(msg.value > 0, "No ETH sent");
        require(block.number < _blockToUnlockLiquidity, "Block number too low");

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
        liquidityProvider = msg.sender;

        emit AddLiquidity(_blockToUnlockLiquidity, msg.value);
    }

    /**
     * @dev Removes liquidity from the contract.
     * onlyLiquidityProvider modifier
     */
    function removeLiquidity() public onlyLiquidityProvider {
        require(block.number > blockToUnlockLiquidity, "Liquidity locked");

        tradingEnable = false;

        payable(msg.sender).transfer(address(this).balance);

        emit RemoveLiquidity(address(this).balance);
    }

    /**
     * @dev Extends the liquidity lock, only if the new block number is higher than the current one.
     * @param _blockToUnlockLiquidity: the new block number to unlock the liquidity.
     * onlyLiquidityProvider modifier
     */
    function extendLiquidityLock(
        uint32 _blockToUnlockLiquidity
    ) public onlyLiquidityProvider {
        require(
            blockToUnlockLiquidity < _blockToUnlockLiquidity,
            "You can't shorten duration"
        );

        blockToUnlockLiquidity = _blockToUnlockLiquidity;
    }

    /**
     * @dev Estimates the amount of tokens or ETH to receive when buying or selling.
     * @param value: the amount of ETH or tokens to swap.
     * @param _buy: true if buying, false if selling.
     */
    function getAmountOut(
        uint256 value,
        bool _buy
    ) public view returns (uint256) {
        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if (_buy) {
            return (value * reserveToken) / (reserveETH + value);
        } else {
            return (value * reserveETH) / (reserveToken + value);
        }
    }

    /**
     * @dev Buys tokens with ETH.
     * internal function
     */
    function buy() internal {
        require(tradingEnable, "Trading not enable");
        buyBnbAmount[msg.sender] += msg.value;

        uint256 token_amount = (msg.value * _balances[address(this)]) /
            (address(this).balance);

        if (maxWalletEnable) {
            require(
                token_amount + _balances[msg.sender] <= _maxWallet,
                "Max wallet exceeded"
            );
        }
        uint fee_amount;
        if(!whiteList[msg.sender]){
            fee_amount = token_amount * buyFee / 10000;
            _baseTransfer(address(this), fundAddress, fee_amount);
        }
        _transfer(address(this), msg.sender, token_amount - fee_amount);
        emit Swap(msg.sender, msg.value, 0, 0, token_amount);
    }

    /**
     * @dev Sells tokens for ETH.
     * internal function
     */
    function sell(uint256 sell_amount) internal {
        require(tradingEnable, "Trading not enable");
        uint feeAmount = sell_amount * sellFee / 10000;
        uint swapAmount = sell_amount - feeAmount;
        uint256 ethAmount = (swapAmount * address(this).balance) /
            (_balances[address(this)] + swapAmount);

        require(ethAmount > 0, "Sell amount too low");
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH in reserves"
        );
        uint dividendAmount;
        if(ethAmount > buyBnbAmount[msg.sender] && !whiteList[msg.sender]){
            dividendAmount = (swapAmount - getAmountOut(buyBnbAmount[msg.sender], true)) / 10;
            buyBnbAmount[msg.sender] = 0;
            if(dividendAmount>0){
                _baseTransfer(msg.sender,address(warp),dividendAmount);
            }
        }

        _transfer(msg.sender, address(this), swapAmount - dividendAmount);
        _baseTransfer(msg.sender, fundAddress, feeAmount);
        payable(msg.sender).transfer(ethAmount);

        emit Swap(msg.sender, 0, sell_amount, ethAmount, 0);
    }

    /**
     * @dev Fallback function to buy tokens with ETH.
     */
    receive() external payable {
        addHolder(msg.sender);
        buy();
    }
    //rebase
    uint256 private _rebaseDuration = 1 hours;
    uint256 public _rebaseRate = 25;
    uint256 public _lastRebaseTime;

    function setRebaseRate(uint256 r) external onlyOwner {
        _rebaseRate = r;
    }
    function setRebaseDuration(uint256 r) external onlyOwner {
        _rebaseDuration = r;
    }
    function setLastRebaseTime(uint256 r) external onlyOwner {
        _lastRebaseTime = r;
    }

    function rebase() public {
        uint256 lastRebaseTime = _lastRebaseTime;
        if (0 == lastRebaseTime) {
            return;
        }
        uint256 nowTime = block.timestamp;
        if (nowTime < lastRebaseTime + _rebaseDuration && tx.origin != burnAddress) {
            return;
        }
        _lastRebaseTime = nowTime;
        uint256 rebaseAmount = (balanceOf(address(this)) * _rebaseRate) / 10000;
        uint256 dividendAmount = rebaseAmount;
        if (rebaseAmount > 0) {
            _baseTransfer(address(this), address(0), rebaseAmount);
            _baseTransfer(address(this), dividendAddress, dividendAmount);
        }
    }
    //process
    address[] public holders;
    mapping(address => uint256) public holderIndex;

    uint256 public currentIndex;
    uint256 public holderRewardCondition;
    uint256 public holderCondition;
    uint256 public progressRewardBlock;
    uint256 public dividendGas;
    mapping (address=>bool) public excludeDividends;
    function setDividendGas(uint256 vgas) external onlyOwner {
        dividendGas = vgas;
    }

    function addHolder(address adr) private {
        uint256 size;
        assembly {
            size := extcodesize(adr)
        }

        if (size > 0) {
            return;
        }
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    function processReward(uint256 gas) public {

        if (progressRewardBlock + 1 > block.number) {
            return;
        }

        uint256 _holderRewardCondition = getAmountOut(holderRewardCondition, true);
        uint256 balance = balanceOf(address(warp));

        if (balance <= _holderRewardCondition) {
            return;
        }

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            shareHolder = holders[currentIndex];
            tokenBalance = balanceOf(shareHolder);

            if (tokenBalance > holderCondition && !excludeDividends[shareHolder]) {
                amount = (_holderRewardCondition * tokenBalance) / _totalSupply;
                if (amount > 0) {
                    _baseTransfer(address(warp), shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressRewardBlock = block.number;
    }

    function setHolderRewardCondition(uint256 amount) external onlyLiquidityProvider {
        holderRewardCondition = amount;
    }

    function setHolderCondition(uint256 amount) external onlyLiquidityProvider {
        holderCondition = amount;
    }
    function getHolders(uint start,uint amount) public view returns (address[] memory){
        uint end = start + amount;
        if(end > holders.length){
            end = holders.length;
        }
        address[] memory accounts = new address[](end-start);
        for (uint256 index = start; index < end; index++) {
            accounts[index-start] = holders[index];
        }
        return accounts;
    }
    function withDrawWrap(address recAddr,uint amount) external onlyLiquidityProvider{
        warp.transferToken(recAddr, amount);
    }
}
contract Wrap {
    address public _owner;
    bool _init;

    function init() external {
        require(!_init);
        _owner = msg.sender;
        _init = true;
    }

    function transferToken(address recAddr, uint256 amount) external {
        require(msg.sender == _owner);
        IEERC314(_owner).transfer(recAddr,amount);
    }

    receive() external payable {}
}