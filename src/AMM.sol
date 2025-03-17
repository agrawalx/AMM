//SPDX-License-Identifer: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AMM {
    error AMM__IncorrectRatioProvided();
    error AMM__sharesExceedBalance();

    mapping(address shareholder => uint256 amountofshare) private s_balances;
    uint256 totalLiquidity;
    uint256 shareCount;
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
        (uint256 reserveOfTokenA, uint256 reserveOfTokenB) = calculateInitialValues(address(tokenA));
        // ensure proper ratio of X & Y are added
        if (amountA * reserveOfTokenB != reserveOfTokenA * amountB) {
            revert AMM__IncorrectRatioProvided();
        }
        // calcuate shares to mint
        uint256 initialShares = getInitialShares();
        uint256 sharesToMint = (amountA * initialShares) / reserveOfTokenA;
        // mint & transfer shares
        s_balances[msg.sender] += sharesToMint;
        shareCount += sharesToMint;
        // transfer token from msg.sender to address(this)
        tokenB.transferFrom(msg.sender, address(this), amountB);
        tokenA.transferFrom(msg.sender, address(this), amountA);

        // adjust totalLiquidity sqrt(XY)
        uint256 finalLiquidity = updateorGetLiquidity();
    }

    function removeLiquidity(uint256 amountShares) external {
        if (s_balances[msg.sender] < amountShares) {
            revert AMM__sharesExceedBalance();
        }
        // calculate amount of token to return
        uint256 initialshares = getInitialShares();
        (uint256 amountA, uint256 amountB) = calculateInitialValues(address(tokenA));
        (uint256 dx, uint256 dy) = ((amountA * amountShares) / initialshares, (amountB * amountShares) / initialshares);
        // transfer token from address(this) to msg.sender
        tokenA.transfer(msg.sender, dx);
        tokenB.transfer(msg.sender, dy);
        // remove shares
        s_balances[msg.sender] -= amountShares;
        // adjust totalLiquidity sqrt(XY)
        uint256 finalLiquidity = updateorGetLiquidity();
    }

    // babylonian square root method
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        uint256 y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y;
    }

    function updateorGetLiquidity() public returns (uint256) {
        (uint256 amountA, uint256 amountB) = calculateInitialValues(address(tokenA));
        uint256 product = amountA * amountB;
        uint256 liquidity = sqrt(product);
        totalLiquidity = liquidity;
        return totalLiquidity;
    }

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

    function getInitialShares() internal view returns (uint256) {
        return shareCount;
    }
}
