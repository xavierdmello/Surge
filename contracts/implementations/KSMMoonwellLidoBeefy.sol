// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BorrowOptimizer} from "../BorrowOptimizer.sol";
import {MoonwellLender} from "../lenders/MoonwellLender.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICErc20} from "../interfaces/ICErc20.sol";
import {WstKSM} from "./lido/wstKSM.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {ERC20} from "../tokens/ERC20.sol";

// TODO: Implement sandwich attack protection
contract KSMMoonwellLidoBeefy is BorrowOptimizer, MoonwellLender, Ownable {
    /*Prevent safetyMargin from being set too low.
    This would cause borrowTarget() to be much lower than it currently is, which would in turn
    make the protocol swap large amounts of the borrowed token and incure bad debt from slippage.*/
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
        address from;
        uint256 amount;
        bool accepted;
    }
    mapping(address => UnbondRequest[]) public unbondRequests;
    mapping(address => bool) public isQuickWithdraw;

    WstKSM public immutable stWant;

    IUniswapV2Router02 private immutable router;
    address[] private rewardTokenPath;
    address[] private rewardEthPath;
    address[] private stWantPath;
    address[] private compoundPath;

    constructor(
        ICErc20 _cAsset,
        ICErc20 _cWant,
        WstKSM _stWant,
        address[] memory _rewardTokenPath,
        address[] memory _rewardEthPath,
        address[] memory _stWantPath,
        address[] memory _compoundPath,
        IUniswapV2Router02 _router,
        string memory _name,
        string memory _symbol
    )
        MoonwellLender(address(_cAsset), address(_cWant))
        BorrowOptimizer(ERC20(_cAsset.underlying()), ERC20(_cWant.underlying()), _name, _symbol)
        Ownable()
    {
        // Approvals
        ERC20 rewardToken = ERC20(rewardTokenPath[0]);
        rewardToken.approve(address(_router), type(uint256).max);
        WstKSM(_stWant).approve(address(_router), type(uint256).max);
        want.approve(address(_stWant), type(uint256).max);

        stWant = _stWant;
        rewardTokenPath = _rewardTokenPath;
        rewardEthPath = _rewardEthPath;
        stWantPath = _stWantPath;
        compoundPath = _compoundPath;
        router = _router;
    }

    function unbond() public {}

    function setUnbondCap(uint8 newCap) public onlyOwner {
        require(newCap <= maxUnbondCap, "Surge: Unbond cap cannot be set over maxUnbondCap.");
        unbondCap = newCap;
    }

    function setSafetyMargin(uint8 newMargin) public onlyOwner {
        require(
            newMargin <= maxSafetyMargin && newMargin >= minSafetyMargin,
            "Surge: Safety margin cannot be set over maxSafetyMargin or under minSafetyMargin."
        );
        safetyMargin = newMargin;
    }

    function setFee(uint8 newFee) public onlyOwner {
        require(newFee <= maxFee, "Surge: Fee cannot be set over maxFee");
        fee = newFee;
    }

    function quickWithdraw(uint256 assets) public {
        isQuickWithdraw[msg.sender] = true;
        withdraw(assets, msg.sender, msg.sender);
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/) internal override returns (uint256) {
        if (isQuickWithdraw[msg.sender] == true) {
            isQuickWithdraw[msg.sender] = false;

            uint256 lendTarget = lendTarget();
            uint256 lendBalance = lendBalance();

            // Amount of 'asset' that can be withdrawn safely *without* needing to repay debt.
            // This is possible if the vault is unbalanced and overcollateralized over the safetyMargin.
            uint256 nonSwapWithdraw = 0;
            if (lendBalance > lendTarget) {
                uint256 maxNonSwapWithdraw = lendBalance - lendTarget;
                if (assets > maxNonSwapWithdraw) {
                    nonSwapWithdraw = maxNonSwapWithdraw;
                } else {
                    nonSwapWithdraw = assets;
                }
            }
            // nonSwapWithdraw cannot be larger than assets
            uint256 leftoverAssets = assets - nonSwapWithdraw;

            if (leftoverAssets > 0) {
                // How much wstKSM that needs to be swapped to KSM and repaid to the lending protocol to unlock assets to withdraw.
                uint256 swapAmount = (((leftoverAssets * exchangeRate()) / 1e18) * stakedExchangeRate()) / 1e18;
                // TODO: Sandwich attack protection
                uint256 actualReceived = router.swapExactTokensForTokens(
                    swapAmount,
                    0,
                    stWantPath,
                    address(this),
                    block.timestamp
                )[1];
                repay(actualReceived);

                uint256 actualWithdraw = (actualReceived * 1e18) / exchangeRate() + nonSwapWithdraw;
                withdraw(actualWithdraw);
                return actualWithdraw;
            } else {
                withdraw(assets);
                return assets;
            }
        } else {
            // for now
            // TODO: change
            revert();
        }
    }

    /**
     * Exchange rate borrow:staked tokens, scaled to 18 decimals.
     */
    function stakedExchangeRate() internal returns (uint256) {}

    function totalAssets() public override returns (uint256) {
        return lendBalance() - debt() + stakedValueInAsset();
    }

    /**
     * The value, denominated in 'asset', of the tokens staked by this vault.
     */
    function stakedValueInAsset() public returns (uint256) {
        // for now, change later
        // TODO: change
        return debt();
    }

    /**
     * The value, denominated in 'want', of the tokens staked by this vault.
     */
    function stakedValueInWant() public returns (uint256) {}

    /**
     * The value, denominated in 'asset', of the borrows owed back to the lendee.
     */
    function debt() public returns (uint256) {
        return (borrowBalance() * 1e18) / exchangeRate();
    }

    function beforeRepay(uint256 amount) internal override {}

    function afterBorrow(uint256 amount) internal override {}

    function compound() public {
        uint256 stakedBalance = stWant.balanceOf(address(this));
        uint256 borrowBalanceInStaked = (borrowBalance() * stakedExchangeRate()) / 1e18;
        if (stakedBalance > borrowBalanceInStaked) {
            uint256 swapAmount = stakedBalance - borrowBalanceInStaked;
            // TODO: Sandwich attack protection
            uint256 actualReceived = router.swapExactTokensForTokens(swapAmount, 0, compoundPath, address(this), block.timestamp)[
                compoundPath.length - 1
            ]; // this .length might break things whoops
            lend(actualReceived);
        }
    }
}
