// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RoyaltySplitter} from "../src/RoyaltySplitter.sol";
import {CrossChainRoyaltySplitter} from "../src/CrossChainRoyaltySplitter.sol";
import {IERC2981} from "openzeppelin-contracts/interfaces/IERC2981.sol";

contract RoyaltySplitterTest is Test {
    RoyaltySplitter public splitter;
    CrossChainRoyaltySplitter public ccSplitter;

    address payable creator1 = payable(address(uint160(0x1111)));
    address payable creator2 = payable(address(uint160(0x2222)));
    address payer = address(uint160(0xAAAA));

    function setUp() public {
        splitter = new RoyaltySplitter(address(0));
        RoyaltySplitter.Recipient[] memory recips = new RoyaltySplitter.Recipient[](2);
        recips[0] = RoyaltySplitter.Recipient({account: creator1, shareBips: 7000});
        recips[1] = RoyaltySplitter.Recipient({account: creator2, shareBips: 3000});
        splitter.registerRecipients(recips);

        ccSplitter = new CrossChainRoyaltySplitter(address(0));
        RoyaltySplitter.Recipient[] memory ccRecips = new RoyaltySplitter.Recipient[](1);
        ccRecips[0] = RoyaltySplitter.Recipient({account: creator1, shareBips: 10000});
        ccSplitter.registerRecipients(ccRecips);
    }

    function test_RoyaltyInfo() public {
        (address receiver, uint256 amount) = splitter.royaltyInfo(1, 10000 ether);
        assertEq(receiver, address(splitter));
        assertEq(amount, 500 ether); // 5% of 10000
    }

    function test_DistributeRoyalty() public {
        vm.deal(payer, 100 ether);
        vm.prank(payer);
        splitter.distributeRoyalty{value: 100 ether}(1, payer);
        assertEq(creator1.balance, 70 ether);
        assertEq(creator2.balance, 30 ether);
    }

    function test_CrossChainRoyaltyQueued() public {
        CrossChainRoyaltySplitterWithChain cc = new CrossChainRoyaltySplitterWithChain(address(0));
        RoyaltySplitter.Recipient[] memory recips = new RoyaltySplitter.Recipient[](1);
        recips[0] = RoyaltySplitter.Recipient({account: creator1, shareBips: 10000});
        cc.registerRecipients(recips);
        vm.deal(payer, 100 ether);
        vm.prank(payer);
        cc.distributeRoyalty{value: 100 ether}(1, payer);
        assertEq(cc.nextNonce(), 1);
    }

    function test_RevertZeroPayment() public {
        vm.expectRevert("zero payment");
        splitter.distributeRoyalty{value: 0}(1, payer);
    }

    function test_SupportsInterface() public {
        assertTrue(splitter.supportsInterface(type(IERC2981).interfaceId));
    }
}

contract CrossChainRoyaltySplitterWithChain is CrossChainRoyaltySplitter {
    constructor(address _nftContract) CrossChainRoyaltySplitter(_nftContract) {}
    function _resolveChainId(address) internal pure override returns (uint256) { return 1; }
}