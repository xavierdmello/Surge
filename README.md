# Surge

(WIP) Automated delta neutral yield farming vaults.

Based off of the [Autolido](https://docs.google.com/document/d/1wQ-vzP7TlSUF-PgjePvF3JFit6_0J2Mg8zCSrj5tKfc/edit?usp=sharing) stragety I outlined.

## Testing
#### Note: This project is in it's early stages and testing may be incomplete or not work. I don't recommend going through the headache (yet)
1. Make sure you have node.js installed
2. Create a .env file and define CMC_KEY, PRIVATE_KEY, BOB, ALICE, MOONRIVER_RPC, MOONSCAN_KEY, and ETHEREUM_RPC (yes, this will be simplified later)
2. Run `yarn` to install dependencies
3. Run `yarn hardhat compile`
4. Run `yarn hardhat test`

## Misc
#### personal, incomplete TODO:
- sandwich attack protection
- gelato integration (WIP)
- unbond withdrawls
- pausing
- access protection on rebalance() so people don't spam it and incure bad debt
- batch withdrawls so vaults don't get limited by the 20 unbond requests at a time limit on Lido
- create interfaces and remove redundant files for lido
- make sure people can withdraw even with an oracle error
- compound lending market rewards
- make afterBorrow and beforeRepay return something?


-- urgent:
- check rounding math, look into rounding down

#### Notes:
- bad debt is caused when debt > stakedValueInAsset (i.e cost to borrow > staking rewards for too long)
    - can be fixed by sending the staked token directly to the vault
