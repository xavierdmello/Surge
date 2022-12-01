// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author Xavier DMello www.xavierdmello.com
abstract contract IBaseLender {
    function claimRewards() internal virtual;

    function lendBalance() public virtual returns (uint256);

    function lend(uint256 amount) internal virtual;

    function borrowBalance() public virtual returns (uint256);

    function borrow(uint256 amount) internal virtual;

    function repay(uint256 amount) internal virtual;

    function withdraw(uint256 amount) internal virtual;

    // Percentage of collateral that can be borrowed against, scaled to 18 decimals.
    function ltv() public view virtual returns (uint256);

    // Price of asset in USD, scaled to 18 decimals.
    function price(address asset) public view virtual returns (uint256);
}
