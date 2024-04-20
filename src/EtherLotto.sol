// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
The "EtherLotto" contract provides a decentralized lottery system using non-fungible tokens (NFTs).
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
*/

// OpenZeppelin ERC721 for managing NFTs and Ownable for access control
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Chainlink VRF interfaces and consumer base for secure and verifiable randomness
import "@chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract EtherLotto is ERC721Enumerable, Ownable, VRFConsumerBaseV2 {
    uint256 public immutable ticketPrice;
    uint256 public immutable feePct;
    uint256 public accumulatedPrize;
    uint256 public accumulatedFees;
    bool public isFinished;

    // Sepolia VRF coordinator
    VRFCoordinatorV2Interface coordinator;
    address constant vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 constant keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 constant callbackGasLimit = 2500000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords =  1;
    uint64 private subscriptionId;

    // Draw held event
    event DrawHeld(address winner);

    // Custom errors
    error DrawIsFinished();
    error IncorrectAmount();
    error InsufficientTicketsSold();
    error TransferFailed();

    /**
    Sets up the NFT token details and initializes Chainlink VRF
    @param _ticketPrice Price of a lottery ticket in wei
    @param _feePct Percentage of the ticket price collected as fees
    @param _subscriptionId Chainlink VRF subscription ID
    */
    constructor(
        uint256 _ticketPrice,
        uint256 _feePct,
        uint64 _subscriptionId
    ) ERC721("EtherLotto", "ELTKT") Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinator) {
        ticketPrice = _ticketPrice;
        feePct = _feePct;
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subscriptionId;
    }

    // Buy a ticket. The ticket price must match exactly. Each ticket purchase results in minting an NFT.
    function buyTicket() public payable {
        if (isFinished) revert DrawIsFinished();
        if (msg.value != ticketPrice) revert IncorrectAmount();

        uint256 fee = ticketPrice * feePct / 100;

        // Increment the prize pool and the fees separately
        accumulatedPrize += ticketPrice - fee;
        accumulatedFees += fee;

        // Mint a new NFT for the ticket
        uint256 newTokenId = totalSupply();
        _safeMint(msg.sender, newTokenId);
    }

    // Trigger a lottery draw. Requires at least two tickets.
    function draw() public onlyOwner returns(uint256) {
        if (isFinished) revert DrawIsFinished();
        if (totalSupply() <= 2) revert InsufficientTicketsSold();

        uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        return requestId;
    }

    // Handle the VRF response
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        // Determine the winner using the random number
        uint winnerIndex = _randomWords[0] % totalSupply();
        address winnerAddress = ownerOf(winnerIndex);

        // Reset the prize pool
        uint256 amount = accumulatedPrize;
        accumulatedPrize = 0;

        // Emit an event for the winner
        emit DrawHeld(winnerAddress);

        // Finish the draw
        isFinished = true;

        // Transfer the prize amount to the winner. If it fails, the draw fails
        (bool success, ) = winnerAddress.call{value:amount}("");
        if (!success) revert TransferFailed();
    }

    // Withdraw the accumulated fees by the owner
    function withdraw() public payable {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        (bool success, ) = owner().call{value:amount}("");
        if (!success) revert TransferFailed();
    }
}