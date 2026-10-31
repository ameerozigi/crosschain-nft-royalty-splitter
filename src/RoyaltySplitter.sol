// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC2981} from "openzeppelin-contracts/interfaces/IERC2981.sol";
import {IERC165} from "openzeppelin-contracts/utils/introspection/IERC165.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";

/// @title RoyaltySplitter
/// @notice ERC-2981 compatible royalty splitter. Splits NFT sale proceeds
///         among multiple recipients by percentage (basis points).
contract RoyaltySplitter is IERC2981, Ownable, ReentrancyGuard {
    struct Recipient {
        address payable account;
        uint256 shareBips;
    }

    event RoyaltyDistributed(uint256 indexed tokenId, address indexed payer, uint256 amount);
    event RecipientRegistered(address indexed recipient, uint256 shareBips);

    uint256 public constant MAX_RECIPIENTS = 10;
    uint256 public constant ROYALTY_BIPS = 500; // 5% default royalty
    address public immutable nftContract;

    Recipient[] private _recipients;
    uint256 private _totalShareBips;

    constructor(address _nftContract) Ownable(msg.sender) {
        nftContract = _nftContract;
    }

    function registerRecipients(Recipient[] memory newRecipients) external onlyOwner {
        require(newRecipients.length > 0 && newRecipients.length <= MAX_RECIPIENTS, "invalid count");
        uint256 sum;
        for (uint256 i = 0; i < newRecipients.length; i++) {
            require(newRecipients[i].account != address(0), "zero addr");
            require(newRecipients[i].shareBips > 0, "zero share");
            sum += newRecipients[i].shareBips;
        }
        require(sum == 10000, "shares must sum to 100%");
        for (uint256 i = 0; i < newRecipients.length; i++) {
            _recipients.push(newRecipients[i]);
            emit RecipientRegistered(newRecipients[i].account, newRecipients[i].shareBips);
        }
        _totalShareBips = sum;
    }

    function recipientCount() public view returns (uint256) { return _recipients.length; }
    function getRecipient(uint256 index) public view returns (address payable, uint256) {
        return (_recipients[index].account, _recipients[index].shareBips);
    }

    /// @notice ERC-2981 royalty info — returns (receiver, royaltyAmount) for a given sale price.
    function royaltyInfo(uint256 /*tokenId*/, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (address(this), (salePrice * ROYALTY_BIPS) / 10000);
    }

    /// @notice Distribute sale proceeds to all recipients by share.
    function distributeRoyalty(uint256 tokenId, address payer) external payable virtual nonReentrant {
        require(msg.value > 0, "zero payment");
        require(_recipients.length > 0, "no recipients");
        emit RoyaltyDistributed(tokenId, payer, msg.value);
        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 share = (msg.value * _recipients[i].shareBips) / _totalShareBips;
            if (share > 0) {
                (bool ok, ) = _recipients[i].account.call{value: share}("");
                require(ok, "transfer failed");
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}