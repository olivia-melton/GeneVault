# GeneVault - Biotech Protocol on Stacks

GeneVault is a decentralized smart contract protocol built on the Stacks blockchain using Clarity. It provides synthetic exposure to gene editing breakthroughs, personalized medicine, and genetic advancement through a tokenized vault system.

## Overview

GeneVault enables investors to gain exposure to biotech innovation through a secure, transparent, and decentralized mechanism. Users deposit STX to receive GENE tokens, which represent fractional ownership in curated biotech vaults. The protocol features reward mechanisms, fee structures, and governance readiness for future decentralization.

## Key Features

### Tokenomics

- **GENE Token**: Fungible token representing vault shares and governance rights
- **Initial Supply**: 1 billion GENE tokens
- **Decimal Places**: 12 decimals for precision
- **Use Cases**: Vault deposits, reward accumulation, future governance voting

### Vault System

- **Multi-Vault Architecture**: Support for multiple biotech-focused vaults covering different sectors (CRISPR, gene therapy, personalized medicine, etc.)
- **Vault States**: Vaults can be open for deposits or closed during market volatility or maintenance
- **Vault Tracking**: Each vault maintains comprehensive records of total deposits, withdrawals, and performance metrics

### Deposit and Withdrawal

- **Minimum Deposit**: 0.001 STX
- **Deposit Fee**: 2% of deposited amount
- **Withdrawal Fee**: 1% of withdrawn amount
- **1:1 Conversion**: GENE tokens are minted at a 1:1 ratio to net deposit amount
- **Fee Distribution**: All fees accumulate in the protocol balance for rewards and operational costs

### Reward System

- **APY-Based Rewards**: Users earn rewards based on their GENE holdings
- **Default APY**: 15% annual percentage yield (owner adjustable)
- **Block-Based Calculation**: Rewards calculated based on blocks staked
- **Claim Mechanism**: Users actively claim rewards; no automatic distribution

### Security Features

- **Owner Controls**: Protocol initialization and vault management restricted to contract owner
- **Error Handling**: Comprehensive error codes for debugging and user feedback
- **Minimum Thresholds**: Deposit minimums prevent dust accounts and network spam
- **Vault Status Checks**: All operations validate vault operational status

## Contract Functions

### Public Functions

#### initialize-protocol()
Initializes the protocol by minting the initial GENE token supply to the contract owner. Must be called before any other operations.

```
(initialize-protocol) -> (response bool uint)
```

#### create-vault(name, description)
Creates a new vault within the protocol. Only callable by the contract owner.

Parameters:
- name: Vault name (max 64 characters)
- description: Vault description (max 256 characters)

Returns: Vault ID (uint)

#### deposit(vault-id, amount)
Deposits STX into a vault and receives GENE tokens in return. Applies 2% deposit fee.

Parameters:
- vault-id: ID of target vault
- amount: STX amount to deposit (minimum 0.001 STX)

Returns: 
- gene-received: GENE tokens minted
- fee-paid: Deposit fee amount

#### withdraw(vault-id, gene-amount)
Burns GENE tokens to withdraw STX from the vault. Applies 1% withdrawal fee.

Parameters:
- vault-id: ID of source vault
- gene-amount: GENE tokens to burn and redeem

Returns:
- stx-received: STX amount returned
- fee-paid: Withdrawal fee amount

#### claim-rewards(vault-id)
Claims accumulated APY rewards on staked GENE tokens. Updates the user's last claim timestamp.

Parameters:
- vault-id: ID of vault to claim rewards from

Returns:
- reward-amount: GENE tokens awarded

#### update-apy(new-apy)
Updates the protocol's APY rate. Only callable by contract owner. Maximum APY capped at 100%.

Parameters:
- new-apy: New APY in basis points (1 = 0.01%)

Returns: Boolean confirmation

#### close-vault(vault-id)
Closes a vault to new deposits and withdrawals in emergency situations. Only callable by contract owner.

Parameters:
- vault-id: ID of vault to close

Returns: Boolean confirmation

### Read-Only Functions

#### get-balance(user, vault-id)
Returns the GENE token balance for a user in a specific vault.

Returns: GENE balance (uint)

#### get-vault-info(vault-id)
Returns comprehensive information about a vault including status, total deposits/withdrawals, and timestamps.

Returns: Vault data structure

#### get-tvl()
Returns the total value locked (TVL) across all vaults in STX equivalent.

Returns: TVL amount (uint)

#### get-protocol-balance()
Returns the accumulated protocol balance from all fees.

Returns: Protocol balance (uint)

## Data Structures

### Vault State
Each vault maintains:
- name: Vault identifier
- description: Vault purpose and details
- status: Open or closed state
- total-deposits: Cumulative STX deposits
- total-withdrawals: Cumulative STX withdrawals
- created-at: Vault creation block height
- last-updated: Last modification block height

### User Positions
Each user's position in a vault includes:
- gene-balance: Current GENE holdings
- stx-deposited: Total STX deposited
- deposit-timestamp: Latest deposit timestamp
- last-claim: Last rewards claim timestamp

### Vault Performance
Daily performance tracking:
- apy: Daily APY snapshot
- tvl: Daily TVL snapshot

## Error Codes

| Code | Description |
|------|-------------|
| 1001 | Unauthorized - Caller is not contract owner |
| 1002 | Unauthorized - Not permitted to create vault |
| 2001 | Vault not found |
| 2002 | Deposit below minimum threshold |
| 2003 | Vault is closed |
| 2004 | User position not found |
| 2005 | Insufficient GENE balance |
| 2006 | No rewards available to claim |
| 2007 | APY exceeds maximum limit |

## Deployment Guide

### Prerequisites

- Clarinet development environment installed
- STX testnet or mainnet access
- Basic understanding of Clarity smart contracts

### Deployment Steps

1. Clone the repository and navigate to the contracts directory

2. Run contract validation:
```
clarinet check
```

3. Deploy to testnet:
```
clarinet deployments apply --network testnet
```

4. Initialize the protocol after deployment:
```
clarinet contract call GeneVault initialize-protocol
```

5. Create your first biotech vault:
```
clarinet contract call GeneVault create-vault \
  --args "CRISPR Innovation" "Vault focused on CRISPR gene editing breakthroughs"
```

## Usage Example

### For Investors

1. Deposit STX into a biotech vault:
```
clarinet contract call GeneVault deposit \
  --args 0 1000000  ;; Deposit 0.001 STX to vault 0
```

2. Check your GENE balance:
```
clarinet contract call GeneVault get-balance <your-principal> 0
```

3. Claim rewards after holding for 100+ blocks:
```
clarinet contract call GeneVault claim-rewards 0
```

4. Withdraw GENE for STX:
```
clarinet contract call GeneVault withdraw 0 500000  ;; Withdraw 0.5 GENE
```

### For Protocol Administrators

1. Update APY to 20%:
```
clarinet contract call GeneVault update-apy 2000  ;; 2000 basis points = 20%
```

2. Close a vault during market stress:
```
clarinet contract call GeneVault close-vault 0
```

## Fee Structure

### Deposit Fees (2%)
Applied to all deposits. Automatically transferred to protocol balance for operational costs and community rewards.

### Withdrawal Fees (1%)
Applied to all withdrawals. Accumulated in protocol balance.

### Example Calculation
- Deposit 1 STX
- 2% fee = 0.02 STX
- Net deposit = 0.98 STX
- GENE received = 980,000 GENE tokens

## Future Roadmap

- Governance token allocation and voting mechanisms
- Integration with oracle services for real biotech metrics
- Cross-chain interoperability
- Advanced vault strategies and automated rebalancing
- Community treasury management
- GENE token staking for governance participation

## Security Considerations

### Audit Status
This contract has been designed with security best practices and simplicity for auditability. Comprehensive testing recommended before mainnet deployment.

### Known Limitations
- No external oracle integration (APY is manually managed)
- No automated liquidation mechanisms
- Simple 1:1 token conversion model
- No slashing or penalty mechanisms

### Risk Factors
- Smart contract risk: Exploits or vulnerabilities in contract code
- Regulatory risk: Biotech investment regulations may evolve
- Market risk: Vault performance depends on external biotech sector developments
- Liquidity risk: GENE tokens derive value from locked STX

## Community and Governance

GeneVault is designed to eventually transition to full community governance. Token holders will govern:
- APY parameters
- Fee structures
- New vault creation
- Protocol upgrades
- Treasury allocation

## Support and Documentation

For technical support, documentation, and community discussions:
- GitHub Issues: Report bugs and request features
- Clarity Documentation: https://docs.stacks.co/clarity
- Stacks Forum: Community support and discussions


## Disclaimer

GeneVault is a decentralized protocol for synthetic biotech exposure. Users should conduct their own research and understand the risks associated with cryptocurrency and blockchain-based investments. Past performance does not guarantee future results. Always verify contract addresses on official channels before interacting.