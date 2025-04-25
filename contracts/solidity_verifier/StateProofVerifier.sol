// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RLPReader.sol";
import "./MPTVerifier.sol";

/**
 * @title StateProofVerifier
 * @dev Verifies an account's state in the Ethereum state trie using a Merkle Patricia Trie proof.
 */
contract StateProofVerifier {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    /**
     * @dev Verifies an account's state in the Ethereum state trie.
     * @param stateRoot The state root hash of the block.
     * @param account The address of the account to verify.
     * @param accountProof The Merkle proof for the account in the state trie.
     * @return isValid True if the proof is valid, false otherwise.
     * @return accountState The account's state (nonce, balance, storage root, code hash).
     */
    function verifyAccountState(
        bytes32 stateRoot,
        address account,
        bytes[] memory accountProof
    ) public pure returns (bool isValid, AccountState memory accountState) {
        // Step 1: Verify the account exists in the state trie
        bytes memory encodedAccount = MPTVerifier.verifyAccountInStateTrie(
            stateRoot,
            account,
            accountProof
        );
        if (encodedAccount.length == 0) {
            return (false, accountState);
        }

        // Step 2: Decode the account details
        RLPReader.RLPItem[] memory accountFields = encodedAccount
            .toRlpItem()
            .toList();
        if (accountFields.length != 4) {
            return (false, accountState);
        }

        accountState = AccountState({
            nonce: accountFields[0].toUint(),
            balance: accountFields[1].toUint(),
            storageRoot: bytes32(accountFields[2].toBytes()),
            codeHash: bytes32(accountFields[3].toBytes())
        });

        isValid = true;
    }

    function test_verifyAccountState(
        bytes32 stateRoot,
        address account,
        bytes[] memory accountProof
    ) public returns (bool isValid) {
        (isValid, ) = verifyAccountState(stateRoot, account, accountProof);
        return isValid;
    }

    /**
     * @dev AccountState structure to hold decoded account fields.
     */
    struct AccountState {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }
}
