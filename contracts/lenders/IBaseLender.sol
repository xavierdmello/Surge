// SPDX-License-Identifier: MIT
abstract contract IBaseLender {
    function claimRewards() internal virtual;

    function lendBalance() internal virtual returns (uint256);

    function lend(uint256 amount) internal virtual;

    function borrowBalance() internal virtual returns (uint256);

    function borrow(uint256 amount) internal virtual;

    function repay(uint256 amount) internal virtual;

    function withdraw(uint256 amount) internal virtual;
    
    // Percentage of collateral that can be borrowed against, scaled to 18 decimals.
    function ltv() internal view virtual returns (uint256);

    // Price of asset in USD, scaled to 18 decimals.
    function price(address asset) internal view virtual returns (uint256);
}
