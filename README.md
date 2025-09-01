# Decentralized Credit Union Management Contract

## Overview

This project implements a comprehensive smart contract system for managing a decentralized credit union on the Stacks blockchain. The contract enables member ownership, democratic governance, profit sharing, community lending, member services, and regulatory compliance - all the core principles of cooperative financial institutions.

## Key Features

### 🏛️ Member Ownership & Democratic Governance
- **Member Registration**: Join the credit union with a minimum deposit
- **Voting Power**: Proportional to member's share balance in the union
- **Proposal System**: Members can create and vote on governance proposals
- **Democratic Decision Making**: 51% threshold for major decisions like loan approvals

### 💰 Profit Sharing & Dividend Distribution
- **Annual Profit Tracking**: Record and manage yearly profits
- **Dividend Distribution**: Automatic calculation of dividends per member
- **Member Claims**: Individual members can claim their earned dividends
- **Transparent Accounting**: Full visibility into profit distribution

### 🏦 Community Lending & Local Investment
- **Loan Requests**: Members can request loans with collateral requirements
- **Governance Approval**: All loans require community vote for approval
- **Interest Management**: Flexible interest rate setting
- **Repayment Tracking**: Complete loan lifecycle management
- **Collateral Protection**: 120% minimum collateral requirement

### 🛡️ Member Services & Benefits
- **Financial Counseling**: Access to financial advisory services
- **Insurance Access**: Group insurance benefits coordination
- **Educational Programs**: Financial literacy and skill development
- **Emergency Assistance**: Crisis support for members
- **Business Development**: Entrepreneurship and business growth support

### 📋 Regulatory Compliance & Cooperative Principles
- **Compliance Officer**: Designated authority for regulatory oversight
- **Event Logging**: Comprehensive audit trail of all activities
- **Member Suspension**: Ability to suspend non-compliant members
- **Transparent Operations**: All actions are recorded and traceable

## Architecture

### Data Structures

#### Members
```clarity
{
  share-balance: uint,        // Member's ownership stake
  join-date: uint,           // Block height when joined
  is-active: bool,           // Active membership status
  voting-power: uint,        // Voting weight in governance
  total-dividends-earned: uint // Lifetime dividend earnings
}
```

#### Loans
```clarity
{
  borrower: principal,       // Loan recipient
  amount: uint,             // Principal amount
  interest-rate: uint,      // Rate in basis points (500 = 5%)
  term-blocks: uint,        // Loan duration in blocks
  issued-at: uint,          // Issue timestamp
  due-at: uint,             // Due date
  amount-repaid: uint,      // Amount repaid so far
  is-approved: bool,        // Governance approval status
  is-active: bool,          // Active loan status
  collateral-amount: uint   // Collateral backing the loan
}
```

#### Proposals
```clarity
{
  proposer: principal,       // Who created the proposal
  title: string-ascii,       // Proposal title
  description: string-ascii, // Detailed description
  proposal-type: string-ascii, // Type: \"loan\", \"policy\", \"budget\"
  target-loan-id: optional uint, // For loan proposals
  created-at: uint,         // Creation timestamp
  voting-ends-at: uint,     // Voting deadline
  votes-for: uint,          // Supporting votes
  votes-against: uint,      // Opposing votes
  is-executed: bool         // Execution status\n}\n```\n\n## Usage Examples\n\n### Becoming a Member\n```clarity\n;; Register as a new member with 1000 units initial deposit\n(contract-call? .credit-union register-member u1000)\n```\n\n### Creating a Governance Proposal\n```clarity\n;; Propose approval for loan ID 1\n(contract-call? .credit-union create-proposal \n  \"Approve Loan for Community Garden\"\n  \"This loan will fund the establishment of a community garden that will benefit all members\"\n  \"loan\"\n  (some u1))\n```\n\n### Voting on Proposals\n```clarity\n;; Vote in favor of proposal ID 1\n(contract-call? .credit-union vote-on-proposal u1 true)\n```\n\n### Requesting a Loan\n```clarity\n;; Request 5000 units loan at 5% APR for 5000 blocks with 6000 units collateral\n(contract-call? .credit-union request-loan u5000 u500 u5000 u6000)\n```\n\n### Enrolling in Member Services\n```clarity\n;; Enroll in financial counseling service\n(contract-call? .credit-union enroll-in-service \"financial-counseling\")\n```\n\n## Governance Model\n\nThe credit union operates on **democratic principles**:\n\n1. **One Member, One Vote Weighted by Ownership**: Voting power is proportional to share balance\n2. **Proposal-Driven Decisions**: All major decisions go through the proposal process\n3. **Transparent Voting**: All votes are recorded and auditable\n4. **Time-Bound Decisions**: Proposals have a 24-hour voting period\n5. **Majority Rule**: 51% threshold for proposal approval\n\n## Security Features\n\n- **Access Controls**: Role-based permissions for different functions\n- **Collateral Requirements**: 120% minimum collateral for loans\n- **Compliance Logging**: Complete audit trail of all operations\n- **Member Verification**: All lending functions require active membership\n- **Governance Approval**: Critical decisions require community consensus\n\n## Compliance & Regulatory Features\n\n- **Event Logging**: Every action is logged with timestamps and details\n- **Member Suspension**: Compliance officer can suspend non-compliant members\n- **Audit Trail**: Complete history of all financial transactions\n- **Transparency**: All operations are visible and verifiable\n- **Cooperative Principles**: Adherence to democratic governance standards\n\n## Technology Stack\n\n- **Blockchain**: Stacks (Bitcoin Layer 2)\n- **Smart Contract Language**: Clarity\n- **Development Framework**: Clarinet\n- **Testing**: Vitest with TypeScript\n- **Version Control**: Git with GitHub integration\n\n## Getting Started\n\n### Prerequisites\n- [Clarinet](https://docs.hiro.so/clarinet) installed\n- Node.js and npm\n- Git\n\n### Installation\n```bash\n# Clone the repository\ngit clone https://github.com/abbaali7139/decentralized-credit-union.git\ncd decentralized-credit-union\n\n# Install dependencies\nnpm install\n\n# Check contract syntax\nclarinet check\n\n# Run tests\nnpm test\n```\n\n### Development\n```bash\n# Start Clarinet console for contract interaction\nclarinet console\n\n# Deploy to local devnet\nclarinet integrate\n```\n\n## Contributing\n\n1. Fork the repository\n2. Create a feature branch (`git checkout -b feature/amazing-feature`)\n3. Commit your changes (`git commit -m 'Add amazing feature'`)\n4. Push to the branch (`git push origin feature/amazing-feature`)\n5. Open a Pull Request\n\n## License\n\nThis project is open source and available under the [MIT License](LICENSE).\n\n## Contact\n\nFor questions about the credit union contract or collaboration opportunities, please open an issue in the GitHub repository.\n\n---\n\n**Built with ❤️ for the cooperative economy**\n
