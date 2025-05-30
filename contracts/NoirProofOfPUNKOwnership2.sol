// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

// import {HonkVerifier} from "../noir/target/prove_hist_punk_ownership.sol";
import {UltraVerifier} from "../noir/target/prove_hist_punk_ownership2_ultra_plonk.sol";

contract NoirProofOfPUNKOwnership2 {
    // HonkVerifier public verifier = new HonkVerifier();
    UltraVerifier public verifier = new UltraVerifier();
    bool public isVerified = false;
    function verify(
        bytes calldata proof,
        uint8[32] calldata y,
        bytes32 block_hash,
        address nft_address,
        address owner_address,
        bytes32 pub_hash_field
    ) external returns (bool) {

        // // Verify pub_hash
        // for (uint i = 0; i < 32; i++) {
        //     if (y[i] != uint8(block_hash[i])) {
        //         revert("First 32 bytes of y[0:32] do not match block_hash");
        //     }
        // }
        // // Verify nft_address
        // for (uint i = 0; i < 20; i++) {
        //     if (y[32+12+i] != uint8(nft_addr_as_bytes20[i])) {
        //         revert("Last 20 bytes of y[32+12:] do not match nft_address");
        //     }
        // }
        // // Verify owner_address
        // for (uint i = 0; i < 20; i++) {
        //     if (y[64+12+i] != uint8(owner_addr_as_bytes20[i])) {
        //         revert("Last 20 bytes of y[64+12:] do not match owner_address");
        //     }
        // }
        
        bytes32 padded_nft = bytes32(uint256(uint160(nft_address)));
        bytes32 padded_owner = bytes32(uint256(uint160(owner_address)));

        bytes memory input = abi.encodePacked(block_hash, padded_nft, padded_owner);
        bytes32 computed_hash = keccak256(input);
        // Check that computed_hash matches pub_hash_field
        require(computed_hash == pub_hash_field, "Hash mismatch");

        bytes32[] memory publicInputs = new bytes32[](32);
        for (uint i = 0; i < 32; i++) {
            publicInputs[i] = bytes32(uint256(y[i]));
        }

        // publicInputs[32] = bytes32(pub_hash_field);
        bool result = verifier.verify(proof, publicInputs);
        isVerified = result;
        return result;
    }
}

