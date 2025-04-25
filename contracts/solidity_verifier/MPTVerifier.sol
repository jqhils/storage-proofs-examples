// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RLPReader.sol";

// MPTVerifier library for verifying Merkle Patricia Trie proofs
library MPTVerifier {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.RLPItem[];

    function verifyAccountInStateTrie(
        bytes32 stateRoot,
        address account,
        bytes[] memory accountProof
    ) internal pure returns (bytes memory) {
        bytes memory accountRlp = executeProof(
            stateRoot,
            keccak256(abi.encodePacked(account)),
            accountProof
        );
        return accountRlp;
    }

    function verifyStorageInStorageTrie(
        bytes32 storageRoot,
        bytes32 slotKey,
        bytes[] memory storageProof
    ) internal pure returns (bytes memory) {
        bytes memory valueRlp = executeProof(
            storageRoot,
            keccak256(abi.encodePacked(slotKey)),
            storageProof
        );
        return valueRlp;
    }

    function executeProof(
        bytes32 rootHash,
        bytes32 path,
        bytes[] memory proof
    ) internal pure returns (bytes memory) {
        bytes memory currentNode;
        bytes32 nodeHash = rootHash;
        uint256 pathPtr = 0;
        bytes memory pathNibble = toNibbles(path);

        // console.log("Proof length:", proof.length);
        for (uint256 i = 0; i < proof.length; i++) {
            if (nodeHash != keccak256(proof[i])) {
                return "";
            }
            currentNode = proof[i];
            RLPReader.RLPItem[] memory nodeList = currentNode
                .toRlpItem()
                .toList();

            if (nodeList.length == 17) {
                // Branch node
                if (pathPtr == pathNibble.length) {
                    // Value node
                    return nodeList[16].toBytes();
                }
                uint8 nibble = uint8(pathNibble[pathPtr]);
                if (nodeList[nibble].len == 0) {
                    return "";
                }
                nodeHash = bytes32(nodeList[nibble].toUint());
                pathPtr += 1;
            } else if (nodeList.length == 2) {
                // Leaf or extension node
                bytes memory nodePathBytes = nodeList[0].toBytes();
                uint8 firstByte = uint8(nodePathBytes[0]);

                // Extract flags from the first nibble
                uint8 firstNibble = firstByte >> 4;

                bool isLeaf = (firstNibble & 0x2) != 0;
                bool isOddLength = (firstNibble & 0x1) != 0;

                bytes memory path;
                // uint256 pathOffset = 0;

                if (isOddLength) {
                    // Path length is odd, the second nibble of the first byte is part of the path
                    uint8 secondNibble = firstByte & 0x0F;
                    path = new bytes((nodePathBytes.length - 1) * 2 + 1);
                    path[0] = bytes1(secondNibble);

                    for (uint256 j = 1; j < path.length; j++) {
                        uint8 byteVal = uint8(nodePathBytes[(j + 1) / 2]);
                        if (j % 2 == 1) {
                            path[j] = bytes1(byteVal >> 4);
                        } else {
                            path[j] = bytes1(byteVal & 0x0F);
                        }
                    }
                } else {
                    // Path length is even, the path starts from the second byte
                    path = new bytes((nodePathBytes.length - 1) * 2);
                    for (uint256 k = 0; k < path.length; k++) {
                        uint8 byteVal = uint8(nodePathBytes[(k / 2) + 1]);
                        if (k % 2 == 0) {
                            path[k] = bytes1(byteVal >> 4);
                        } else {
                            path[k] = bytes1(byteVal & 0x0F);
                        }
                    }
                }

                // We need to compare the path starting from pathPtr with the node's path
                // Since we cannot specify length in sliceBytes, we'll check manually
                if (pathPtr + path.length > pathNibble.length) {
                    // The remaining pathNibble is shorter than the node's path
                    return "";
                }

                for (uint256 m = 0; m < path.length; m++) {
                    if (pathNibble[pathPtr + m] != path[m]) {
                        return "";
                    }
                }

                // Output the prefix for debugging
                // uint256 prefix = firstNibble;
                // console.log("prefix", prefix);

                if (isLeaf) {
                    // Leaf node
                    return nodeList[1].toBytes();
                } else {
                    // Extension node
                    nodeHash = bytes32(nodeList[1].toUint());
                    pathPtr += path.length;
                }
            } else {
                return "";
            }
        }
        return "";
    }

    function toNibbles(bytes32 b) internal pure returns (bytes memory) {
        bytes memory nibbles = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            nibbles[i * 2] = bytes1(uint8(uint256(b) >> (248 - i * 8)) >> 4);
            nibbles[i * 2 + 1] = bytes1(
                uint8(uint256(b) >> (248 - i * 8)) & 0x0f
            );
        }
        return nibbles;
    }

    function getNibbleArray(
        bytes memory b
    ) internal pure returns (bytes memory) {
        uint256 length = b.length * 2;
        bytes memory nibbles = new bytes(length);
        for (uint256 i = 0; i < b.length; i++) {
            nibbles[i * 2] = bytes1(uint8(b[i]) >> 4);
            nibbles[i * 2 + 1] = bytes1(uint8(b[i]) & 0x0f);
        }
        return nibbles;
    }

    function nibbleArrayEqual(
        bytes memory a,
        bytes memory b
    ) internal pure returns (bool) {
        if (a.length != b.length) return false;
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }

    function sliceBytes(
        bytes memory b,
        uint256 start
    ) internal pure returns (bytes memory) {
        if (start >= b.length) return new bytes(0);
        bytes memory sliced = new bytes(b.length - start);
        for (uint256 i = start; i < b.length; i++) {
            sliced[i - start] = b[i];
        }
        return sliced;
    }
}
