use ring::aead::{self, Nonce, AES_256_GCM};
use ring::rand::{SecureRandom, SystemRandom};

use crate::utils::error::{AppError, AppResult};

/// Marker byte to identify encrypted files
const ENCRYPTION_MARKER: u8 = 0x01;

/// Size of the nonce for AES-GCM (96 bits = 12 bytes)
const NONCE_SIZE: usize = 12;

/// Size of the authentication tag for AES-GCM (128 bits = 16 bytes)
const TAG_SIZE: usize = 16;

/// Generate a random 12-byte nonce for AES-GCM
pub fn generate_nonce() -> [u8; NONCE_SIZE] {
    let rng = SystemRandom::new();
    let mut nonce = [0u8; NONCE_SIZE];
    rng.fill(&mut nonce).expect("Failed to generate nonce");
    nonce
}

/// Parse a 32-byte hex string into a byte array
pub fn parse_key(key_hex: &str) -> AppResult<[u8; 32]> {
    if key_hex.len() != 64 {
        return Err(AppError::BadRequest(
            "Encryption key must be 64 hex characters (32 bytes)".to_string(),
        ));
    }

    let mut key = [0u8; 32];
    for i in 0..32 {
        let byte_str = &key_hex[i * 2..i * 2 + 2];
        key[i] = u8::from_str_radix(byte_str, 16)
            .map_err(|_| AppError::BadRequest("Invalid hex in encryption key".to_string()))?;
    }

    Ok(key)
}

/// Encrypt file data using AES-256-GCM
/// Returns: [marker: 1 byte][nonce: 12 bytes][ciphertext + tag]
pub fn encrypt_file(data: &[u8], key: &[u8; 32]) -> Vec<u8> {
    let nonce_bytes = generate_nonce();
    let nonce = Nonce::assume_unique_for_key(nonce_bytes);

    // Start with plaintext in a mutable buffer
    let mut in_out = data.to_vec();

    // Create sealing key
    let sealing_key = aead::LessSafeKey::new(
        aead::UnboundKey::new(&AES_256_GCM, key).expect("Invalid key length"),
    );

    // Encrypt in-place and append tag
    sealing_key
        .seal_in_place_append_tag(nonce, aead::Aad::empty(), &mut in_out)
        .expect("Encryption failed");

    // Build output: marker + nonce + ciphertext_with_tag
    let mut result = Vec::with_capacity(1 + NONCE_SIZE + in_out.len());
    result.push(ENCRYPTION_MARKER);
    result.extend_from_slice(&nonce_bytes);
    result.extend_from_slice(&in_out);

    result
}

/// Decrypt file data using AES-256-GCM
/// Expects: [marker: 1 byte][nonce: 12 bytes][ciphertext + tag]
/// If no marker is present, returns the data as-is (legacy unencrypted file)
pub fn decrypt_file(data: &[u8], key: &[u8; 32]) -> AppResult<Vec<u8>> {
    // Check if file has encryption marker
    if data.is_empty() {
        return Ok(Vec::new());
    }

    if data[0] != ENCRYPTION_MARKER {
        // No marker - treat as unencrypted (legacy file)
        return Ok(data.to_vec());
    }

    // Ensure we have enough data for marker + nonce + minimum ciphertext
    if data.len() < 1 + NONCE_SIZE + TAG_SIZE {
        return Err(AppError::BadRequest(
            "Encrypted file data too short".to_string(),
        ));
    }

    // Extract nonce (skip marker byte)
    let mut nonce_bytes = [0u8; NONCE_SIZE];
    nonce_bytes.copy_from_slice(&data[1..1 + NONCE_SIZE]);
    let nonce = Nonce::assume_unique_for_key(nonce_bytes);

    // Extract ciphertext with tag (after marker and nonce)
    let mut in_out = data[1 + NONCE_SIZE..].to_vec();

    // Create opening key
    let opening_key = aead::LessSafeKey::new(
        aead::UnboundKey::new(&AES_256_GCM, key).expect("Invalid key length"),
    );

    // Decrypt in-place (automatically verifies authentication tag)
    let plaintext = opening_key
        .open_in_place(nonce, aead::Aad::empty(), &mut in_out)
        .map_err(|_| {
            AppError::BadRequest("Failed to decrypt file - wrong key or corrupted data".to_string())
        })?;

    Ok(plaintext.to_vec())
}

/// Check if data is encrypted (has the encryption marker)
pub fn is_encrypted(data: &[u8]) -> bool {
    !data.is_empty() && data[0] == ENCRYPTION_MARKER
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let key = [0x42u8; 32];
        let plaintext = b"Hello, world! This is a test file.";

        let encrypted = encrypt_file(plaintext, &key);
        assert!(is_encrypted(&encrypted));
        assert_eq!(encrypted[0], ENCRYPTION_MARKER);

        let decrypted = decrypt_file(&encrypted, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_decrypt_unencrypted_data() {
        let key = [0x42u8; 32];
        let plaintext = b"This is not encrypted";

        // Should return data as-is when no marker present
        let result = decrypt_file(plaintext, &key).unwrap();
        assert_eq!(result, plaintext.to_vec());
    }

    #[test]
    fn test_decrypt_with_wrong_key_fails() {
        let key1 = [0x42u8; 32];
        let key2 = [0x13u8; 32];
        let plaintext = b"Secret data";

        let encrypted = encrypt_file(plaintext, &key1);

        // Should fail with wrong key
        let result = decrypt_file(&encrypted, &key2);
        assert!(result.is_err());
    }

    #[test]
    fn test_decrypt_tampered_data_fails() {
        let key = [0x42u8; 32];
        let plaintext = b"Secret data";

        let mut encrypted = encrypt_file(plaintext, &key);
        // Tamper with the ciphertext
        let last_idx = encrypted.len() - 1;
        encrypted[last_idx] ^= 0xFF;

        let result = decrypt_file(&encrypted, &key);
        assert!(result.is_err());
    }

    #[test]
    fn test_empty_data() {
        let key = [0x42u8; 32];
        let empty: &[u8] = b"";

        let result = decrypt_file(empty, &key).unwrap();
        assert!(result.is_empty());
    }

    #[test]
    fn test_parse_key() {
        let key_hex = "a".repeat(64);
        let key = parse_key(&key_hex).unwrap();
        assert_eq!(key.len(), 32);
        assert_eq!(key[0], 0xAA); // 'aa' in hex = 170 = 0xAA

        // Wrong length should fail
        let result = parse_key(&"a".repeat(63));
        assert!(result.is_err());
    }

    #[test]
    fn test_encrypt_produces_different_output_each_time() {
        let key = [0x42u8; 32];
        let plaintext = b"Same data";

        let encrypted1 = encrypt_file(plaintext, &key);
        let encrypted2 = encrypt_file(plaintext, &key);

        // Due to random nonce, ciphertexts should differ
        assert_ne!(encrypted1, encrypted2);

        // But both should decrypt to same plaintext
        assert_eq!(decrypt_file(&encrypted1, &key).unwrap(), plaintext.to_vec());
        assert_eq!(decrypt_file(&encrypted2, &key).unwrap(), plaintext.to_vec());
    }
}
