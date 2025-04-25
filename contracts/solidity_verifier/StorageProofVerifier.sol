// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {console} from "forge-std/console.sol";

import "./RLPReader.sol";
import "./MPTVerifier.sol";

contract StorageProofVerifier {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    /**
     * @dev Verifies a storage proof for a given account and storage slot.
     * @param stateRoot The state root hash of the block.
     * @param account The address of the account.
     * @param storageSlot The storage slot (key) being proven.
     * @param accountProof The Merkle proof for the account in the state trie.
     * @param storageProof The Merkle proof for the storage slot in the account's storage trie.
     * @return isValid True if the proof is valid, false otherwise.
     * @return value The value stored at the given storage slot.
     */
    function verifyStorageProof(
        bytes32 stateRoot,
        address account,
        bytes32 storageSlot,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) public pure returns (bool isValid, bytes memory value) {
        // Step 1: Verify the account exists in the state trie
        bytes memory encodedAccount = MPTVerifier.verifyAccountInStateTrie(
            stateRoot,
            account,
            accountProof
        );
        if (encodedAccount.length == 0) {
            return (false, "");
        }

        // Step 2: Decode the account to get the storage root
        RLPReader.RLPItem[] memory accountFields = encodedAccount
            .toRlpItem()
            .toList();
        if (accountFields.length != 4) {
            return (false, "");
        }

        // Parse account fields correctly
        // uint256 nonce = accountFields[0].toUint();
        // uint256 balance = accountFields[1].toUint();
        bytes32 storageRoot = bytes32(accountFields[2].toBytes());
        // bytes32 codeHash = bytes32(accountFields[3].toBytes());

        // console.log("Storage root:");
        // console.logBytes32(storageRoot);

        // Step 3: Verify the storage slot in the account's storage trie
        bytes memory encodedValue = MPTVerifier.verifyStorageInStorageTrie(
            storageRoot,
            storageSlot,
            storageProof
        );
        if (encodedValue.length == 0) {
            return (false, "");
        }

        // Step 4: Decode the value
        value = encodedValue.toRlpItem().toBytes();
        isValid = true;
    }

    function test_verifyStorageProof(
        bytes32 stateRoot,
        address account,
        bytes32 storageSlot,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) public returns (bool isValid) {
        (isValid, ) = verifyStorageProof(stateRoot, account, storageSlot, accountProof, storageProof);
        return isValid;
    }
}
