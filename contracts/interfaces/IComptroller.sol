// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
    function _become(address unitroller) external;

    function _borrowGuardianPaused() external view returns (bool);

    function _grantComp(address recipient, uint256 amount) external;

    function _mintGuardianPaused() external view returns (bool);

    function _setBorrowCapGuardian(address newBorrowCapGuardian) external;

    function _setBorrowPaused(address cToken, bool state) external returns (bool);

    function _setCloseFactor(uint256 newCloseFactorMantissa) external returns (uint256);

    function _setCollateralFactor(address cToken, uint256 newCollateralFactorMantissa) external returns (uint256);

    function _setCompSpeeds(address[] memory cTokens, uint256[] memory supplySpeeds, uint256[] memory borrowSpeeds) external;

    function _setContributorCompSpeed(address contributor, uint256 compSpeed) external;

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (uint256);

    function _setMarketBorrowCaps(address[] memory cTokens, uint256[] memory newBorrowCaps) external;

    function _setMintPaused(address cToken, bool state) external returns (bool);

    function _setPauseGuardian(address newPauseGuardian) external returns (uint256);

    function _setPriceOracle(address newOracle) external returns (uint256);

    function _setSeizePaused(bool state) external returns (bool);

    function _setTransferPaused(bool state) external returns (bool);

    function _supportMarket(address cToken) external returns (uint256);

    function accountAssets(address, uint256) external view returns (address);

    function admin() external view returns (address);

    function allMarkets(uint256) external view returns (address);

    function borrowAllowed(address cToken, address borrower, uint256 borrowAmount) external returns (uint256);

    function borrowCapGuardian() external view returns (address);

    function borrowCaps(address) external view returns (uint256);

    function borrowGuardianPaused(address) external view returns (bool);

    function borrowVerify(address cToken, address borrower, uint256 borrowAmount) external;

    function checkMembership(address account, address cToken) external view returns (bool);

    function claimComp(address holder, address[] memory cTokens) external;

    function claimComp(address[] memory holders, address[] memory cTokens, bool borrowers, bool suppliers) external;

    function claimComp(address holder) external;

    function closeFactorMantissa() external view returns (uint256);

    function compAccrued(address) external view returns (uint256);

    function compBorrowSpeeds(address) external view returns (uint256);

    function compBorrowState(address) external view returns (uint224 index, uint32 block);

    function compBorrowerIndex(address, address) external view returns (uint256);

    function compContributorSpeeds(address) external view returns (uint256);

    function compInitialIndex() external view returns (uint224);

    function compRate() external view returns (uint256);

    function compReceivable(address) external view returns (uint256);

    function compSpeeds(address) external view returns (uint256);

    function compSupplierIndex(address, address) external view returns (uint256);

    function compSupplySpeeds(address) external view returns (uint256);

    function compSupplyState(address) external view returns (uint224 index, uint32 block);

    function comptrollerImplementation() external view returns (address);

    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    function exitMarket(address cTokenAddress) external returns (uint256);

    function fixBadAccruals(address[] memory affectedUsers, uint256[] memory amounts) external;

    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

    function getAllMarkets() external view returns (address[] memory);

    function getAssetsIn(address account) external view returns (address[] memory);

    function getBlockNumber() external view returns (uint256);

    function getCompAddress() external view returns (address);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external view returns (uint256, uint256, uint256);

    function isComptroller() external view returns (bool);

    function isDeprecated(address cToken) external view returns (bool);

    function lastContributorBlock(address) external view returns (uint256);

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 actualRepayAmount,
        uint256 seizeTokens
    ) external;

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256);

    function liquidationIncentiveMantissa() external view returns (uint256);

    function markets(address) external view returns (bool isListed, uint256 collateralFactorMantissa, bool isComped);

    function maxAssets() external view returns (uint256);

    function mintAllowed(address cToken, address minter, uint256 mintAmount) external returns (uint256);

    function mintGuardianPaused(address) external view returns (bool);

    function mintVerify(address cToken, address minter, uint256 actualMintAmount, uint256 mintTokens) external;

    function oracle() external view returns (address);

    function pauseGuardian() external view returns (address);

    function pendingAdmin() external view returns (address);

    function pendingComptrollerImplementation() external view returns (address);

    function proposal65FixExecuted() external view returns (bool);

    function redeemAllowed(address cToken, address redeemer, uint256 redeemTokens) external returns (uint256);

    function redeemVerify(address cToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external;

    function repayBorrowAllowed(address cToken, address payer, address borrower, uint256 repayAmount) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 actualRepayAmount,
        uint256 borrowerIndex
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeGuardianPaused() external view returns (bool);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(address cToken, address src, address dst, uint256 transferTokens) external returns (uint256);

    function transferGuardianPaused() external view returns (bool);

    function transferVerify(address cToken, address src, address dst, uint256 transferTokens) external;

    function updateContributorRewards(address contributor) external;
}
