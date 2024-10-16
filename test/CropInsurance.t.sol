// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { CropInsurance } from "../src/CropInsurance.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract CropInsuranceTest is Test {
    // Actors
    address deployer = address(0x11);
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);
    MockERC20 usdc;

    CropInsurance public cropInsurance;

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        cropInsurance = new CropInsurance(address(usdc));
    }

    function test_PayPremium_Successful() public {
        _payPremiumAndAssert(alice);
    }

    function test_PayPremium_Failed() public {
        _payPremiumAndAssert(alice);
        vm.startPrank(alice);
        deal(address(usdc), alice, 100e6);
        usdc.approve(address(cropInsurance), 100e6);
        vm.expectRevert(CropInsurance.AlreadyPaid.selector);
        cropInsurance.payPremium();
    }

    function test_payout() public {
        _payPremiumAndAssert(alice);
        _payPremiumAndAssert(bob);

        uint256 amount = 10e6;
        uint256 expectedAmount = 10e6 * 9900 / 10000;
        cropInsurance.payout(amount);
        assertEq(usdc.balanceOf(alice), expectedAmount);
        assertEq(usdc.balanceOf(bob), expectedAmount);

        // Charlie should not get anything
        vm.expectRevert();
        cropInsurance.isInsured(charlie);
    }

    function _payPremiumAndAssert(address actor) internal {
        uint256 amount = 100e6;
        deal(address(usdc), actor, amount);
        assertEq(usdc.balanceOf(actor), amount);

        vm.startPrank(actor);
        usdc.approve(address(cropInsurance), amount);
        cropInsurance.payPremium();
        assertEq(cropInsurance.isInsured(actor), 1);
        vm.stopPrank();

        assertEq(usdc.balanceOf(actor), 0);
    }

    function test_setFee() public {
        assertEq(cropInsurance.feeBps(), 100);
        cropInsurance.setFee(200);
        assertEq(cropInsurance.feeBps(), 200);
    }
}
