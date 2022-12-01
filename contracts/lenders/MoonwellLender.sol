// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseLender} from "./IBaseLender.sol";
import {ICErc20} from "../interfaces/ICErc20.sol";
import {ERC20} from "../tokens/ERC20.sol";
import {IMoontroller} from "../interfaces/IMoontroller.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";

contract MoonwellLender is IBaseLender {
    IMoontroller public immutable comptroller;
    ICErc20 public immutable cAsset;
    ICErc20 public immutable cWant;

    constructor(address _cAsset, address _cWant) {
        comptroller = IMoontroller(address(ICErc20(_cAsset).comptroller()));
        cAsset = ICErc20(_cAsset);
        cWant = ICErc20(_cWant);

        // Note: Approvals & readying markets were going to be in seperate functions,
        // but it wasn't possible to use with immutable variables before they were fully initialized.

        // Approve cAsset for lending to and cWant for repaying to
        ERC20 asset = ERC20(cAsset.underlying());
        ERC20 want = ERC20(cWant.underlying());
        asset.approve(address(cAsset), type(uint256).max);
        want.approve(address(cWant), type(uint256).max);

        // Enter Markets
        address[] memory market = new address[](1);
        market[0] = address(cAsset);
        comptroller.enterMarkets(market);
    }

    function claimRewards() internal override{
        comptroller.claimReward(0, payable(address(this))); // MFAM/WELL
        comptroller.claimReward(1, payable(address(this))); // MOVR/GLMR
    }

    // To recieve MOVR/GLMR rewards
    receive() external payable {}

    function lendBalance() internal override returns (uint256) {
        return cAsset.balanceOfUnderlying(address(this));
    }

    function lend(uint256 amount) internal override {
        cAsset.mint(amount);
    }

    function borrowBalance() internal override returns (uint256) {
        return cWant.borrowBalanceCurrent(address(this));
    }

    function borrow(uint256 amount) internal override{
        cWant.borrow(amount);
    }

    function repay(uint256 amount) internal override{
        cWant.repayBorrow(amount);
    }

    function withdraw(uint256 amount) internal override{
        cAsset.redeemUnderlying(amount);
    }

    // Price of asset in USD, scaled to 18 decimals.
    function price(address asset) internal view override returns (uint256 price) {
        return IPriceOracle(comptroller.oracle()).price(ICErc20(asset).symbol()) * 1e12;
    }

    function ltv() internal view override returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cAsset));
        return collateralFactorMantissa;
    }
}
