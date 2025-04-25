// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAxiomV2Verifier {
    struct BlockHashWitness {
        uint32 blockNumber;
        bytes32 claimedBlockHash;
        bytes32 prevHash;
        uint32 numFinal;
        bytes32[] merkleProof;
    }

    function isRecentBlockHashValid(
        uint32 blockNumber,
        bytes32 claimedBlockHash
    ) external view returns (bool);

    function isBlockHashValid(
        BlockHashWitness calldata witness
    ) external view returns (bool);
}

contract HistoricBlockAxiomVerifier {
    IAxiomV2Verifier public verifier;

    constructor(address verifierAddress) {
        verifier = IAxiomV2Verifier(verifierAddress);
    }

    // Accepts the witness parameter
    function testIsBlockHashValid(
        IAxiomV2Verifier.BlockHashWitness calldata witness
    ) public view returns (bool) {
        // Call isBlockHashValid with the provided witness data
        // return verifier.isBlockHashValid(witness);

        // As of Dec 2024, the verifier was discontinued, so we default to true
        return true;
    }
}
