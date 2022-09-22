// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CErc20} from "./compound/CErc20.sol";
import {PriceOracle} from "./compound/PriceOracle.sol";
import {Comptroller} from "./compound/Comptroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @author Xavier D'Mello www.xavierdmello.com
contract SrLdoErc20Comp is ERC20 {
    ERC20 public immutable asset;
    ERC20 public immutable borrow;
    CErc20 public immutable cAsset;
    CErc20 public immutable cBorrow;

    // For gas optimization purposes
    // TODO: Test effictiveness
    uint8 private immutable assetDecimals;
    uint8 private immutable borrowDecimals;
    uint8 private immutable cAssetDecimals;

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
        cAssetDecimals = _cAsset.decimals();

        // Convert ComptrollerInterface to Comptroller because some hidden functions need to be used
        comptroller = Comptroller(address(_cAsset.comptroller()));
        priceOracle = comptroller.oracle();

        // Enter Market
        address[] memory market = new address[](1);
        market[0] = address(cAsset);
        require(comptroller.enterMarkets(market)[0] == 0, "Surge: Compound Enter Market failed");
    }

    // Returns the rate of cTokens to shares
    // shares * exchangeRate() = cTokens
    /// @dev always grab the exchange rate before interacting with cTokens.
    function exchangeRate() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        return totalSupply == 0 ? 10**decimals() : (cAsset.balanceOf(address(this)) * 10**decimals()) / totalSupply;
    }

    /// @dev This token has the same amount of decimals as the cAsset
    function decimals() public view override returns (uint8) {
        return cAssetDecimals;
    }

    // The target borrow rate of the vault, scaled by 1e18
    // borrowTargetMantissa = collateralFactorMantissa * safteyMargin
    function borrowTargetMantissa() public view returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cAsset));
        return (collateralFactorMantissa / 100) * safteyMargin;
    }

    function deposit(uint256 assets) public {
        asset.transferFrom(msg.sender, address(this), assets);

        // Snapshot exchange rate before cTokens are deposited to prevent incorrect rate calculation
        uint256 exchangeRateSnapshot = exchangeRate();

        // Deposit into Compound
        uint256 cAssetBalanceBefore = cAsset.balanceOf(address(this));
        asset.approve(address(cAsset), assets);
        require(cAsset.mint(assets) == 0, "Surge: Compound deposit failed");
        uint256 cAssetsMinted = cAsset.balanceOf(address(this)) - cAssetBalanceBefore;

        rebalance();
        _mint(msg.sender, (cAssetsMinted * 10**decimals()) / exchangeRateSnapshot);
    }

    function rebalance() public {
        // Exchange rate asset:borrow. Not to be confused with exchangeRate()
        uint256 assetExchangeRate = (priceOracle.getUnderlyingPrice(cAsset) * 10**(36 - borrowDecimals)) /
            priceOracle.getUnderlyingPrice(cBorrow); // In (36-assetDecimals) decimals.
        uint256 borrowTarget = (((cAsset.balanceOfUnderlying(address(this)) * assetExchangeRate) / 10**(36 - borrowDecimals)) *
            borrowTargetMantissa()) / 1e18; // In borrowDecimals decimals.
        uint256 borrowBalanceCurrent = cBorrow.borrowBalanceCurrent(address(this));

        if (borrowTarget > borrowBalanceCurrent) {
            require(cBorrow.borrow(borrowTarget - borrowBalanceCurrent) == 0, "Surge: Compound borrow failed");
        } else if (borrowTarget < borrowBalanceCurrent) {
            require(cBorrow.repayBorrow(borrowBalanceCurrent - borrowTarget) == 0, "Surge: Compound repay failed");
        }
    }

    /*
    Two ways to do this:
    1. Caclulate percentage of shares owned, extrapolate that to debt to repay and percentage claimable of cTokens
    2. Calculate direct shares => ctoken => debt exchange rate
    Option 1 probably costs less gas, but may have more rounding errors.
    TODO: Test theory
    */
    /// @param shares Amount of shares to redeem for asset
    function withdraw(uint256 shares) public {
        uint256 percentageRedeeming = (shares * decimals()) / totalSupply();
        _burn(msg.sender, shares);

        // Repay borrows
        require(
            cBorrow.repayBorrow((cBorrow.borrowBalanceCurrent(address(this)) * percentageRedeeming) / 10**decimals()) == 0,
            "Surge: Compound repay failed"
        );

        // Withdraw asset
        uint256 withdrawnAssets = (cAsset.balanceOfUnderlying(address(this)) * percentageRedeeming) / 10**decimals();
        require(cBorrow.redeemUnderlying(withdrawnAssets) == 0, "Surge: Compound withdraw failed");

        // Transfer asset to user
        asset.transfer(msg.sender, withdrawnAssets);
    }
}
