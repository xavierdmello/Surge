// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CErc20} from "./compound/CErc20.sol";
import {PriceOracle} from "./compound/PriceOracle.sol";
import {Comptroller} from "./compound/Comptroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

/// @author Xavier D'Mello www.xavierdmello.com
// TODO: Replace hardcoded 1e18 decimal assumptions with actual asset decimals
// TODO: Investigate weird shares:cToken ratio behaviour
contract SrLdoErc20Comp is ERC20 {
    ERC20 public immutable asset;
    ERC20 public immutable borrow;
    CErc20 public immutable cAsset;
    CErc20 public immutable cBorrow;

    // For gas optimization purposes
    uint256 private immutable assetDecimals;
    uint256 private immutable borrowDecimals;

    PriceOracle public immutable priceOracle;
    Comptroller public immutable comptroller;

    // Percentage of LTV to borrow
    uint256 public safteyMargin = 80;

    constructor(
        CErc20 _cAsset,
        CErc20 _cBorrow,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        cAsset = _cAsset;
        cBorrow = _cBorrow;

        asset = ERC20(_cAsset.underlying());
        borrow = ERC20(_cBorrow.underlying());
        assetDecimals = asset.decimals();
        borrowDecimals = borrow.decimals();

        // Convert ComptrollerInterface to Comptroller because some hidden functions need to be used
        comptroller = Comptroller(address(_cAsset.comptroller()));
        priceOracle = comptroller.oracle();

        // Enter Market
        address[] memory market = new address[](1);
        market[0] = address(cAsset);
        require(comptroller.enterMarkets(market)[0] == 0, "Surge: Compound Enter Market failed");
    }

    // Returns the rate of ctokens to shares, scaled by 1e18.
    // shares * exchangeRate() = cTokens
    function exchangeRate() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        return totalSupply == 0 ? 1e18 : (cAsset.balanceOf(address(this)) * 1e18) / totalSupply;
    }

    // The target borrow rate of the vault, scaled by 1e18
    // borrowTargetMantissa = collateralFactorMantissa * safteyMargin
    function borrowTargetMantissa() public view returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cAsset));
        return (collateralFactorMantissa / 100) * safteyMargin;
    }

    function deposit(uint256 assets) public {
        asset.transferFrom(msg.sender, address(this), assets);

        // Deposit into Compound
        asset.approve(address(cAsset), assets);
        require(cAsset.mint(assets) == 0, "Surge: Compound deposit failed");

        console.log("Compound Deposit Success");
        rebalance();
        console.log("Rebalance Success");
        console.log("cAsset.exchangeRateCurrent: ", cAsset.exchangeRateCurrent());
        console.log("shares exchange rate: ", exchangeRate());
        uint256 amount = (((assets * 1e18) / cAsset.exchangeRateCurrent()) * exchangeRate()) / 1e18;
        console.log("Mint amount: ", amount);
        _mint(msg.sender, amount);
        console.log("Mint Success");
    }

    function rebalance() public {
        // Exchange rate asset:borrow. Not to be confused with exchangeRate()
        uint256 assetExchangeRate = (priceOracle.getUnderlyingPrice(cAsset) * 1e18) /
            priceOracle.getUnderlyingPrice(cBorrow);
        uint256 borrowBalanceCurrent = cBorrow.borrowBalanceCurrent(address(this));
        uint256 borrowTarget = (((cAsset.balanceOfUnderlying(address(this)) * assetExchangeRate) / 1e18) *
            borrowTargetMantissa()) / 1e18;

        console.log("\nBorrow Balance Current:", borrowBalanceCurrent, "\n");
        console.log("\nBorrow Target:", borrowTarget, "\n");

        if (borrowTarget > borrowBalanceCurrent) {
            require(cBorrow.borrow(borrowTarget - borrowBalanceCurrent) == 0, "Surge: Compound borrow failed");
        } else if (borrowTarget < borrowBalanceCurrent) {
            require(cBorrow.repayBorrow(borrowBalanceCurrent - borrowTarget) == 0, "Surge: Compound repay failed");
        }
    }

    function withdraw(uint256 cAssets) public {}
}
