pragma solidity ^0.8.0;

import {Comptroller} from "../lenders/compound/Comptroller.sol";

abstract contract Moontroller is Comptroller {
    /**
     * @notice Claim all the WELL accrued by holder in all markets
     * @param holder The address to claim WELL for
     */
    function claimReward(uint8 rewardType, address payable holder) public virtual;

    /**
     * @notice Claim all the WELL accrued by holder in the specified markets
     * @param holder The address to claim WELL for
     * @param mTokens The list of markets to claim WELL in
     */
    function claimReward(uint8 rewardType, address payable holder, address[] memory mTokens) public virtual;
}
