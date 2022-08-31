// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC4626} from "./solmate/mixins/ERC4626.sol";
import {ERC20} from "./solmate/tokens/ERC20.sol";
import {CErc20} from "./compound/CErc20.sol";
import {PriceOracle} from "./compound/PriceOracle.sol";
import {Comptroller} from "./compound/Comptroller.sol";

/// @author Xavier D'Mello www.xavierdmello.com
contract SLidoCompVault is ERC4626 {
	ERC20 public immutable borrow;
	PriceOracle public immutable priceOracle;
	Comptroller public immutable comptroller;
	CErc20 public immutable cAsset;
	CErc20 public immutable cBorrow;

	uint256 public depositLiquidity;

	constructor(
		CErc20 _cAsset,
		CErc20 _cBorrow,
		string memory _name,
		string memory _symbol
	) ERC4626(ERC20(_cAsset.underlying()), _name, _symbol) {
		cAsset = _cAsset;
		cBorrow = _cBorrow;

		// Convert ComptrollerInterface to Comptroller because some hidden functions need to be used
		comptroller = Comptroller(address(_cAsset.comptroller()));

		priceOracle = comptroller.oracle();
		borrow = ERC20(_cBorrow.underlying());

		// Enter Market
		address[] memory market = new address[](1);
		market[0] = address(cAsset);
		require(comptroller.enterMarkets(market)[0] == 0, "Surge: Compound Enter Market failed");
	}

	function afterDeposit(uint256 assets, uint256 shares) internal override {
		(uint256 beforeError, uint256 beforeLiquidity, uint256 beforeShortfall) = comptroller.getAccountLiquidity(
			address(this)
		);
		require(beforeError == 0, "Surge: Compound liquidity calculation failed");
		require(beforeShortfall == 0, "Surge: Cannot borrow, vault is underwater");

		asset.approve(address(cAsset), assets);
		require(cAsset.mint(assets) == 0, "Surge: Compound deposit failed");

		(uint256 afterError, uint256 afterLiquidity, uint256 afterShortfall) = comptroller.getAccountLiquidity(
			address(this)
		);
		require(afterError == 0, "Surge: Compound liquidity calculation failed");
		require(afterShortfall == 0, "Surge: Cannot borrow, vault is underwater");

		depositLiquidity = afterLiquidity - beforeLiquidity;
	}

	function beforeWithdraw(uint256 assets, uint256 shares) internal override {}

	// Asset Balance + (Value of Investments - Borrow Debt)
	function totalAssets() public override returns (uint256) {
		int256 borrowPrice = int256(priceOracle.getUnderlyingPrice(cBorrow));
		return
			uint256(
				int256(cAsset.balanceOfUnderlying(address(this))) +
					((borrowPrice *
						(int256(borrow.balanceOf(address(this))) -
							int256(cBorrow.borrowBalanceCurrent(address(this))))) /
						int256(10**(36 - borrow.decimals())))
			);
	}
}
