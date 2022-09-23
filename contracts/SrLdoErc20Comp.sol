// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CErc20} from "./compound/CErc20.sol";
import {PriceOracle} from "./compound/PriceOracle.sol";
import {Moontroller} from "./interfaces/Moontroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {WstKSM} from "./lido/wstKSM.sol";

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

    // Lido
    WstKSM public immutable stBorrow;
    address[] private stBorrowPath;

    constructor(
        CErc20 _cAsset,
        CErc20 _cBorrow,
        WstKSM _stBorrow,
        address[] memory _rewardTokenPath,
        address[] memory _rewardEthPath,
        address[] memory _stBorrowPath,
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

        // Lido
        stBorrow = _stBorrow;
        stBorrowPath = _stBorrowPath;

        // Convert ComptrollerInterface to Comptroller because some hidden functions need to be used
        comptroller = Moontroller(address(_cAsset.comptroller()));
        priceOracle = comptroller.oracle();

        // Enter Market
        address[] memory market = new address[](1);
        market[0] = address(cAsset);
        require(comptroller.enterMarkets(market)[0] == 0, "Surge: Compound Enter Market failed");
    }

    /**
     * Returns the rate of cTokens to shares
     * @notice shares * exchangeRate() = cTokens
     * @dev always grab the exchange rate before interacting with cTokens.
     */
    function exchangeRate() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        return totalSupply == 0 ? 10**decimals() : (cAsset.balanceOf(address(this)) * 10**decimals()) / totalSupply;
    }

    /**
     * @dev This token has the same amount of decimals as the underlying cAsset.
     */
    function decimals() public view override returns (uint8) {
        return cAssetDecimals;
    }

    /**
     * The target borrow rate of the vault, scaled by 1e18
     * @notice borrowTargetMantissa = collateralFactorMantissa * safteyMargin
     */
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

    // TODO: Decide to call this function every time deposit() is called, or only perodically (to save gas)
    function rebalance() public {
        // Exchange rate asset:borrow. Not to be confused with exchangeRate()
        uint256 assetExchangeRate = (priceOracle.getUnderlyingPrice(cAsset) * 10**(36 - borrowDecimals)) /
            priceOracle.getUnderlyingPrice(cBorrow); // In (36-assetDecimals) decimals.
        uint256 borrowTarget = (((cAsset.balanceOfUnderlying(address(this)) * assetExchangeRate) / 10**(36 - borrowDecimals)) *
            borrowTargetMantissa()) / 1e18; // In borrowDecimals decimals.
        uint256 borrowBalanceCurrent = cBorrow.borrowBalanceCurrent(address(this));

        if (borrowTarget > borrowBalanceCurrent) {
            // Borrow & stake more tokens
            uint256 borrowAmount = borrowTarget - borrowBalanceCurrent;
            require(cBorrow.borrow(borrowAmount) == 0, "Surge: Compound borrow failed");
            borrow.approve(address(stBorrow), borrowAmount);
            stBorrow.submit(borrowAmount);
        } else if (borrowTarget < borrowBalanceCurrent) {
            // Unstake & repay some tokens
            uint256 repayAmount = borrowBalanceCurrent - borrowTarget;
            stBorrow.approve(address(router), type(uint256).max);
            router.swapTokensForExactTokens(repayAmount, type(uint256).max, stBorrowPath, address(this), block.timestamp);
            borrow.approve(address(cBorrow), repayAmount);
            require(cBorrow.repayBorrow(repayAmount) == 0, "Surge: Compound repay failed");
        }
    }

    /**
     * TODO: Decide to call this function every time rebalance() is called, or only perodically (to save gas)
     * @notice Claims Compound rewards, swaps them into asset, and deposits them back into Compound.
     * @dev Moonwell uses a modified Compound rewards system with additional rewards.
     */
    function claimMoonwellRewards() public {
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

    // To recieve MOVR/GLMR rewards
    receive() external payable {}

    /**
     * @notice Converts wstKSM to xcKSM using the LP.
     * Not reccomended unless you need your tokens fast & are willing to pay fees and slippage.
     * For feeless (but slow) withdrawls, use the normal withdraw().
     * @param shares Amount of shares to redeem for asset
     * @dev Two ways to do this:
     * 1. Caclulate percentage of shares owned, extrapolate that to debt to repay and percentage claimable of cTokens
     * 2. Calculate direct shares => ctoken => debt exchange rate
     * Option 1 probably costs less gas, but may have more rounding errors.
     * TODO: Test theory
     */
    function quickWithdraw(uint256 shares) public {
        uint256 percentageRedeeming = (shares * decimals()) / totalSupply();
        _burn(msg.sender, shares);

        // Swap stBorrow -> borrow
        uint256 stBorrowRepayAmount = (stBorrow.balanceOf(address(this)) * percentageRedeeming) / 10**decimals();
        stBorrow.approve(address(router), stBorrowRepayAmount);
        uint256 borrowRepayAmount = router.swapExactTokensForTokens(
            stBorrowRepayAmount,
            0,
            stBorrowPath,
            address(this),
            block.timestamp
        )[1];

        // Calculate the percentage of tokens that are actually being paid back (will differ because of swap fees & slippage)
        uint256 percentageRepaid = (borrowRepayAmount * 10**borrowDecimals) / cBorrow.borrowBalanceCurrent(address(this));

        // Repay borrows
        borrow.approve(address(cBorrow), borrowRepayAmount);
        require(
            cBorrow.repayBorrow(borrowRepayAmount) == 0,
            "Surge: Compound repay failed"
        );

        // Withdraw asset
        uint256 withdrawnAssets = (cAsset.balanceOfUnderlying(address(this)) * percentageRepaid) / 10**borrowDecimals;
        require(cBorrow.redeemUnderlying(withdrawnAssets) == 0, "Surge: Compound withdraw failed");

        // Transfer asset to user
        asset.transfer(msg.sender, withdrawnAssets);
    }

    /**
     * @dev Placeholder function for feeless "slow withdraw" from lido
     */
    function withdraw(uint256 shares) public {}
}
