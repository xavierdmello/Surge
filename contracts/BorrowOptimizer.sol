pragma solidity ^0.8.0;

import {BaseVault} from "./BaseVault.sol";
import {IBaseLender} from "./lenders/IBaseLender.sol";
import {ERC20} from "./tokens/ERC20.sol";

/// @author Xavier D'Mello www.xavierdmello.com
abstract contract BorrowOptimizer is BaseVault, IBaseLender {
    // ERC20 public immutable asset (Stored in BaseVault)
    ERC20 public immutable borrow;

    // Percentage of LTV to borrow
    uint256 public safteyMargin = 80;

    constructor(ERC20 _asset, ERC20 _borrow, string memory _name, string memory _symbol) BaseVault(_asset, _name, _symbol) {
        borrow = borrow;

        approveLending();
        readyMarkets();
    }

    /**
     * The target percentage of the vault to borrow against, scaled by 1e18
     * @notice borrowTargetMantissa = ltv * safteyMargin
     */
    function borrowTargetMantissa() public view returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cAsset));
        return (collateralFactorMantissa / 100) * safteyMargin;
    }

    /**
     * The target amount of tokens to borrow safely
     */
    function borrowTarget() public view returns (uint256) {
        uint256 exchangeRate = (price(asset) * 1e18) / price(borrow);
        uint256 borrowTarget = (((lendBalance() * exchangeRate) / 1e18) * borrowTargetMantissa()) / 1e18;
        return borrowTarget;
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

    function totalAssets() public override returns (uint256) {}

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {}

    function afterDeposit(uint256 assets, uint256 shares) internal override {}

    function beforeRepay(uint256 amount) internal virtual {}

    function afterBorrow(uint256 amount) internal virtual {}
}
