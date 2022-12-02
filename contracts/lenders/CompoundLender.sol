// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseLender} from "../interfaces/IBaseLender.sol";
import {ICErc20} from "../interfaces/ICErc20.sol";
import {ERC20} from "../tokens/ERC20.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IComptroller} from "../interfaces/IComptroller.sol";

contract MoonwellLender is IBaseLender {
    IComptroller public immutable comptroller;
    ICErc20 public immutable cAsset;
    ICErc20 public immutable cWant;
    mapping(address => address) private cToken;

    constructor(address _cAsset, address _cWant) {
        comptroller = IComptroller(address(ICErc20(_cAsset).comptroller()));
        cAsset = ICErc20(_cAsset);
        cWant = ICErc20(_cWant);

        // Note: Approvals & readying markets were going to be in seperate functions,
        // but it wasn't possible to use with immutable variables before they were fully initialized.

        // Approve cAsset for lending to and cWant for repaying to
        ERC20 asset = ERC20(cAsset.underlying());
        ERC20 want = ERC20(cWant.underlying());
        asset.approve(address(cAsset), type(uint256).max);
        want.approve(address(cWant), type(uint256).max);

        cToken[address(asset)] = _cAsset;
        cToken[address(want)] = _cWant;

        // Enter Markets
        address[] memory market = new address[](1);
        market[0] = address(cAsset);
        comptroller.enterMarkets(market);
    }

    function claimRewards() internal override {
        comptroller.claimComp(address(this));
    }

    function lendBalance() public override returns (uint256) {
        return cAsset.balanceOfUnderlying(address(this));
    }

    function lend(uint256 amount) internal override {
        cAsset.mint(amount);
    }

    function borrowBalance() public override returns (uint256) {
        return cWant.borrowBalanceCurrent(address(this));
    }

    function borrow(uint256 amount) internal override {
        cWant.borrow(amount);
    }

    function repay(uint256 amount) internal override {
        cWant.repayBorrow(amount);
    }

    function withdraw(uint256 amount) internal override {
        cAsset.redeemUnderlying(amount);
    }

    // Price of asset in USD, scaled to 18 decimals.
    function price(address asset) public view override returns (uint256) {
        // The price of the asset in USD as an unsigned integer scaled up by 10 ^ (36 - underlying asset decimals)
        uint256 unscaledPrice = IPriceOracle(comptroller.oracle()).getUnderlyingPrice(cToken[asset]);

        // Adjust to 18 decimals
        uint assetDecimals = ERC20(asset).decimals();
        if (assetDecimals > 18) {
            return unscaledPrice * 10 ** (ERC20(asset).decimals() - 18);
        } else {
            return unscaledPrice / 10 ** (18 - ERC20(asset).decimals());
        }
    }

    function ltv() public view override returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cAsset));
        return collateralFactorMantissa;
    }
}
