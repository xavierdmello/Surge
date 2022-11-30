pragma solidity ^0.8.0;

import {BaseVault} from "./BaseVault.sol";
import {IBaseLender} from "./lenders/IBaseLender.sol";
import {ERC20} from "./tokens/ERC20.sol";

/// @author Xavier D'Mello www.xavierdmello.com
abstract contract BorrowOptimizer is BaseVault, IBaseLender {
    // ERC20 public immutable asset (Stored in BaseVault)
    ERC20 public immutable borrow;

    // Percentage of LTV to borrow
    uint256 public safetyMargin = 80;

    constructor(ERC20 _asset, ERC20 _borrow, string memory _name, string memory _symbol) BaseVault(_asset, _name, _symbol) {
        borrow = _borrow;
        approveLending();
        readyMarkets();
    }

    /**
     * The target percentage of the vault to borrow against, scaled to 18 decimals.
     * @notice borrowTargetMantissa = ltv * safetyMargin
     */
    function borrowTargetMantissa() public view returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cAsset));
        return (collateralFactorMantissa / 100) * safetyMargin;
    }

    /**
     * The target amount of tokens to borrow safely
     */
    function borrowTarget() public view returns (uint256) {
        return = (((lendBalance() * exchangeRate()) / 1e18) * borrowTargetMantissa()) / 1e18;
    }

    /**
     * The exchange rate asset:borrow, scaled to 18 decimals.
     */
    function exchangeRate() public view returns(uint256) {
        return (price(asset) * 1e18) / price(borrow);
    }

    function rebalance() public {
        uint256 borrowTarget = borrowTarget();
        uint256 borrowBalance = borrowBalance();

        if (borrowTarget > borrowBalance) {
            // Borrow more tokens
            uint256 borrowAmount = borrowTarget - borrowBalance;
            borrow(borrowAmount);
            afterBorrow(borrowAmount);
        } else if (borrowTarget < borrowBalanceCurrent) {
            // Borrow less tokens
            uint256 repayAmount = borrowBalance - borrowTarget;
            beforeRepay(repayAmount);
            repay(repayAmount);
        }
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        lend(assets);
        rebalance();
    }

    /**
     * @notice beforeWithdraw() must be implemented in the vault implementation contract.
     * This is because staking withdrawls from Lido & other services usually require an unbonding peroid.
     * This also allows for multiple withdrawl implementations, like a quickWithdraw() that uses LP liquidity to exit instead of unbonding.
     */
    // function beforeWithdraw(uint256 assets, uint256 shares) internal override {}

    /**
     * @notice totalAssets() must be implemented in the vault implementation contract.
     * This is because assets are staked and potentially even LP'd, which affects the total value of assets. 
     */
    // function totalAssets public override returns (uint256) {}

    function beforeRepay(uint256 amount) internal virtual {}

    function afterBorrow(uint256 amount) internal virtual {}
}
