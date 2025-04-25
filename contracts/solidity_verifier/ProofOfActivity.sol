// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {console} from "forge-std/console.sol";

import "./StateProofVerifier.sol";
import "./BlockHeaderVerifier.sol";
import "./HistoricBlockAxiomVerifier.sol";
import "./RLPReader.sol";

contract SolidityProofOfActivity {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    StateProofVerifier stateProofVerifier;
    BlockHeaderVerifier blockHeaderVerifier;
    HistoricBlockAxiomVerifier historicBlockAxiomVerifier;

    constructor(
        address _stateProofVerifier,
        address _blockHeaderVerifier,
        address _historicBlockAxiomVerifier
    ) {
        stateProofVerifier = StateProofVerifier(_stateProofVerifier);
        blockHeaderVerifier = BlockHeaderVerifier(_blockHeaderVerifier);
        historicBlockAxiomVerifier = HistoricBlockAxiomVerifier(
            _historicBlockAxiomVerifier
        );
    }

    function hasActivity(
        address eoa,
        uint32 startBlock,
        uint32 endBlock,
        bytes memory startBlockHeader,
        bytes memory endBlockHeader,
        bytes32 startBlockHash,
        bytes32 endBlockHash,
        bytes[] memory startAccountProof,
        bytes[] memory endAccountProof,
        IAxiomV2Verifier.BlockHashWitness calldata startBlockWitness,
        IAxiomV2Verifier.BlockHashWitness calldata endBlockWitness
    ) public view returns (bool isValid) {
        // Verify block headers
        verifyBlockHeader(startBlockHeader, startBlockHash, startBlockWitness);
        verifyBlockHeader(endBlockHeader, endBlockHash, endBlockWitness);

        // Verify account state at start block
        StateProofVerifier.AccountState memory startState = verifyAccountState(
            startBlockHeader,
            eoa,
            startAccountProof
        );

        // Verify account state at end block
        StateProofVerifier.AccountState memory endState = verifyAccountState(
            endBlockHeader,
            eoa,
            endAccountProof
        );

        // Check if nonce has increased
        // console.log("Start nonce: %d", startState.nonce);
        // console.log("End nonce: %d", endState.nonce);
        return endState.nonce > startState.nonce;
    }

    function verifyBlockHeader(
        bytes memory blockHeader,
        bytes32 blockHash,
        IAxiomV2Verifier.BlockHashWitness calldata blockWitness
    ) internal view {
        require(
            blockHeaderVerifier.verifyBlockHeader(
                blockHeader,
                blockHash,
                getStateRoot(blockHeader)
            ),
            "Block header verification failed"
        );
        require(
            historicBlockAxiomVerifier.testIsBlockHashValid(blockWitness),
            "Block hash verification failed"
        );
    }

    function verifyAccountState(
        bytes memory blockHeader,
        address eoa,
        bytes[] memory accountProof
    ) internal view returns (StateProofVerifier.AccountState memory) {
        (
            bool valid,
            StateProofVerifier.AccountState memory state
        ) = stateProofVerifier.verifyAccountState(
                getStateRoot(blockHeader),
                eoa,
                accountProof
            );
        require(valid, "Account state verification failed");
        return state;
    }

    function getStateRoot(
        bytes memory rlpHeader
    ) internal pure returns (bytes32) {
        RLPReader.RLPItem[] memory items = rlpHeader.toRlpItem().toList();
        require(items.length > 3, "Invalid block header structure");
        return bytes32(items[3].toBytes());
    }

    function test_hasActivity(
        address eoa,
        uint32 startBlock,
        uint32 endBlock,
        bytes memory startBlockHeader,
        bytes memory endBlockHeader,
        bytes32 startBlockHash,
        bytes32 endBlockHash,
        bytes[] memory startAccountProof,
        bytes[] memory endAccountProof,
        IAxiomV2Verifier.BlockHashWitness calldata startBlockWitness,
        IAxiomV2Verifier.BlockHashWitness calldata endBlockWitness
    ) public returns (bool isValid) {
        isValid = hasActivity(eoa, startBlock, endBlock, startBlockHeader, endBlockHeader, startBlockHash, endBlockHash, startAccountProof, endAccountProof, startBlockWitness, endBlockWitness);
        return isValid;
    }
}
