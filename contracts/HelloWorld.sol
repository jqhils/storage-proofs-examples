// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

// import {HonkVerifier} from "../noir/target/hello_world.sol";
import {UltraVerifier} from "../noir/target/hello_world_ultra_plonk.sol";

contract HelloWorld {
    // HonkVerifier public verifier = new HonkVerifier();
    UltraVerifier public verifier = new UltraVerifier();
    bool public isVerified = false;

    // Original Code
    // function verify(
    //     bytes calldata proof,
    //     uint256 y
    // ) external view returns (bool) {
    //     bytes32[] memory publicInputs = new bytes32[](1);
    //     publicInputs[0] = bytes32(y);
    //     bool result = verifier.verify(proof, publicInputs);
    //     return result;
    // }

    // New Code removes the `view` modifier
    function verify(
        bytes calldata proof,
        uint256 y
    ) external returns (bool) {
        bytes32[] memory publicInputs = new bytes32[](1);
        publicInputs[0] = bytes32(y);
        bool result = verifier.verify(proof, publicInputs);
        isVerified = result;
        return result;
    }
}
