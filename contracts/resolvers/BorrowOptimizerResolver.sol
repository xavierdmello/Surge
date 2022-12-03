// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BorrowOptimizer} from "../BorrowOptimizer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LibString} from "../utils/LibString.sol";

contract BorrowOptimizerResolver is Ownable {
    BorrowOptimizer public immutable bo;
    uint256 public threshold;
    using LibString for uint256;

    constructor(BorrowOptimizer _borrowOptimizer, uint256 _threshold) Ownable() {
        bo = _borrowOptimizer;
        threshold = _threshold;
    }
    
    function shouldRebalance() external returns (bool canExec, bytes memory execPayload) {
        uint256 borrowBalance = bo.borrowBalance();
        uint256 max = bo.previewBorrowTarget(bo.safetyMargin() + threshold);
        uint256 min = bo.previewBorrowTarget(bo.safetyMargin() - threshold);
        if (borrowBalance > max || borrowBalance < min) {
            return (true, abi.encodeCall(BorrowOptimizer.rebalance, ()));
        } else {
            return (
                false,
                abi.encodePacked(
                    "Current LTV: ",
                    currentLtv().toString(),
                    " Target: ",
                    bo.borrowTargetMantissa().toString(),
                    " Threshold: ",
                    threshold.toString(),
                    " Borrow Balance: ",
                    borrowBalance.toString(),
                    " Max: ",
                    max.toString(),
                    " Min: ",
                    min.toString()
                )
            );
        }
    }

    /// @dev Not percise! Should only be used for display purposes.
    function currentLtv() public returns (uint256) {
        uint256 assetDecimals = bo.asset().decimals();
        uint256 lendBalance = bo.lendBalance();
        if (lendBalance == 0) {
            return 0;
        } else {
            if (assetDecimals > 18) {
                return
                    ((((bo.borrowBalance() * 10 ** bo.asset().decimals()) / bo.exchangeRate()) * 10 ** bo.asset().decimals()) /
                        lendBalance) / 10 ** (assetDecimals - 18);
            } else {
                return
                    ((((bo.borrowBalance() * 10 ** bo.asset().decimals()) / bo.exchangeRate()) * 10 ** bo.asset().decimals()) /
                        lendBalance) * 10 ** (18 - assetDecimals);
            }
        }
    }

    function setThreshold(uint256 _threshold) public onlyOwner {
        threshold = _threshold;
    }
}
