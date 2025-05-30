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
        uint8[96] calldata y,
        bytes32 block_hash,
        address nft_address,
        address owner_address
    ) external returns (bool) {
        bytes20 nft_addr_as_bytes20 = bytes20(nft_address);
        bytes20 owner_addr_as_bytes20 = bytes20(owner_address);

        // Verify block_hash
        for (uint i = 0; i < 32; i++) {
            if (y[i] != uint8(block_hash[i])) {
                revert("First 32 bytes of y[0:32] do not match block_hash");
            }
        }
        // Verify nft_address
        for (uint i = 0; i < 20; i++) {
            if (y[32+12+i] != uint8(nft_addr_as_bytes20[i])) {
                revert("Last 20 bytes of y[32+12:] do not match nft_address");
            }
        }
        // Verify owner_address
        for (uint i = 0; i < 20; i++) {
            if (y[64+12+i] != uint8(owner_addr_as_bytes20[i])) {
                revert("Last 20 bytes of y[64+12:] do not match owner_address");
            }
        }
        
        bytes32[] memory publicInputs = new bytes32[](96);
        for (uint i = 0; i < 96; i++) {
            publicInputs[i] = bytes32(uint256(y[i]));
        }
        // publicInputs[0] = bytes32(y);
        bool result = verifier.verify(proof, publicInputs);
        isVerified = result;
        return result;
    }
}
