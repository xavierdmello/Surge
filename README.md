# Surge

(WIP) Automated delta neutral yield farming vaults.

Based off of the [Autolido](https://docs.google.com/document/d/1wQ-vzP7TlSUF-PgjePvF3JFit6_0J2Mg8zCSrj5tKfc/edit?usp=sharing) stragety I outlined.

incomplete TODO:
- sandwich attack protection
- gelato integration
- unbond withdrawls
- pausing
- access protection on rebalance() so people don't spam it and incure bad debt
- batch withdrawls so vaults don't get limited by the 20 unbond requests at a time limit on Lido
- create interfaces and remove redundant files for lido
- figure out how to deal with bad debt
- make sure people can withdraw even with an oracle error
- compound lending market rewards
