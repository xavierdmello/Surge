// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BorrowOptimizer} from "../BorrowOptimizer.sol";
import {MoonwellLender} from "../lenders/MoonwellLender.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICErc20} from "../interfaces/ICErc20.sol";
import {ERC20} from "../tokens/ERC20.sol";

// An barebones implementation of BorrowOptimizer for testing.
contract BorrowOptimizerTest is BorrowOptimizer, MoonwellLender, Ownable {
    constructor(
        ICErc20 _cAsset,
        ICErc20 _cWant,
        string memory _name,
        string memory _symbol
    )
        MoonwellLender(address(_cAsset), address(_cWant))
        BorrowOptimizer(ERC20(_cAsset.underlying()), ERC20(_cWant.underlying()), _name, _symbol)
        Ownable()
    {}

    function setSafetyMargin(uint8 newMargin) public onlyOwner {
        safetyMargin = newMargin;
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/) internal override returns (uint256) {
        repay(borrowBalance());
        withdraw(assets);
        return assets;
    }

    function totalAssets() public override returns (uint256) {
        return lendBalance() - debt() + stakedValueInAsset();
    }

    /**
     * The value, denominated in 'asset', of the tokens staked by this vault.
     */
    function stakedValueInAsset() public view returns (uint256) {
        return (want.balanceOf(address(this)) * 1e18) / exchangeRate();
    }

    /**
     * The value, denominated in 'asset', of the borrows owed back to the lendee.
     */
    function debt() public returns (uint256) {
        return (borrowBalance() * 1e18) / exchangeRate();
    }

    function beforeRepay(uint256 amount) internal override {}

    function afterBorrow(uint256 amount) internal override {}
}
