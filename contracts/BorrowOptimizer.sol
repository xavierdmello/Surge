// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseVault} from "./BaseVault.sol";
import {IBaseLender} from "./interfaces/IBaseLender.sol";
import {ERC20} from "./tokens/ERC20.sol";

/// @author Xavier D'Mello www.xavierdmello.com
abstract contract BorrowOptimizer is BaseVault, IBaseLender {
    // Token that is borrowed
    ERC20 public immutable want;
    // ERC20 public immutable asset (Stored in BaseVault)

    // Percentage of LTV to borrow
    uint256 public safetyMargin = 80;

    constructor(ERC20 _asset, ERC20 _want, string memory _name, string memory _symbol) BaseVault(_asset, _name, _symbol) {
        want = _want;
    }

    /**
     * The target percentage of the vault to borrow against, scaled to 18 decimals.
     * @notice borrowTargetMantissa = ltv * safetyMargin
     */
    function previewBorrowTargetMantissa(uint256 _safetyMargin) public view returns (uint256) {
        return (ltv() / 100) * _safetyMargin;
    }

    function borrowTargetMantissa() public view returns (uint256) {
        return previewBorrowTargetMantissa(safetyMargin);
    }

    /**
     * The target amount of tokens to borrow safely.
     */
    function previewBorrowTarget(uint256 _safetyMargin) public returns (uint256) {
        return (((lendBalance() * exchangeRate()) / 10 ** asset.decimals()) * previewBorrowTargetMantissa(_safetyMargin)) / 1e18;
    }

    function borrowTarget() public returns (uint256) {
        return previewBorrowTarget(safetyMargin);
    }

    /**
     * The target amount of collateral to supply safely.
     * Used internally to calculate withdrawls.
     */
    function lendTarget() internal returns (uint256) {
        return (((borrowBalance() * 10 ** asset.decimals()) / exchangeRate()) * 1e18) / borrowTargetMantissa();
    }

    /**
     * The exchange rate asset:want
     */
    function exchangeRate() public view returns (uint256) {
        return (price(address(asset)) * 10 ** want.decimals()) / price(address(want));
    }

    function rebalance() public {
        uint256 borrowTarget = borrowTarget();
        uint256 borrowBalance = borrowBalance();

        if (borrowTarget > borrowBalance) {
            // Borrow more tokens
            uint256 borrowAmount = borrowTarget - borrowBalance;
            borrow(borrowAmount);
            afterBorrow(borrowAmount);
        } else if (borrowTarget < borrowBalance) {
            // Borrow less tokens
            uint256 repayAmount = borrowBalance - borrowTarget;
            beforeRepay(repayAmount);
            repay(repayAmount);
        }
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/) internal override {
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
