pragma solidity ^0.8.0;

import {BaseVault} from "./BaseVault.sol";
import {IBaseLender} from "./lenders/IBaseLender.sol";

/// @author Xavier D'Mello www.xavierdmello.com
contract BorrowOptimizer is BaseVault, IBaseLender {
    function beforeRepay() internal virtual {}
    function afterBorrow() internal virtual {}
}