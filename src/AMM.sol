//SPDX-License-Identifer: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AMM {
    uint256 totalLiquidity;
    IERC20 tokenA;
    IERC20 tokenB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function swapAtoB(uint256 amountSwapped) external {
        // transfer tokenA to this contract
        tokenA.transferFrom(msg.sender, address(this), amountSwapped);
        // calculate amount of token B to swap Ydx/(X+DX)
        (uint256 amountA, uint256 amountB) = calculateInitialValues();
        uint256 amountBtoReturn = calculateAmountToSwap(amountSwapped, amountA, amountB);
        // transfer tokenB to msg.sender
        tokenB.transfer(msg.sender, amountBtoReturn);
    }

    function addLiquidity() external {
        // transfer token from msg.sender to address(this)
        // adjust totalLiquidity sqrt(XY)
    }
    function removeLiquidity() external {
        // transfer token from address(this) to msg.sender
        // adjust totalLiquidity sqrt(XY)
    }
    function sqrt() internal pure {}
    function calculatetotalLiquidity() public {}

    function calculateAmountToSwap(
        uint256 amountswapped,
        uint256 initialAmountofSwappedToken,
        uint256 initialAmountOfReturnedToken
    ) public pure returns (uint256) {
        // uint256 dx = amountswapped;
        // uint256 x = initialAmountofSwappedToken;
        // uint256 y = initialAmountOfReturnedToken;
        // return (dx * y) / (x + dx);
        return (amountswapped * initialAmountOfReturnedToken) / (amountswapped + initialAmountofSwappedToken);
    }
    // function to return amount of tokenA and tokenB in contract

    function calculateInitialValues() public view returns (uint256 amountA, uint256 amountB) {
        amountA = tokenA.balanceOf(address(this));
        amountB = tokenB.balanceOf(address(this));
        return (amountA, amountB);
    }
}
