interface IBaseLender {
    function readyMarkets() internal;

    function claimRewards() internal;

    function lendBalance() internal returns (uint256);

    function lend(uint256 amount) internal;

    function borrowBalance() internal returns (uint256);

    function borrow(uint256 amount) internal;

    function repay(uint256 amount) internal;

    function withdraw(uint256 amount) internal;

    function approveLending() internal;
    
    // Percentage of collateral that can be borrowed against, scaled to 18 decimals.
    function ltv() internal view returns (uint256);

    // Price of asset in USD, scaled to 18 decimals.
    function price(address asset) internal view returns (uint256);
}
