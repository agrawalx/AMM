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

    function selectWhichTokenIsSwapped(address token) internal view returns (address tokenOut) {
        if (token == address(tokenA)) {
            return (address(tokenB));
        } else {
            return (address(tokenA));
        }
    }

    function swap(address tokenSwapped, uint256 amountSwapped) external {
        address tokenToReturn = selectWhichTokenIsSwapped(tokenSwapped);

        // transfer tokenA to this contract
        // calculate amount of token B to swap Ydx/(X+DX)
        (uint256 reserveOfTokenSwapped, uint256 reserveOfTokenReturned) = calculateInitialValues(tokenSwapped);
        uint256 amounttoReturn = calculateAmountToSwap(amountSwapped, reserveOfTokenSwapped, reserveOfTokenReturned);
        // transfer tokenB to msg.sender
        IERC20(tokenSwapped).transferFrom(msg.sender, address(this), amountSwapped);
        IERC20(tokenToReturn).transfer(msg.sender, amounttoReturn);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        // ensure proper ratio of X & Y are added

        // transfer token from msg.sender to address(this)
        tokenB.transferFrom(msg.sender, address(this), amountB);
        tokenA.transferFrom(msg.sender, address(this), amountA);
        // adjust totalLiquidity sqrt(XY)
    }

    function removeLiquidity(uint256 amount, address token) external {
        // transfer token from address(this) to msg.sender
        IERC20(token).transfer(msg.sender, amount);
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

    function calculateInitialValues(address tokenSwapped)
        public
        view
        returns (uint256 reserveOfSwappedToken, uint256 reserveOfReturnedToken)
    {
        uint256 amountA = tokenA.balanceOf(address(this));
        uint256 amountB = tokenB.balanceOf(address(this));
        if (tokenSwapped == address(tokenA)) {
            return (amountA, amountB);
        } else {
            return (amountB, amountA);
        }
    }
}
