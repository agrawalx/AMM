//SPDX-License-Identifier : MIT
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
        amm.initialLiquidity(10000 * 1e18, 10000 * 1e18);
    }

    function testInitialLiquidity() public {
        uint256 liquidity = amm.updateorGetLiquidity();
        assertEq(liquidity, 10000 * 1e18);
    }

    function invariant_Swap() public {
        // contract must have some tokenA & tokenB
        // send some amount of tokenA and calculate how many tokenB should be returned
        (uint256 initial_amountA, uint256 initial_amountB) = amm.calculateInitialValues(address(tokenA));
        uint256 product = initial_amountA * initial_amountB;
        tokenA.mint(PERSON, INITIAL_BALANCE);
        vm.startPrank(PERSON);
        tokenA.approve(address(amm), INITIAL_BALANCE);
        amm.swap(address(tokenA), INITIAL_DEPOSIT);
        (uint256 final_amountA, uint256 final_amountB) = amm.calculateInitialValues(address(tokenA));
        uint256 finalProduct = final_amountA * final_amountB;
        assert(tokenA.balanceOf(PERSON) == INITIAL_BALANCE - INITIAL_DEPOSIT);
        console.log(tokenB.balanceOf(PERSON));
        console.log(product, finalProduct);
        assert(finalProduct >= product);
        vm.stopPrank();
        // assert if amount returned is equal to calculated amount
        // amount returned = 10000*1e18 * 100 /(10100)
    }

    function testIfAddLiquidityRevertsOnWrongRatio() public {
        tokenA.mint(PERSON, INITIAL_BALANCE);
        tokenB.mint(PERSON, INITIAL_BALANCE);
        vm.startPrank(PERSON);
        tokenA.approve(address(amm), INITIAL_BALANCE);
        tokenB.approve(address(amm), INITIAL_BALANCE);
        vm.expectRevert(AMM.AMM__IncorrectRatioProvided.selector);
        amm.addLiquidity(INITIAL_BALANCE, INITIAL_BALANCE - (10 ether));
        vm.stopPrank();
    }

    function invariant_AddLiquidity() public {
        // contract must have some tokenA & tokenB
        (uint256 initial_amountA, uint256 initial_amountB) = amm.calculateInitialValues(address(tokenA));
        uint256 product = initial_amountA * initial_amountB;
        tokenA.mint(PERSON, INITIAL_BALANCE);
        tokenB.mint(PERSON, INITIAL_BALANCE);
        vm.startPrank(PERSON);
        tokenA.approve(address(amm), INITIAL_BALANCE);
        tokenB.approve(address(amm), INITIAL_BALANCE);
        amm.addLiquidity(INITIAL_DEPOSIT, INITIAL_DEPOSIT);
        (uint256 final_amountA, uint256 final_amountB) = amm.calculateInitialValues(address(tokenA));
        uint256 finalProduct = final_amountA * final_amountB;
        assert(tokenA.balanceOf(PERSON) == INITIAL_BALANCE - INITIAL_DEPOSIT);
        assert(tokenB.balanceOf(PERSON) == INITIAL_BALANCE - INITIAL_DEPOSIT);
        uint256 totalShares = amm.getInitialShares();
        uint256 sharesToMint = (INITIAL_DEPOSIT * (totalShares)) / (initial_amountA);
        assert(amm.getShareHolding(PERSON) == sharesToMint);
        console.log(product, finalProduct);
        assert(finalProduct >= product);
        vm.stopPrank();
    }
}
