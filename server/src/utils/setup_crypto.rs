use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Key, Nonce,
};
use aes_gcm::aead::rand_core::RngCore;
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use sha2::{Digest, Sha256};

#[derive(Debug)]
pub enum CryptoError {
    EncryptionFailed(String),
    DecryptionFailed(String),
    InvalidInput(String),
}

impl std::fmt::Display for CryptoError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CryptoError::EncryptionFailed(msg) => write!(f, "Encryption failed: {}", msg),
            CryptoError::DecryptionFailed(msg) => write!(f, "Decryption failed: {}", msg),
            CryptoError::InvalidInput(msg) => write!(f, "Invalid input: {}", msg),
        }
    }
}

/// Derives a 32-byte AES key from the secret string using SHA-256.
fn derive_key(secret: &str) -> Key<Aes256Gcm> {
    let mut hasher = Sha256::new();
    hasher.update(secret.as_bytes());
    let result = hasher.finalize();
    *Key::<Aes256Gcm>::from_slice(&result)
}

/// Encrypts a JSON payload using AES-256-GCM.
/// Returns Base64(nonce[12] + ciphertext).
pub fn encrypt_setup_payload(json: &str, secret: &str) -> Result<String, CryptoError> {
    let key = derive_key(secret);
    let cipher = Aes256Gcm::new(&key);

    let mut nonce_bytes = [0u8; 12];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher
        .encrypt(nonce, json.as_bytes())
        .map_err(|e| CryptoError::EncryptionFailed(e.to_string()))?;

    let mut combined = Vec::with_capacity(12 + ciphertext.len());
    combined.extend_from_slice(&nonce_bytes);
    combined.extend_from_slice(&ciphertext);

    Ok(BASE64.encode(&combined))
}

/// Decrypts a Base64-encoded AES-256-GCM payload.
pub fn decrypt_setup_payload(b64: &str, secret: &str) -> Result<String, CryptoError> {
    let combined = BASE64
        .decode(b64)
        .map_err(|e| CryptoError::InvalidInput(e.to_string()))?;

    if combined.len() < 13 {
        return Err(CryptoError::InvalidInput("Payload too short".to_string()));
    }

    let key = derive_key(secret);
    let cipher = Aes256Gcm::new(&key);

    let nonce = Nonce::from_slice(&combined[..12]);
    let ciphertext = &combined[12..];

    let plaintext = cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| CryptoError::DecryptionFailed(e.to_string()))?;

    String::from_utf8(plaintext)
        .map_err(|e| CryptoError::DecryptionFailed(e.to_string()))
}

/// Derives a deterministic 6-character Base36 short code from a JSON payload.
/// Uses a fixed zero nonce so the same payload always produces the same code.
pub fn derive_short_code(json: &str, secret: &str) -> Result<String, CryptoError> {
    let key = derive_key(secret);
    let cipher = Aes256Gcm::new(&key);

    // Fixed nonce for deterministic output
    let nonce = Nonce::from_slice(&[0u8; 12]);

    let ciphertext = cipher
        .encrypt(nonce, json.as_bytes())
        .map_err(|e| CryptoError::EncryptionFailed(e.to_string()))?;

    // Convert first 5 bytes to a 40-bit number, then Base36-encode
    let mut value: u64 = 0;
    for &byte in ciphertext.iter().take(5) {
        value = (value << 8) | (byte as u64);
    }
    Ok(to_base36(value, 6))
}

fn to_base36(mut value: u64, min_len: usize) -> String {
    const CHARS: &[u8] = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    let mut result = Vec::new();
    if value == 0 {
        result.push(b'0');
    } else {
        while value > 0 {
            result.push(CHARS[(value % 36) as usize]);
            value /= 36;
        }
    }
    result.reverse();
    let s = String::from_utf8(result).unwrap_or_default();
    // Pad to minimum length
    format!("{:0>width$}", s, width = min_len)
        .chars()
        .take(min_len.max(s.len()))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encrypt_decrypt_roundtrip() {
        let payload = r#"{"url":"http://192.168.1.1:8080","name":"Test School"}"#;
        let secret = "test-secret-32-chars-padded-here";
        let encrypted = encrypt_setup_payload(payload, secret).unwrap();
        let decrypted = decrypt_setup_payload(&encrypted, secret).unwrap();
        assert_eq!(payload, decrypted);
    }

    #[test]
    fn short_code_is_deterministic() {
        let payload = r#"{"url":"http://192.168.1.1:8080","name":"Pi School"}"#;
        let secret = "test-secret-32-chars-padded-here";
        let code1 = derive_short_code(payload, secret).unwrap();
        let code2 = derive_short_code(payload, secret).unwrap();
        assert_eq!(code1, code2);
        assert_eq!(code1.len(), 6);
    }
}
