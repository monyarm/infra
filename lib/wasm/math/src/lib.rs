use nix_wasm_rust::Value;

// Table-driven CRC32 (IEEE 802.3, 0xEDB88320), matches the pure-Nix
// version it replaces (shortcuts.vdf.nix) byte-for-byte.
const fn make_table() -> [u32; 256] {
    let mut table = [0u32; 256];
    let mut i = 0;
    while i < 256 {
        let mut crc = i as u32;
        let mut j = 0;
        while j < 8 {
            crc = if crc & 1 == 1 {
                (crc >> 1) ^ 0xEDB88320
            } else {
                crc >> 1
            };
            j += 1;
        }
        table[i] = crc;
        i += 1;
    }
    table
}

const CRC_TABLE: [u32; 256] = make_table();

fn crc32(bytes: &[u8]) -> u32 {
    let mut crc: u32 = 0xFFFFFFFF;
    for &byte in bytes {
        let idx = ((crc ^ byte as u32) & 0xFF) as usize;
        crc = (crc >> 8) ^ CRC_TABLE[idx];
    }
    crc ^ 0xFFFFFFFF
}

#[no_mangle]
pub extern "C" fn crc32_string(arg: Value) -> Value {
    let s = arg.get_string();
    Value::make_int(crc32(s.as_bytes()) as i64)
}
