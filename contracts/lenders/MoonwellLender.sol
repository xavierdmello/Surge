pragma solidity ^0.8.0;

import {IBaseLender} from "./IBaseLender.sol";
import {CErc20} from "./compound/CErc20.sol";
import {Moontroller} from "./interfaces/Moontroller.sol";

contract MoonwellLender is IBaseLender {
    Moontroller public immutable comptroller;
    CErc20 public immutable cAsset;
    CErc20 public immutable cBorrow;

    // Mapping of ERC20 Tokens to their respective cTokens
    mapping(address=> CErc20) public cToken;

    constructor(address _cAsset, address _cBorrow) {
        comptroller = Moontroller(address(CErc20(_cAsset).comptroller()));

        address asset = CErc20(_cAsset).underlying();
        address borrow = CErc20(_cBorrow).underlying();

        cAsset = CErc20(_cAsset);
        cBorrow = CErc20(_cBorrow);

        cToken[asset] = cAsset;
        cToken[borrow] = cBorrow;
    } 

    function readyMarkets() public internal {
        address[] memory market = new address[](1);
        market[0] = address(cAsset);
        require(comptroller.enterMarkets(market)[0] == 0, "Surge: Compound Enter Market failed");
    }

}

