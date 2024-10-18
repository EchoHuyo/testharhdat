// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPledge{

    function pledgeHandle(address owner, uint256 amount) external;

    function dividendHandle(uint256 dividend) external;

    event Pledge(address indexed owner,uint256 indexed value);

    event Dividend(uint256 indexed dividend,uint256 indexed dividends,uint256 indexed totalDividends,uint256  pledgeTotal,uint256 blockNumber);

    event Withdrawal(address indexed owner,address indexed to,uint256 indexed value,uint256 dividend);

    event DividendWithdrawal(address indexed owner,uint256 indexed value);

    event OwnerDividends(address indexed owner,uint256 indexed newDividends,uint256 indexed lodDividends);

    event InactivatedTransfer(address indexed from, address indexed to, uint256 value);

    event Inactivated(address indexed owner,uint256 indexed value,bool indexed toInactivated);
}