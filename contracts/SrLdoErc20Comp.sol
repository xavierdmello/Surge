// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CErc20} from "./compound/CErc20.sol";
import {PriceOracle} from "./compound/PriceOracle.sol";
import {Moontroller} from "./interfaces/Moontroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

/// @author Xavier D'Mello www.xavierdmello.com
contract SrLdoErc20Comp is ERC20 {
    // Compound
    ERC20 public immutable asset;
    ERC20 public immutable borrow;
    CErc20 public immutable cAsset;
    CErc20 public immutable cBorrow;
    PriceOracle public immutable priceOracle;
    Moontroller public immutable comptroller;

    // For gas optimization purposes
    // TODO: Test effictiveness
    uint8 private immutable assetDecimals;
    uint8 private immutable borrowDecimals;
    uint8 private immutable cAssetDecimals;

    // Percentage of LTV to borrow
    uint256 public safteyMargin = 80;

    // Moonwell Apollo and Artemis have two reward coins, respectively:
    // MOVR/GLMR (native) and MFAM/WELL (COMP equivalent)
    IUniswapV2Router02 private immutable router;
    address[] private rewardTokenPath;
    address[] private rewardEthPath;

    constructor(
        CErc20 _cAsset,
        CErc20 _cBorrow,
        address[] memory _rewardTokenPath,
        address[] memory _rewardEthPath,
        IUniswapV2Router02 _router,
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

        // Uniswap
        rewardTokenPath = _rewardTokenPath;
        rewardEthPath = _rewardEthPath;
        router = _router;

        // Convert ComptrollerInterface to Comptroller because some hidden functions need to be used
        comptroller = Moontroller(address(_cAsset.comptroller()));
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
        claimCompRewards();

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

    /// @dev Claims compound rewards, swaps them into asset, and deposits them back into compound.
    // TODO: Decide to call this function every time rebalance() is called, or only perodically (to save gas)
    function claimCompRewards() internal {
        claimMoonwellRewards();
    }

    // Moonwell uses a modified comp rewards system with additional rewards.
    function claimMoonwellRewards() internal {
        ERC20 rewardToken = ERC20(rewardTokenPath[0]); // MFAM/WELL
        comptroller.claimReward(0, payable(address(this))); // MFAM/WELL
        comptroller.claimReward(1, payable(address(this))); // MOVR/GLMR

        // Cache rewardTokenBalance to save some gas
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        rewardToken.approve(address(router), rewardTokenBalance);
        router.swapExactTokensForTokens(rewardTokenBalance, 0, rewardTokenPath, address(this), block.timestamp);
        router.swapExactETHForTokens{value: address(this).balance}(0, rewardEthPath, address(this), block.timestamp);

        // Deposit rewards back into compound
        asset.approve(address(cAsset), asset.balanceOf(address(this)));
        require(cAsset.mint(asset.balanceOf(address(this))) == 0, "Surge: Compound deposit failed");
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
