// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

// import {HonkVerifier} from "../noir/target/prove_eoa_activity.sol";
import {UltraVerifier} from "../noir/target/prove_eoa_activity2_ultra_plonk.sol";

contract NoirProofOfEOAActivity2 {
    // HonkVerifier public verifier = new HonkVerifier();
    UltraVerifier public verifier = new UltraVerifier();
    bool public isVerified = false;
    function verify(
        bytes calldata proof,
        uint8[32] calldata y,
        bytes32 block_hash_1,
        bytes32 block_hash_2,
        address account_address
    ) external returns (bool) {
        bytes32 padded_account_address = bytes32(uint256(uint160(account_address)));
        bytes memory input = abi.encodePacked(block_hash_1, block_hash_2, padded_account_address);
        bytes32 computed_hash = keccak256(input);

        // Check that computed_hash matches circuit public input
        bytes32 y_as_bytes32 = convertToBytes32(y);
        require(y_as_bytes32 == computed_hash, "Hash mismatch");

        bytes32[] memory publicInputs = new bytes32[](32);
        for (uint i = 0; i < 32; i++) {
            publicInputs[i] = bytes32(uint256(y[i]));
        }
        bool result = verifier.verify(proof, publicInputs);
        isVerified = result;
        return result;
    }

    function convertToBytes32(uint8[32] calldata y_input) internal pure returns (bytes32) {
        bytes32 result = 0; // Initialize to zero
        for (uint i = 0; i < 32; i++) {
            result |= (bytes32(uint256(y_input[i])) << (8 * (31 - i)));
        }
        return result;
    }
}
