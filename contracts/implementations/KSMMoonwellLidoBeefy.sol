pragma solidity ^0.8.0;

import {BorrowOptimizer} from "../BorrowOptimizer.sol";
import {MoonwellLender} from "../lenders/MoonwellLender.sol";
// TODO: Implement sandwich attack protection
contract KSMMoonwellLidoBeefy is BorrowOptimizer, MoonwellLender {
    function beforeRepay() internal override {}
    function afterBorrow() internal override {}
    function compound() public {}
}