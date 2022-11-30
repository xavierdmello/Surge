pragma solidity ^0.8.0;

import {BorrowOptimizer} from "../BorrowOptimizer.sol";
import {MoonwellLender} from "../lenders/MoonwellLender.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {CErc20} from "../lenders/compound/CErc20.sol";
import {WstKSM} from "./lido/wstKSM.sol";

// TODO: Implement sandwich attack protection
contract KSMMoonwellLidoBeefy is BorrowOptimizer, MoonwellLender, Ownable {
    /*Prevent safetyMargin from being set too low.
    This would cause borrowTarget() to be much lower than it currently is, which would in turn
    make the protocol swap large amounts of the borrow token and incure bad debt from slippage.*/
    uint256 constant minSafetyMargin = 70;
    uint256 constant maxSafetyMargin = 90;

    // Percentage of *profits* that are sent to the treasury
    // (There is no fee for depositing/withdrawing)
    uint256 public fee = 25;
    uint256 constant maxFee = 50;

    // Prevent the entire amount of KSM from being unbonded at once.
    // There has to be some liquidity remaning to facilitate rebalancing & avoid liquidations.
    uint256 public unbondCap = 50;
    uint256 constant maxUnbondCap = 80;
    struct UnbondRequest {
        ;
    }
    mapping(address => UnbondRequest[]) public unbondRequests;
    mapping(address => bool) public isQuickWithdraw;

    WstKSM public immutable stBorrow;

    constructor(CErc20 _cAsset, CErc20 _cBorrow, WstKSM _stBorrow, string memory _name, string memory _symbol) BorrowOptimizer(_cAsset.underlying(), _cBorrow.underlying(), _name, _symbol) MoonwellLender(address(_cAsset), address(_cBorrow)) Ownable() {
        approveContracts();
        stBorrow = _stBorrow;
    }
    
    function unbond() public {}

    function setUnbondCap(uint8 newCap) public onlyOwner {
        require(newCap <= maxUnbondCap, "Surge: Unbond cap cannot be set over maxUnbondCap.");
        unbondCap = newCap;
    }

    function setSafetyMargin(uint8 newMargin) public onlyOwner {
        require(newMargin <= maxSafetyMargin && newMargin >= minSafetyMargin, "Surge: Safety margin cannot be set over maxSafetyMargin or under minSafetyMargin.");
        safteyMargin = newMargin;
    }

    function setFee(uint8 newFee) public onlyOwner {
        require (newFee <= maxFee, "Surge: Fee cannot be set over maxFee");
    }

    function quickWithdraw(uint256 assets) public {
        isQuickWithdraw[msg.sender] = true;
        withdraw(assets, msg.sender, msg.sender);
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        if (isQuickWithdraw[msg.sender] == true) {
            isQuickWithdraw[msg.sender] = false;

            // Share of staked tokens the user is withdrawing
            uint256 swapAmount = (((assets * exchangeRate())/1e18)*stakedExchangeRate())/1e18; // TODO: fix, this doesn't work
            // TODO: Sandwich attack protection
            uint256 actualReceived = router.swapExactTokensForTokens(
                swapAmount,
                0,
                stBorrowPath,
                address(this),
                block.timestamp
            )[1];


        } else {
            // for now
            // TODO: change
            revert(); 
        }
    }

    /**
     * Exchange rate borrow:staked tokens, scaled to 18 decimals.
     */
    function stakedExchangeRate() internal returns(uint256) {

    }

    function totalAssets() public override returns (uint256) {
        return lendBalance() - debt() + stakedValueInAsset();
    }
    
    /**
     * The value, denominated in 'asset', of the tokens staked by this vault.
     */
    function stakedValueInAsset() public view returns(uint256) {
        // for now, change later
        // TODO: change
        return debt();
    }

    /**
     * The value, denominated in 'borrow', of the tokens staked by this vault.
     */
    function stakedValueInBorrow() public view returns(uint256) {

    }

    /**
     * The value, denominated in 'asset', of the borrows owed back to the lendee.
     */
    function debt() public returns(uint256) {
        return (borrowBalance()*1e18)/exchangeRate();
    }

    function beforeRepay(uint256 amount) internal override {}

    function afterBorrow(uint256 amount) internal override {}

    function compound() public {
        uint256 stakedBalance = stBorrow.balanceOf(address(this));
        uint256 borrowBalanceInStaked = (borrowBalance() * stakedExchangeRate())/1e18;
        if (stakedBalance > borrowBalanceInStaked) {
            uint256 swapAmount = stakedBalance-borrowBalanceInStaked;
            // TODO: Sandwich attack protection
            uint256 actualReceived = router.swapExactTokensForTokens(
                swapAmount,
                0,
                compoundPath,
                address(this),
                block.timestamp
            )[compoundPath.length-1];// this .length might break things whoops
            lend(actualReceived);
        }
    }

    function approveContracts() internal {
        stBorrow.approve(address(router), type(uint256).max);
        borrow.approve(address(stBorrow), type(uint256).max);
        rewardToken.approve(address(router), type(uint256).max);
    }
}
