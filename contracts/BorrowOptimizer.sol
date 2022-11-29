pragma solidity ^0.8.0;

import {BaseVault} from "./BaseVault.sol";

/// @author Xavier D'Mello www.xavierdmello.com
contract BorrowOptimizer is BaseVault{
    function beforeRepay() internal virtual {}
    function afterBorrow() internal virtual {}
}