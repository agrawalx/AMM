//SPDX-License-Identifer: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract AMM is ReentrancyGuard {
    error AMM__IncorrectRatioProvided();
    error AMM__sharesExceedBalance();
    error AMM__mustBeMoreThanZero();
    error AMM__alreadyContainsLiquidity();
    error AMM__NotValidToken();

    mapping(address shareholder => uint256 amountofshare) private s_balances;
    uint256 totalLiquidity;
    uint256 shareCount;
    IERC20 tokenA;
    IERC20 tokenB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert AMM__mustBeMoreThanZero();
        }
        _;
    }

    modifier ValidToken(address token) {
        if (token != address(tokenA) && token != address(tokenB)) {
            revert AMM__NotValidToken();
        }
        _;
    }

    function initialLiquidity(uint256 amountA, uint256 amountB)
        public
        moreThanZero(amountA)
        moreThanZero(amountB)
        nonReentrant
    {
        (uint256 reserveOfTokenA, uint256 reserveOfTokenB) = calculateInitialValues(address(tokenA));
        if (reserveOfTokenA != 0 || reserveOfTokenB != 0) {
            revert AMM__alreadyContainsLiquidity();
        }
        shareCount = sqrt(amountA * amountB);
        s_balances[msg.sender] += shareCount;

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        uint256 initialLiquidity = updateorGetLiquidity();
    }

    function selectWhichTokenIsSwapped(address token) internal view returns (address tokenOut) {
        if (token == address(tokenA)) {
            return (address(tokenB));
        } else {
            return (address(tokenA));
        }
    }

    function swap(address tokenSwapped, uint256 amountSwapped)
        external
        nonReentrant
        moreThanZero(amountSwapped)
        ValidToken(tokenSwapped)
    {
        address tokenToReturn = selectWhichTokenIsSwapped(tokenSwapped);

        // transfer tokenA to this contract
        // calculate amount of token B to swap Ydx/(X+DX)
        (uint256 reserveOfTokenSwapped, uint256 reserveOfTokenReturned) = calculateInitialValues(tokenSwapped);
        uint256 amounttoReturn = calculateAmountToSwap(amountSwapped, reserveOfTokenSwapped, reserveOfTokenReturned);
        // transfer tokenB to msg.sender
        IERC20(tokenSwapped).transferFrom(msg.sender, address(this), amountSwapped);
        IERC20(tokenToReturn).transfer(msg.sender, amounttoReturn);
    }

    function addLiquidity(uint256 amountA, uint256 amountB)
        external
        moreThanZero(amountA)
        moreThanZero(amountB)
        nonReentrant
    {
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

    function removeLiquidity(uint256 amountShares) external moreThanZero(amountShares) nonReentrant {
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

    function getShareHolding(address shareHolder) external view returns (uint256) {
        return s_balances[shareHolder];
    }
}
