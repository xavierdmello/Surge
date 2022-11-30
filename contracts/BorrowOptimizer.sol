pragma solidity ^0.8.0;

import {BaseVault} from "./BaseVault.sol";
import {IBaseLender} from "./lenders/IBaseLender.sol";
import {ERC20} from "./tokens/ERC20.sol";

/// @author Xavier D'Mello www.xavierdmello.com
abstract contract BorrowOptimizer is BaseVault, IBaseLender {

    // ERC20 public immutable asset (Stored in BaseVault())
    ERC20 public immutable borrow;

    constructor(ERC20 _asset, ERC20 _borrow, string memory _name, string memory _symbol) BaseVault(_asset, _name, _symbol) {
        borrow = borrow;

        readyMarkets();
    }


    function beforeRepay() internal virtual {}
    function afterBorrow() internal virtual {}
}