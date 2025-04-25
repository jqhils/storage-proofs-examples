// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {console} from "forge-std/console.sol";

import "./RLPReader.sol"; // RLP decoding library

contract BlockHeaderVerifier {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    // Event emitted when verification is successful
    event VerificationSuccess(bytes32 blockHash, bytes32 stateRoot);

    /**
     * @dev Verifies that the given RLP-encoded block header matches the provided block hash
     *      and contains the specified state root.
     * @param rlpHeader The RLP-encoded block header.
     * @param expectedBlockHash The hash of the block header that we expect.
     * @param expectedStateRoot The expected state root in the block header.
     * @return bool indicating whether the verification succeeded.
     */
    function verifyBlockHeader(
        bytes memory rlpHeader,
        bytes32 expectedBlockHash,
        bytes32 expectedStateRoot
    ) public view returns (bool) {
        // Compute the block header hash
        bytes32 actualBlockHash = keccak256(rlpHeader);
        if (actualBlockHash != expectedBlockHash) {
            // console.log("Block hash mismatch");
            return false; // Block hash does not match
        }

        // Decode the RLP-encoded header and extract the state root
        RLPReader.RLPItem[] memory items = rlpHeader.toRlpItem().toList();
        require(items.length > 3, "Invalid block header structure");

        // Extract the state root (typically the fourth item in Ethereum block headers)
        bytes32 actualStateRoot = bytes32(items[3].toBytes());
        if (actualStateRoot != expectedStateRoot) {
            return false; // State root does not match
        }

        // Emit success event
        // emit VerificationSuccess(actualBlockHash, actualStateRoot);
        return true;
    }
}
