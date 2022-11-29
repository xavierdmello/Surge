pragma solidity ^0.8.0;

import {BorrowOptimizer} from "../BorrowOptimizer.sol";

contract KSMMoonwellLidoBeefy is BorrowOptimizer {
    function beforeRepay() internal override {}
    function afterBorrow() internal override {}
    function compound() public {}
}