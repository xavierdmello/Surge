// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BorrowOptimizer} from "../BorrowOptimizer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LibString} from "../utils/LibString.sol";

contract BorrowOptimizerResolver is Ownable {
    BorrowOptimizer public immutable bo;
    uint256 public missThreshold;
    using LibString for uint256;

    /// @notice missThreshold is scaled to 1 decimal, so entering a _missThreshold of 1 will set the threshold to 0.1%
    constructor(BorrowOptimizer _borrowOptimizer, uint256 _missThreshold) Ownable() {
        bo = _borrowOptimizer;
        missThreshold = _missThreshold;
    }

    function shouldRebalance() external returns (bool canExec, bytes memory execPayload) {
        if (bo.totalAssets() == 0) return (false, "No assets in vault.");

        uint256 miss = borrowTargetMiss();

        if (miss < missThreshold) return (false, abi.encodePacked("Miss threshold not met. Current miss: ", miss.toString()));

        execPayload = abi.encodeCall(BorrowOptimizer.rebalance, ());
        return (true, execPayload);
    }

    function borrowTargetMiss() public returns (uint256 missFactor) {
        // 1000 = 1 = 100%
        // 0100 = 0.1 = 10%
        // 0010 = 0.01 = 1%
        // 0001 = 0.001 = 0.1%
        missFactor = (bo.borrowBalance() * 1000) / bo.borrowTarget();
        if (missFactor < 1000) {
            return 1000 - missFactor;
        } else {
            return missFactor - 1000;
        }
    }

    /// @notice missThreshold is scaled to 1 decimal, so entering a _missThreshold of 1 will set the threshold to 0.1%
    function setMissThreshold(uint256 _missThreshold) public onlyOwner {
        missThreshold = _missThreshold;
    }
}
