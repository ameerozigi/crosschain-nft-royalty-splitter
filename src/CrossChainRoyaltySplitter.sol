// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoyaltySplitter} from "./RoyaltySplitter.sol";

/// @title CrossChainRoyaltySplitter
/// @notice Extends RoyaltySplitter to support cross-chain recipients.
///         When a recipient's chain ID differs from Arbitrum, the royalty
///         share is queued as a CrossChainRoyalty struct for bridging.
contract CrossChainRoyaltySplitter is RoyaltySplitter {
    uint256 public constant ARBITRUM_CHAIN_ID = 42161;

    struct CrossChainRoyalty {
        address recipient;
        uint256 amount;
        uint256 targetChainId;
        uint256 nonce;
    }

    event CrossChainRoyaltyQueued(
        address indexed recipient,
        uint256 amount,
        uint256 targetChainId,
        uint256 nonce
    );

    uint256 public nextNonce;

    constructor(address _nftContract) RoyaltySplitter(_nftContract) {}

    /// @notice Override distributeRoyalty to detect cross-chain recipients.
    function distributeRoyalty(uint256 tokenId, address payer) external payable override nonReentrant {
        require(msg.value > 0, "zero payment");
        require(recipientCount() > 0, "no recipients");
        emit RoyaltyDistributed(tokenId, payer, msg.value);
        for (uint256 i = 0; i < recipientCount(); i++) {
            (address account, uint256 shareBips) = getRecipient(i);
            uint256 share = (msg.value * shareBips) / 10000;
            if (share == 0) continue;
            uint256 targetChainId = _resolveChainId(account);
            if (targetChainId == ARBITRUM_CHAIN_ID || targetChainId == block.chainid) {
                (bool ok, ) = account.call{value: share}("");
                require(ok, "transfer failed");
            } else {
                emit CrossChainRoyaltyQueued(account, share, targetChainId, nextNonce);
                nextNonce++;
            }
        }
    }

    function _recipientCount() internal view returns (uint256) {
        return recipientCount();
    }

    function _getRecipient(uint256 i) internal view returns (address, uint256) {
        return getRecipient(i);
    }

    function _resolveChainId(address) internal pure virtual returns (uint256) {
        return ARBITRUM_CHAIN_ID;
    }
}