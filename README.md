## EtherLotto

This contract provides a decentralized lottery system using non-fungible tokens (NFTs) and Verifiable Random Functions, on the Sepolia test blockchain.

Each ticket purchase results in the minting of a unique NFT, and the ticket price contributes to a cumulative prize pool.

Key features of this contract include:
- Ticket Purchase: Users can buy lottery tickets by sending the exact ticket price to the contract. Each purchase mints an NFT, which acts as the lottery ticket.
- Prize Accumulation: A portion of each ticket sale contributes to the prize pool, while another portion is collected as fees for the maintenance and operation of the lottery.
- Chainlink VRF Integration: The contract integrates Chainlink's Verifiable Random Function (VRF) to ensure fair and transparent random number generation. This randomness is used to select a winner from among the NFT holders when a lottery draw is conducted.
- Draw Mechanism: Only the owner of the contract can initiate a draw, which requires at least three tickets to have been sold. This restriction ensures that there is a minimal level of participation for each draw.
- Prize Distribution: When a draw occurs, the Chainlink VRF function selects a random winner based on the generated random number. The accumulated prize pool is then transferred to the winner's address.
- Fee Withdrawal: The contract owner can withdraw the accumulated fees, which are collected from ticket sales.
- Security Features: The contract implements several security measures, including reversion on incorrect Ether transfers and safeguarding against insufficient ticket sales and transfer failures.
This contract not only offers a transparent and fair mechanism for lottery but also leverages the security and reliability of Ethereum's smart contracts and Chainlink's decentralized oracle network, bringing a high degree of trust and automation to the process.


This is just a practice, do not use in production.

### How to install

```bash
forge install
forge build
```

### ToDo

- Foundry Tests
- Support other networks