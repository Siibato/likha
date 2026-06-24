use sha2::{Digest, Sha256};
use uuid::Uuid;

pub fn seed_id(table: &str, name: &str) -> Uuid {
    let input = format!("{table}:{name}");
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    let result = hasher.finalize();

    // Use first 16 bytes of hash to create a UUID
    let bytes: [u8; 16] = result[..16].try_into().expect("Slice is always 16 bytes");

    // Set UUID version (4) and variant bits for standard UUID format
    let mut uuid_bytes = bytes;
    uuid_bytes[6] = (uuid_bytes[6] & 0x0f) | 0x40; // Version 4
    uuid_bytes[8] = (uuid_bytes[8] & 0x3f) | 0x80; // Variant 10

    Uuid::from_bytes(uuid_bytes)
}
