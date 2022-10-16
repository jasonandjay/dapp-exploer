# AAVE V2版本闪电贷
## 流程
    借贷->投资->赎回->归还
## 入口合约
    BatchFlashDemo.sol

## 部署物料
- 网络Goerli测试网
- 部署工具MetaMask
- 部署时传入AAVE V2 LendingPoolAddressesProvider: 0x5E52dEc931FFb32f609681B8438A51c675cc232d
- V2没有部署水龙头合约，手动转入资金：10aave,10link和10dai
- 执行闪电贷：executeFlasLoans(200000000000000000000, 200000000000000000000, 200000000000000000000)
- 查看交易Tx