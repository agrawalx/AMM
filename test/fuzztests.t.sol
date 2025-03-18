//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployAMM} from "../script/DeployAMM.s.sol";
import {AMM} from "../src/AMM.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract testAMM is Test {
    DeployAMM deployer;
    AMM amm;
    ERC20Mock tokenA;
    ERC20Mock tokenB;
    address public PERSON = makeAddr("Person");
    uint256 public INITIAL_BALANCE = 1000 ether;
    uint256 public INITIAL_DEPOSIT = 100 ether;

    function setUp() external {
        deployer = new DeployAMM();
        (amm, tokenA, tokenB) = deployer.run();
        // sets up the contract with initial liquidity
        tokenA.mint(address(this), 20000 * 1e18);
        console.log(tokenA.balanceOf(address(this)));
        tokenB.mint(address(this), 20000 * 1e18);
        tokenA.approve(address(amm), 20000 * 1e18);
        tokenB.approve(address(amm), 20000 * 1e18);
        amm.initialLiquidity(INITIAL_BALANCE, INITIAL_BALANCE);
    }

    function testSwap(uint256 amount) public {
        vm.assume(amount > 0 && amount < INITIAL_DEPOSIT);
        amm.swap(address(tokenA), amount);
    }

    function testaddLiquidity(uint256 amount) public {
        vm.assume(amount > 0 && amount < 1000 ether);
        uint256 initialLiquidity = amm.updateorGetLiquidity();
        amm.addLiquidity(amount, amount);
        uint256 liquidity = amm.updateorGetLiquidity();
        assert(liquidity > initialLiquidity);
    }
}
