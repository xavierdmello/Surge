pragma solidity ^0.8.0;

import {IBaseLender} from "./IBaseLender.sol";
import {CErc20, EIP20Interface} from "./compound/CErc20.sol";

import {Moontroller} from "./interfaces/Moontroller.sol";

contract MoonwellLender is IBaseLender {
    Moontroller public immutable comptroller;
    CErc20 public immutable cAsset;
    CErc20 public immutable cBorrow;

    constructor(address _cAsset, address _cBorrow) {
        comptroller = Moontroller(address(CErc20(_cAsset).comptroller()));
        cAsset = CErc20(_cAsset);
        cBorrow = CErc20(_cBorrow);
    }

    function readyMarkets() internal {
        address[] memory market = new address[](1);
        market[0] = address(cAsset);
        require(comptroller.enterMarkets(market)[0] == 0, "Surge: Compound Enter Market failed");
    }

    function claimRewards() internal {
        comptroller.claimReward(0, payable(address(this))); // MFAM/WELL
        comptroller.claimReward(1, payable(address(this))); // MOVR/GLMR
    }

    // To recieve MOVR/GLMR rewards
    receive() external payable {}

    function lendBalance() internal returns (uint256) {
        return cAsset.balanceOfUnderlying(address(this));
    }

    function lend(uint256 amount) internal {
        cAsset.mint(amount);
    }

    function borrowBalance() internal returns (uint256) {
        cBorrow.borrowBalanceCurrent(address(this));
    }

    function borrow(uint256 amount) internal {
        cBorrow.borrow(amount);
    }

    function repay(uint256 amount) internal {
        cBorrow.repayBorrow(amount);
    }

    function withdraw(uint256 amount) internal {
        cAsset.redeemUnderlying(amount);
    }

    // Price of asset in USD, scaled to 18 decimals.
    function price(address asset) internal view returns (uint256) {
        comptroller.oracle().price(asset) * 1e12;
    }

    function approveLending() internal {
        EIP20Interface asset = EIP20Interface(cAsset.underlying());
        EIP20Interface borrow = EIP20Interface(cborrow.underlying());

        // Approve cAsset for lending to
        asset.approve(address(cAsset), type(uint256).max);

        // Approve cBorrow for repaying to
        borrow.approve(address(cBorrow), type(uint256).max);
    }

    function ltv() internal view returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(cAsset);
        return collateralFactorMantissa;
    }
}
