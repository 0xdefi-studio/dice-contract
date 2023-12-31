// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

interface IRandomizer {
    function request(
        uint256 _callbackGasLimit,
        uint256 _confirmations
    ) external returns (uint256);

    function clientWithdrawTo(address _to, uint256 _amount) external;

    function estimateFee(
        uint256 _callbackGasLimit,
        uint256 _confirmations
    ) external view returns (uint256);

    function clientDeposit(address _client) external payable;

    function getFeeStats(
        uint256 _request
    ) external view returns (uint256[2] memory);
}

interface IBankRoll {
    function getIsGame(address game) external view returns (bool);

    function getIsValidWager(
        address game,
        address tokenAddress
    ) external view returns (bool);

    function transferPayout(
        address player,
        uint256 payout,
        address token
    ) external;

    function getOwner() external view returns (address);

    function isPlayerSuspended(
        address player
    ) external view returns (bool, uint256);
}

contract Common is ReentrancyGuard {
    IBankRoll public Bankroll;
    address public randomizer;
    uint256 VRFgasLimit;

    using SafeERC20 for IERC20;

    error NotApprovedBankroll();
    error InvalidValue(uint256 sent, uint256 required);
    error TransferFailed();
    error RefundFailed();
    error NotOwner(address want, address have);
    error ZeroWager();
    error PlayerSuspended(uint256 suspensionTime);

    function _changeRandomizer(address _randomizer) internal {
        randomizer = _randomizer;
    }

    function _transferWager(
        address tokenAddress,
        uint256 wager,
        uint256 vrfFee
    ) internal returns (uint256 VRFfee) {
        if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
            revert NotApprovedBankroll();
        }
        if (wager == 0) {
            revert ZeroWager();
        }
        (bool suspended, uint256 suspendedTime) = Bankroll.isPlayerSuspended(
            msg.sender
        );
        if (suspended) {
            revert PlayerSuspended(suspendedTime);
        }
        if (tokenAddress == address(0)) {
            if (msg.value < wager + vrfFee) {
                revert InvalidValue(msg.value, wager + vrfFee);
            }

            (bool sent, bytes memory data) = payable(randomizer).call{
                value: vrfFee
            }("");
            require(sent, "Failed to fund back randomizer");

            _refundExcessValue(msg.value - (vrfFee + wager));
        } else {
            if (msg.value < vrfFee) {
                revert InvalidValue(VRFfee, msg.value);
            }
            (bool sent, bytes memory data) = payable(randomizer).call{
                value: vrfFee
            }("");
            require(sent, "Failed to fund back randomizer");
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                wager
            );
            _refundExcessValue(msg.value - vrfFee);
        }
    }

    /**
     * @dev function to transfer the wager held by the game contract to the bankroll
     * @param tokenAddress address of the token to transfer
     * @param amount token amount to transfer
     */
    function _transferToBankroll(
        address tokenAddress,
        uint256 amount
    ) internal {
        if (tokenAddress == address(0)) {
            (bool success, ) = payable(address(Bankroll)).call{value: amount}(
                ""
            );
            if (!success) {
                revert RefundFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(address(Bankroll), amount);
        }
    }

    /**
     * @dev calculates in form of native token the fee charged by  VRF
     * @return fee amount of fee user has to pay
     */
    function getVRFFee() public view returns (uint256 fee) {
        fee = (IRandomizer(randomizer).estimateFee(2500000, 4) * 125) / 100;
    }

    /**
     * @dev returns to user the excess fee sent to pay for the VRF
     * @param refund amount to send back to user
     */
    function _refundExcessValue(uint256 refund) internal {
        if (refund == 0) {
            return;
        }
        console.log("refund: ", refund);
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        if (!success) {
            revert RefundFailed();
        }
    }

    /**
     * @dev function to charge user for VRF
     */
    function _payVRFFee() internal returns (uint256 VRFfee) {
        VRFfee = getVRFFee();
        if (msg.value < VRFfee) {
            revert InvalidValue(VRFfee, msg.value);
        }
        IRandomizer(randomizer).clientDeposit{value: VRFfee}(address(this));
        _refundExcessValue(msg.value - VRFfee);
    }

    function _transferWagerNoVRF(
        address tokenAddress,
        uint256 wager,
        uint32 numBets
    ) internal {
        require(Bankroll.getIsGame(address(this)), "not valid");
        require(numBets > 0 && numBets < 500, "invalid bet number");
        if (tokenAddress == address(0)) {
            require(msg.value == wager * numBets, "incorrect value");

            (bool success, ) = payable(address(Bankroll)).call{
                value: msg.value
            }("");
            require(success, "eth transfer failed");
        } else {
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(Bankroll),
                wager * numBets
            );
        }
    }

    /**
     * @dev function to transfer wager to game contract, without charging for VRF
     * @param tokenAddress tokenAddress the wager is made on
     * @param wager wager amount
     */
    function _transferWagerPvPNoVRF(
        address tokenAddress,
        uint256 wager
    ) internal {
        if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
            revert NotApprovedBankroll();
        }
        if (tokenAddress == address(0)) {
            if (!(msg.value == wager)) {
                revert InvalidValue(wager, msg.value);
            }
        } else {
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                wager
            );
        }
    }

    /**
     * @dev function to transfer wager to game contract, including charge for VRF
     * @param tokenAddress tokenAddress the wager is made on
     * @param wager wager amount
     */
    function _transferWagerPvP(address tokenAddress, uint256 wager) internal {
        if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
            revert NotApprovedBankroll();
        }

        uint256 VRFfee = getVRFFee();
        if (tokenAddress == address(0)) {
            if (msg.value < wager + VRFfee) {
                revert InvalidValue(msg.value, wager);
            }

            _refundExcessValue(msg.value - (VRFfee + wager));
        } else {
            if (msg.value < VRFfee) {
                revert InvalidValue(VRFfee, msg.value);
            }

            IERC20(tokenAddress).transferFrom(msg.sender, address(this), wager);
            _refundExcessValue(msg.value - VRFfee);
        }
    }

    /**
     * @dev transfers payout from the game contract to the players
     * @param player address of the player to transfer the payout to
     * @param payout amount of payout to transfer
     * @param tokenAddress address of the token that payout will be transfered
     */
    function _transferPayoutPvP(
        address player,
        uint256 payout,
        address tokenAddress
    ) internal {
        if (tokenAddress == address(0)) {
            (bool success, ) = payable(player).call{value: payout}("");
            if (!success) {
                revert TransferFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(player, payout);
        }
    }

    /**
     * @dev transfers house edge from game contract to bankroll
     * @param amount amount to transfer
     * @param tokenAddress address of token to transfer
     */
    function _transferHouseEdgePvP(
        uint256 amount,
        address tokenAddress
    ) internal {
        if (tokenAddress == address(0)) {
            (bool success, ) = payable(address(Bankroll)).call{value: amount}(
                ""
            );
            if (!success) {
                revert TransferFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(address(Bankroll), amount);
        }
    }

    /**@dev function to alter gaslimit of vrf request
     * @param limit new gas Limit on request
     */
    function setVRFGasLimit(uint256 limit) external {
        if (msg.sender != Bankroll.getOwner()) {
            revert NotOwner(Bankroll.getOwner(), msg.sender);
        }
        VRFgasLimit = limit;
    }

    /**
     * @dev function to request bankroll to give payout to player
     * @param player address of the player
     * @param payout amount of payout to give
     * @param tokenAddress address of the token in which to give the payout
     */
    function _transferPayout(
        address player,
        uint256 payout,
        address tokenAddress
    ) internal {
        Bankroll.transferPayout(player, payout, tokenAddress);
    }

    function _requestRandomWords(
        uint32 numWords
    ) internal returns (uint256 s_requestId) {
        s_requestId = IRandomizer(randomizer).request(VRFgasLimit, 4);
        return s_requestId;
    }

    function whithdrawVRF(address to, uint256 amount) external {
        if (msg.sender != Bankroll.getOwner()) {
            revert NotOwner(Bankroll.getOwner(), msg.sender);
        }
        IRandomizer(randomizer).clientWithdrawTo(to, amount);
    }
}
