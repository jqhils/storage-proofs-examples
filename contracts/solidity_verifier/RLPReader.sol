// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// RLPReader library for decoding RLP-encoded data
library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    function toRlpItem(
        bytes memory item
    ) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }
        return RLPItem({len: item.length, memPtr: memPtr});
    }

    function toList(
        RLPItem memory item
    ) internal pure returns (RLPItem[] memory result) {
        require(isList(item), "RLPReader: item is not a list");
        uint256 items = numItems(item);
        result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = itemLength(memPtr);
            result[i] = RLPItem({len: dataLen, memPtr: memPtr});
            memPtr = memPtr + dataLen;
        }
    }

    function isList(RLPItem memory item) internal pure returns (bool) {
        uint256 memPtr = item.memPtr; // Assign to local variable
        uint8 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    function numItems(RLPItem memory item) internal pure returns (uint256) {
        uint256 count = 0;
        uint256 currPtr = item.memPtr + payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + itemLength(currPtr);
            count++;
        }
        return count;
    }

    function itemLength(uint256 memPtr) internal pure returns (uint256 len) {
        uint8 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < STRING_SHORT_START) return 1;
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            uint8 byteLen = byte0 - STRING_LONG_START + 1;
            uint256 dataLen;
            assembly {
                dataLen := div(
                    mload(add(memPtr, 1)),
                    exp(256, sub(32, byteLen))
                )
            }
            len = dataLen + byteLen + 1;
        } else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } else {
            uint8 byteLen = byte0 - LIST_LONG_START + 1;
            uint256 dataLen;
            assembly {
                dataLen := div(
                    mload(add(memPtr, 1)),
                    exp(256, sub(32, byteLen))
                )
            }
            len = dataLen + byteLen + 1;
        }
    }

    function payloadOffset(uint256 memPtr) internal pure returns (uint256) {
        uint8 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < STRING_SHORT_START) return 0;
        else if (
            byte0 < STRING_LONG_START ||
            (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
        ) return 1;
        else if (byte0 < LIST_SHORT_START)
            // string long
            return byte0 - 0xb7 + 1;
        else return byte0 - 0xf7 + 1;
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        // console.log("item.len", item.len);
        require(item.len <= 33, "RLPReader: invalid uint length");
        uint256 offset = payloadOffset(item.memPtr);
        uint256 len = item.len - offset;
        uint256 result;
        uint256 memPtr = item.memPtr + offset; // Assign to local variable
        assembly {
            let ptr := memPtr
            result := mload(ptr)
            // Adjust for potential leading zeros
            result := div(result, exp(256, sub(32, len)))
        }
        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint256 offset = payloadOffset(item.memPtr);
        uint256 len = item.len - offset;
        bytes memory result = new bytes(len);
        if (len == 0) {
            return result;
        }
        uint256 destPtr;
        uint256 srcPtr = item.memPtr + offset; // Assign to local variable
        assembly {
            // let srcPtr := add(item.memPtr, offset)
            destPtr := add(result, 0x20)
            // Copy data
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 32)
            } {
                mstore(add(destPtr, i), mload(add(srcPtr, i)))
            }
        }
        return result;
    }
}
