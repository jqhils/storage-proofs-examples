// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

// import {HonkVerifier} from "../noir/target/prove_eoa_activity.sol";
import {UltraVerifier} from "../noir/target/prove_eoa_activity_ultra_plonk.sol";

contract NoirProofOfEOAActivity {
    // HonkVerifier public verifier = new HonkVerifier();
    UltraVerifier public verifier = new UltraVerifier();
    bool public isVerified = false;
    function verify(
        bytes calldata proof,
        uint256 y
    ) external returns (bool) {
        bytes32[] memory publicInputs = new bytes32[](0);
        // publicInputs[0] = bytes32(y);
        bool result = verifier.verify(proof, publicInputs);
        isVerified = result;
        return result;
    }
}
