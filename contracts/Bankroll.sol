// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Bankroll {
    mapping(address => bool) isGame;
    mapping(address => bool) isTokenAllowed;
    address[] allowedTokens;
    address wrappedToken;
    mapping(address => uint256) suspendedTime;
    mapping(address => bool) _isPlayerSuspended;

    function getIsValidWager(
        address game,
        address tokenAddress
    ) external view returns (bool) {
        return isGame[game] && isTokenAllowed[tokenAddress];
    }

    function isPlayerSuspended(
        address player
    ) external view returns (bool, uint256) {
        return (_isPlayerSuspended[player], suspendedTime[player]);
    }
}
