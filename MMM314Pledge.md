# 中文
## 质押合约描述
1. 质押合约本质上是一个代币合约(ERC20合约)
2. 质押合约上显示的余额即钱包地址的MMM314币余额
3. 合约地址: 0x65C195D8ba72F492dEe6A916Af91f79370428CfD
4. 发行链: BSC
## 质押和提现流程
1. 质押 用户通过MMM314代币合约往质押合约转MMM314代币，即完成质押
2. 提现 用户在质押合约上向钱包地址转账即完成提现
## 质押限制
1. 初次钱包地址质押需要质押不少于21000枚MMM314代币
2. 全网质押地址总数为300个地址
3. 全网质押总量不超过700W枚MMM314代币
4. 钱包地址质押余额不超过21000枚MMM314代币时不产生分红
## 质押数据查询
1. 全网质押总量即质押合约上totalSupply
## 质押权益
1. MMM314代币发生交易时，会有6%的分红
2. 质押合约提现时，会有3%的分红
3. 官方不定时发放分红
4. 官方下期项目会优先空投代币在正在质押的钱包地址
## 质押规则
1. 钱包地址质押余额不超过21000枚MMM314代币时不产生分红
2. 当钱包地址提现后，如果钱包地址质押余额不超过21000枚MMM314代币时，将被定义为未激活质押钱包地址
3. 激活质押，激活条件为：钱包地址质押余额超过21000枚MMM314代币时开始分红
4. 未激活钱包地址的余额不会计算在全网质押总量中
5. 当全网质押量大于0时，开始分红
6. 分红算法：当时分红数量 * 钱包质押量 / 全网质押总量
7. 钱包地址提现时，会被收取3%的手续费用于分红
8. 分红实时到账钱包地址质押余额

# English

## Pledge Contract Description
1. The pledge contract is essentially a token contract (ERC20 contract)
2. The balance displayed on the pledge contract is the MMM314 coin balance of the wallet address.
3. Contract address: 0x65C195D8ba72F492dEe6A916Af91f79370428CfD
4. Issuance chain: BSC
## Pledge and withdrawal process
1. Pledge: The user transfers MMM314 tokens to the pledge contract through the MMM314 token contract, which completes the pledge.
2. Withdrawal: The user completes the withdrawal by transferring money to the wallet address on the pledge contract.
## Staking restrictions
1. The initial wallet address pledge requires no less than 21,000 MMM314 tokens.
2. The total number of pledged addresses in the entire network is 300 addresses
3. The total amount of pledges in the entire network shall not exceed 7 million MMM314 tokens.
4. No dividends will be generated when the pledge balance of the wallet address does not exceed 21,000 MMM314 tokens.
## Pledge data query
1. The total amount of pledges in the entire network is the totalSupply on the pledge contract
## Pledge interests
1. When MMM314 tokens are traded, there will be a 6% dividend
2. When withdrawing the pledged contract, there will be a 3% dividend.
3. Official dividends are distributed from time to time
4. The official next phase of the project will give priority to airdrop tokens to the wallet address that is being pledged.
## Pledge rules
1. No dividends will be generated when the pledge balance of the wallet address does not exceed 21,000 MMM314 tokens.
2. After the wallet address is withdrawn, if the pledge balance of the wallet address does not exceed 21,000 MMM314 tokens, it will be defined as an inactive pledge wallet address.
3. Activate staking. The activation conditions are: dividends will begin when the pledge balance of the wallet address exceeds 21,000 MMM314 tokens.
4. The balance of unactivated wallet addresses will not be calculated in the total amount of pledges on the entire network.
5. When the pledge amount of the entire network is greater than 0, dividends will start
6. Dividend algorithm: current dividend amount * wallet pledge amount / total network pledge amount
7. When withdrawing money from the wallet address, a 3% handling fee will be charged for dividends.
8. Dividends will be credited to the wallet address pledge balance in real time