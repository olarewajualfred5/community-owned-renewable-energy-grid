# Community-Owned Renewable Energy Grid

A decentralized platform for community-owned renewable energy infrastructure, built on the Stacks blockchain using Clarity smart contracts. This system enables communities to collectively own, operate, and benefit from renewable energy assets through tokenization, democratic governance, and transparent profit distribution.

## Overview

This project implements a comprehensive system for managing community-owned renewable energy grids. The platform allows community members to purchase shares in renewable energy assets, participate in governance decisions, and receive proportional returns from energy production and sales.

## Architecture

### Core Components

1. **Energy Shares Contract** (`energy-shares.clar`)
   - Tokenizes ownership of renewable energy assets
   - Manages share issuance and trading
   - Tracks ownership stakes and voting rights
   - Handles dividend distribution from energy profits
   - Implements share transfer and delegation mechanisms

2. **Grid Governance Contract** (`grid-governance.clar`)
   - Facilitates democratic decision-making for grid operations
   - Manages proposal creation and voting processes
   - Handles governance parameter adjustments
   - Oversees infrastructure expansion decisions
   - Implements quadratic voting for fair representation

## Features

- **Tokenized Ownership**: Community members own shares representing stakes in energy assets
- **Democratic Governance**: Collective decision-making through on-chain voting mechanisms
- **Profit Distribution**: Automatic distribution of energy revenue to shareholders
- **Transparent Operations**: All transactions and decisions recorded on-chain
- **Renewable Focus**: Dedicated to clean energy infrastructure development
- **Community Benefits**: Local energy independence and economic empowerment
- **Scalable Model**: Framework for expanding to multiple communities

## Smart Contract APIs

### Energy Shares Contract

#### Core Functions
- `issue-shares`: Create new shares for energy asset investments
- `transfer-shares`: Transfer ownership between community members
- `delegate-voting`: Delegate voting rights to trusted representatives
- `claim-dividends`: Collect earned profits from energy sales
- `calculate-returns`: Determine expected returns from energy production
- `get-share-info`: Retrieve detailed ownership information

#### Management Functions
- `set-dividend-rate`: Adjust profit distribution percentage
- `pause-trading`: Temporarily halt share transfers for maintenance
- `update-asset-value`: Reflect current valuation of energy infrastructure
- `add-energy-asset`: Register new renewable energy installations

### Grid Governance Contract

#### Core Functions
- `create-proposal`: Submit new governance proposals for community voting
- `cast-vote`: Vote on active proposals using share-weighted system
- `execute-proposal`: Implement approved governance decisions
- `delegate-vote`: Assign voting power to community representatives
- `get-voting-power`: Calculate voting strength based on shares owned

#### System Functions
- `set-voting-period`: Configure duration for proposal voting
- `update-quorum`: Adjust minimum participation requirements
- `add-governance-token`: Introduce new voting mechanisms
- `emergency-pause`: Halt operations during critical situations

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) - JavaScript runtime for testing and integration
- [Git](https://git-scm.com/) - Version control system

### Installation

1. Clone the repository:
```bash
git clone https://github.com/olarewajualfred5/community-owned-renewable-energy-grid.git
cd community-owned-renewable-energy-grid
```

2. Install dependencies:
```bash
npm install
```

3. Verify contract syntax:
```bash
clarinet check
```

### Testing

Run the comprehensive test suite:
```bash
clarinet test
```

Run contract-specific tests:
```bash
clarinet test --filter energy-shares
clarinet test --filter grid-governance
```

### Local Development

Start local blockchain environment:
```bash
clarinet integrate
```

Deploy contracts to devnet:
```bash
clarinet deploy --devnet
```

## Usage Examples

### Purchasing Energy Shares

```clarity
;; Community member buys shares in renewable energy project
(contract-call? .energy-shares issue-shares 
  tx-sender
  u1000    ;; 1000 shares
  u500000  ;; 500 STX investment
  "Solar Farm Phase 1")
```

### Creating Governance Proposals

```clarity
;; Propose new wind turbine installation
(contract-call? .grid-governance create-proposal
  "Install 5MW Wind Turbine Array"
  "Expand renewable capacity with wind energy installation"
  u2000000  ;; 2000 STX required funding
  u1008)    ;; 1 week voting period
```

### Voting on Proposals

```clarity
;; Cast vote supporting the wind turbine proposal
(contract-call? .grid-governance cast-vote
  u1      ;; proposal-id
  true    ;; vote in favor
  u500)   ;; voting weight based on shares owned
```

### Claiming Dividends

```clarity
;; Collect earned dividends from energy sales
(contract-call? .energy-shares claim-dividends
  tx-sender
  u2023  ;; dividend period
  u4)    ;; quarter
```

## Configuration

### Network Settings

#### Devnet (Local Development)
```toml
[devnet]
stacks_node_rpc_address = "http://localhost:20443"
stacks_node_p2p_address = "http://localhost:20444"
```

#### Testnet (Testing)
```toml
[testnet]
stacks_node_rpc_address = "https://api.testnet.hiro.so"
bitcoin_node_rpc_address = "https://blockstream.info/testnet/api"
```

#### Mainnet (Production)
```toml
[mainnet]
stacks_node_rpc_address = "https://api.hiro.so"
bitcoin_node_rpc_address = "https://blockstream.info/api"
```

### System Parameters

- **Share Price**: Dynamic pricing based on asset valuation
- **Dividend Rate**: 70% of net profits distributed to shareholders
- **Voting Period**: 1 week default for governance proposals
- **Minimum Quorum**: 30% of total shares must participate
- **Proposal Threshold**: 5% of shares needed to create proposals
- **Emergency Pause**: 48-hour cool-down for critical decisions

## Economic Model

### Revenue Streams
- **Energy Sales**: Primary income from electricity generation
- **Grid Services**: Revenue from stability and ancillary services
- **Carbon Credits**: Environmental benefits monetization
- **Excess Capacity**: Selling surplus energy to neighboring communities

### Cost Structure
- **Infrastructure Maintenance**: 15% of revenue
- **Operations Management**: 10% of revenue
- **Platform Fees**: 5% of revenue
- **Community Development**: 5% of revenue
- **Shareholder Dividends**: 65% of net revenue

### Share Valuation
- Based on discounted cash flow from energy assets
- Adjusted for infrastructure depreciation
- Includes environmental and social impact premiums
- Market-driven pricing through community trading

## Governance Model

### Proposal Types
- **Infrastructure Expansion**: New renewable energy installations
- **Operational Changes**: Grid management and maintenance decisions
- **Financial Allocations**: Budget approvals and dividend policies
- **Partnership Agreements**: External collaborations and contracts
- **Emergency Responses**: Crisis management and safety protocols

### Voting Mechanisms
- **Share-Weighted Voting**: Influence proportional to ownership stake
- **Quadratic Voting**: Prevents concentration of power
- **Delegation Systems**: Representative voting for complex decisions
- **Time-Locked Voting**: Prevent last-minute manipulation
- **Multi-Stage Voting**: Complex proposals require multiple approvals

## Security Features

### Access Controls
- Share ownership verification for voting rights
- Multi-signature requirements for large expenditures
- Time-locked proposal execution
- Emergency pause mechanisms

### Financial Protection
- Segregated funds for different operational purposes
- Insurance coverage for infrastructure assets
- Risk management through diversified energy sources
- Transparent financial reporting and auditing

### Governance Security
- Proposal validation and spam prevention
- Vote privacy and manipulation protection
- Delegation verification and limits
- Historical decision tracking and accountability

## Environmental Impact

### Renewable Energy Focus
- Solar panel installations with community ownership
- Wind turbine cooperatives for consistent generation
- Battery storage systems for grid stability
- Smart grid technology for efficient distribution

### Community Benefits
- Reduced energy costs for local residents
- Energy independence and security
- Local job creation in renewable energy sector
- Environmental stewardship and education

### Sustainability Metrics
- Carbon footprint reduction tracking
- Renewable energy generation statistics
- Community energy consumption patterns
- Environmental impact assessment reporting

## API Integration

### Frontend Integration

```typescript
import { makeContractCall, callReadOnlyFunction } from '@stacks/transactions';

// Purchase energy shares
const buySharesTx = await makeContractCall({
  contractAddress: deployerAddress,
  contractName: 'energy-shares',
  functionName: 'issue-shares',
  functionArgs: [
    principalCV(buyerAddress),
    uintCV(shareAmount),
    uintCV(investmentAmount),
    stringUtf8CV(assetDescription)
  ],
  network: network,
  senderKey: privateKey
});

// Check voting power
const votingPower = await callReadOnlyFunction({
  contractAddress: deployerAddress,
  contractName: 'grid-governance',
  functionName: 'get-voting-power',
  functionArgs: [principalCV(voterAddress)],
  network: network
});
```

### Energy Data Integration

```javascript
// Monitor energy production
const energyMetrics = await fetch('/api/energy-production', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  }
});

// Update share valuations
const assetValuation = await fetch('/api/asset-valuation', {
  method: 'POST',
  body: JSON.stringify({
    assetId: 'solar-farm-01',
    newValue: calculatedValue
  })
});
```

## Roadmap

### Phase 1 (Current)
- [x] Basic share tokenization system
- [x] Governance voting mechanisms
- [x] Dividend distribution logic
- [x] Community member management

### Phase 2 (Q1 2024)
- [ ] Advanced voting algorithms (quadratic voting)
- [ ] Cross-community energy trading
- [ ] Carbon credit tokenization
- [ ] Mobile application interface

### Phase 3 (Q2 2024)
- [ ] AI-powered energy optimization
- [ ] Peer-to-peer energy marketplace
- [ ] Integration with smart home systems
- [ ] Regulatory compliance framework

### Phase 4 (Q3 2024)
- [ ] Multi-chain compatibility
- [ ] Enterprise partnership integrations
- [ ] Advanced analytics dashboard
- [ ] Community education platform

## Contributing

We welcome contributions from community members and developers:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with proper tests
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Development Guidelines
- Follow Clarity best practices and conventions
- Include comprehensive tests for new functionality
- Update documentation for API changes
- Ensure backward compatibility where possible

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support & Community

- **Documentation**: [docs.renewablegrid.io](https://docs.renewablegrid.io)
- **Discord**: [Join our community](https://discord.gg/renewable-grid)
- **Twitter**: [@RenewableGrid](https://twitter.com/RenewableGrid)
- **Email**: community@renewablegrid.io

## Acknowledgments

- Inspired by cooperative energy models worldwide
- Built with support from renewable energy advocates
- Powered by Stacks blockchain technology
- Community-driven development approach

---

**Empowering communities through decentralized renewable energy ownership.** 🌱⚡️🏘️
