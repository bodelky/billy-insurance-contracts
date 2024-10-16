pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT

import "@openzeppelin/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
// import { EnumerableSet } from "@openzeppelin/utils/struct/EnumerableSet.sol";
import { EnumerableMap } from "@openzeppelin/utils/structs/EnumerableMap.sol";

contract CropInsurance is Ownable {
    using SafeERC20 for IERC20;
    // using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    // Error
    error AlreadyPaid();
    error InvalidAmount();
    error InsufficientBalance();
    error InvalidFee();
    error SetFailed();

    // Event
    event LogDeposit(address depositor, address token, uint256 amount);
    event LogWithdraw(address withdrawer, address token, uint256 amount);
    event LogSetUSD(address usdc);
    event LogDeducted(address user, address token, uint256 amount);

    // State
    // Set uint to 0, 1
    EnumerableMap.AddressToUintMap private insuredUsers;
    address public usdcAddress;

    // Constant
    uint256 public premiumPrice = 100 * 1e6; // Assuming 100 USDC premium (in 6 decimal places)
    uint256 public MAX_BPS = 10000;
    uint256 public feeBps = 100; // 1%

    constructor(address _usdcAddress) Ownable(msg.sender) {
        usdcAddress = _usdcAddress;
    }

    function payPremium() external {
        // Transfer USDC from user to this contract
        IERC20(usdcAddress).safeTransferFrom(msg.sender, address(this), premiumPrice);

        // Mark the user as insured
        bool isSucess = insuredUsers.set(msg.sender, 1);
        if (!isSucess) {
            revert AlreadyPaid();
        }
    }

    function payout(uint256 payoutAmount) external onlyOwner {
        uint256 len = insuredUsers.length();

        uint256 fee = payoutAmount * feeBps / MAX_BPS;
        uint256 actualPayoutAmount = payoutAmount - fee;

        for (uint256 i = 0; i < len; i++) {
            (address _user, uint256 _value) = insuredUsers.at(i);

            // Payout, if insured (1). Else will skip
            if (_value == 1) {
                IERC20(usdcAddress).safeTransfer(_user, actualPayoutAmount);
            }
        }
    }

    // Function to check if a wallet is insured (0 = not insure yet, 1 = insured)
    function isInsured(address user) external view returns (uint256) {
        return insuredUsers.get(user);
    }

    function setFee(uint256 _feeBps) external onlyOwner {
        if (_feeBps > 10000) {
            revert InvalidFee();
        }
        feeBps = _feeBps;
    }
}
