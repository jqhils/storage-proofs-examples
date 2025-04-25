fn decode_rlp_header(node: [u8; 32]) -> RlpHeader {
    let mut header = RlpHeader::default();
    let mut offset = 0;

    // Get the first byte and constrain it to be a valid RLP prefix
    let first_byte = node[0] as u32;
    constrain first_byte < 256; // Ensure it's a valid byte

    // Single byte string case
    let is_single_byte = first_byte < 0x80;
    if is_single_byte {
        header.data_type = RLP_DATA_TYPE_STRING;
        header.length = 1;
        return header;
    }

    // Short string case
    let is_short_string = first_byte < 0xb8;
    if is_short_string {
        header.data_type = RLP_DATA_TYPE_STRING;
        let length = first_byte - 0x80;
        constrain length > 0; // Ensure length is positive
        header.length = length as u32;
        offset = 1;
        return header;
    }

    // Long string case
    let is_long_string = first_byte < 0xc0;
    if is_long_string {
        header.data_type = RLP_DATA_TYPE_STRING;
        let length_of_length = (first_byte - 0xb7) as u32;
        constrain length_of_length > 0 && length_of_length <= 4; // RLP spec limits
        
        header.length = 0;
        for i in 0..length_of_length {
            let byte = node[1 + i as usize] as u32;
            constrain byte < 256; // Ensure valid byte
            header.length = header.length * 256 + byte;
        }
        constrain header.length > 55; // RLP spec for long strings
        offset = 1 + length_of_length;
        return header;
    }

    // Short list case
    let is_short_list = first_byte < 0xf8;
    if is_short_list {
        header.data_type = RLP_DATA_TYPE_LIST;
        let length = first_byte - 0xc0;
        constrain length > 0; // Ensure length is positive
        header.length = length as u32;
        offset = 1;
        return header;
    }

    // Long list case
    header.data_type = RLP_DATA_TYPE_LIST;
    let length_of_length = (first_byte - 0xf7) as u32;
    constrain length_of_length > 0 && length_of_length <= 4; // RLP spec limits
    
    header.length = 0;
    for i in 0..length_of_length {
        let byte = node[1 + i as usize] as u32;
        constrain byte < 256; // Ensure valid byte
        header.length = header.length * 256 + byte;
    }
    constrain header.length > 55; // RLP spec for long lists
    offset = 1 + length_of_length;
    
    header
} 