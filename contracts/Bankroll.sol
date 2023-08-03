// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Bankroll is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) isGame;
    mapping(address => bool) isTokenAllowed;
    address[] allowedTokens;
    address wrappedToken;
    mapping(address => uint256) suspendedTime;
    mapping(address => bool) _isPlayerSuspended;

    /**
     * @dev event emitted when game is Added or Removed
     * @param gameAddress address of game state that changed
     * @param isValid new state of game address
     */
    event BankRoll_Game_State_Changed(address gameAddress, bool isValid);

    /**
     * @dev event emitted when token state is changed
     * @param tokenAddress address of token that changed state
     * @param isValid new state of token address
     */
    event Bankroll_Token_State_Changed(address tokenAddress, bool isValid);
    error InvalidGameAddress();
    error TransferFailed();

    /**
     * @dev remove funds from the bankroll
     */
    function withdrawFunds(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(to, amount);
    }

    /**
     * @dev remove funds from the bankroll
     */
    function withdrawNativeFunds(
        address to,
        uint256 amount
    ) external onlyOwner {
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @dev Function to enable or disable games to distribute bankroll payouts
     * @param game contract address of game to change state
     * @param isValid state to set the address to
     */
    function setGame(address game, bool isValid) external onlyOwner {
        isGame[game] = isValid;
        emit BankRoll_Game_State_Changed(game, isValid);
    }

    /**
     * @dev function to get if game is allowed to access the bankroll
     * @param game address of the game contract
     */
    function getIsGame(address game) external view returns (bool) {
        return isGame[game];
    }

    /**
     * @dev function to set if a given token can be wagered
     * @param tokenAddress address of the token to set address
     * @param isValid state to set the address to
     */
    function setTokenAddress(
        address tokenAddress,
        bool isValid
    ) external onlyOwner {
        isTokenAllowed[tokenAddress] = isValid;
        emit Bankroll_Token_State_Changed(tokenAddress, isValid);
    }

    /**
     * @dev function to set the wrapped token contract of the native asset
     * @param wrapped address of the wrapped token contract
     */
    function setWrappedAddress(address wrapped) external onlyOwner {
        wrappedToken = wrapped;
    }

    function getWrappedAddress() external view returns (address) {
        return wrappedToken;
    }

    /**
     * @dev function that games call to transfer payout
     * @param player address of the player to transfer payout to
     * @param payout amount of payout to transfer
     * @param tokenAddress address of the token to transfer, 0 address is the native token
     */
    function transferPayout(
        address player,
        uint256 payout,
        address tokenAddress
    ) external {
        if (!isGame[msg.sender]) {
            revert InvalidGameAddress();
        }
        if (tokenAddress != address(0)) {
            IERC20(tokenAddress).safeTransfer(player, payout);
        } else {
            (bool success, ) = payable(player).call{value: payout, gas: 2400}(
                ""
            );
            if (!success) {
                (bool _success, ) = wrappedToken.call{value: payout}(
                    abi.encodeWithSignature("deposit()")
                );
                if (!_success) {
                    revert();
                }
                IERC20(wrappedToken).safeTransfer(player, payout);
            }
        }
    }

    /**
     * @dev function to check if payout can be given
     * @param game address of the game contract
     * @param tokenAddress address of the token the wager is made
     */
    function getIsValidWager(
        address game,
        address tokenAddress
    ) external view returns (bool) {
        return isGame[game] && isTokenAllowed[tokenAddress];
    }

    /**
     * @dev Function to view player suspension status.
     * @param player Address of the
     * @return bool is player suspended
     * @return uint256 time that unlock period ends
     */
    function isPlayerSuspended(
        address player
    ) external view returns (bool, uint256) {
        return (_isPlayerSuspended[player], suspendedTime[player]);
    }
}
