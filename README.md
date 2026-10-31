# Cross-Chain NFT Royalty Splitter

A Foundry project implementing **ERC-2981** compatible NFT royalty splitting. Sale proceeds are automatically distributed among multiple creators by percentage, with optional **cross-chain** royalty distribution.

Deployed on **Arbitrum** (chain ID `42161`).

## Architecture

```
NFT Sale (marketplace) ──royaltyInfo()──► RoyaltySplitter (IERC2981)
                                              │
                                              │ distributeRoyalty(tokenId, payer)
                                              ▼
                                    ┌─────────────────────┐
                                    │  Split by shareBips  │
                                    │  (sums to 100%)      │
                                    └──────────┬──────────┘
                                               │
                          ┌────────────────────┼────────────────────┐
                          ▼                    ▼                    ▼
                    Creator A (70%)      Creator B (30%)       Cross-Chain Creator
                                                  │
                                                  ▼
                                    CrossChainRoyaltyQueued event
                                                  │
                                                  ▼
                                    ┌─────────────────────────┐
                                    │   REAL BRIDGE PLUG-IN   │
                                    │   Wormhole / LayerZero   │
                                    └─────────────────────────┘
```

## Contracts

| File | Purpose |
|------|---------|
| `src/RoyaltySplitter.sol` | ERC-2981 compatible royalty splitter. Splits sale proceeds among up to 10 recipients by basis-point share. |
| `src/CrossChainRoyaltySplitter.sol` | Extends `RoyaltySplitter` to support cross-chain recipients. Queues cross-chain royalties as `CrossChainRoyalty` structs. |
| `test/RoyaltySplitter.t.sol` | Foundry tests covering royalty info, distribution, cross-chain queuing, and interface support. |
| `scripts/deploy.ts` | TypeScript (ethers.js) deploy script. |

## Real-world use cases

- **Collaborative NFT collections** — split royalties across multiple artists
- **Music NFT platforms** — distribute streaming royalties to producers, vocalists, and labels
- **Gaming assets** — split in-game item sale proceeds among item creators
- **DAO treasury** — distribute NFT sale proceeds to contributors across chains

## Setup

```bash
forge build
forge test
```

## Deployment

```bash
forge script scripts/deploy.ts --broadcast
```