pragma solidity ^0.8.0;

/// @author Xavier D'Mello www.xavierdmello.com
contract BorrowOptimizer {
    function beforeRepay() internal virtual {}
    function afterBorrow() internal virtual {}
}