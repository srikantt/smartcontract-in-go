// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../error.sol";

contract BankAPI {

    // Owner represents the address who deployed the contract.
    address public Owner;

    // API represents the address of the API contract.
    address public API;

    // accountBalances represents the amount of money an account has available.
    mapping (address => uint256) private accountBalances;

    // EventLog provides support for external logging.
    event EventLog(string value);

    // =========================================================================

    // constructor is called when the contract is deployed.
    constructor() {
        Owner = msg.sender;
    }

    // Reconcile settles the accounting for a game that was played.
    function Reconcile(address winner, address[] memory losers, uint256 anteWei, uint256 gameFeeWei) public {
        // Add the ante for each player to the pot. The initialization is
        // for the winner's ante.
        uint256 pot = anteWei;
        for (uint i = 0; i < losers.length; i++) {
            if (accountBalances[losers[i]] < anteWei) {
                emit EventLog(string.concat("account balance ", Error.Itoa(accountBalances[losers[i]]), " is less than ante ", Error.Itoa(anteWei)));
                pot += accountBalances[losers[i]];
                accountBalances[losers[i]] = 0;
            } else {
                pot += anteWei;
                accountBalances[losers[i]] -= anteWei;
            }
        }

        emit EventLog(string.concat("ante[", Error.Itoa(anteWei), "] gameFee[", Error.Itoa(gameFeeWei), "] pot[", Error.Itoa(pot), "]"));

        // This should not happen but check to see if the pot is 0 because none
        // of the losers had an account balance.
        if (pot == 0) {
            revert("no pot was created based on account balances");
        }

        // This should not happen but check there is enough in the pot to cover
        // the game fee.
        if (pot < gameFeeWei) {
            accountBalances[Owner] += pot;
            emit EventLog(string.concat("pot less than fee: winner[0] owner[", Error.Itoa(pot), "]"));
            return;
        }

        // Take the game fee from the pot and give the winner the remaining pot
        // and the owner the game fee.
        pot -= gameFeeWei;
        accountBalances[winner] += pot;
        accountBalances[Owner] += gameFeeWei;
        emit EventLog(string.concat("winner[", Error.Itoa(pot), "] owner[", Error.Itoa(gameFeeWei), "]"));
    }
}
