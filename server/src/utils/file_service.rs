use sha2::{Digest, Sha256};
use std::path::Path;
use uuid::Uuid;

use crate::utils::file_encryption::{decrypt_file, encrypt_file};

/// Compute SHA-256 hash of file bytes
pub fn compute_hash(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}

/// Generate disk filename from original name and UUID
pub fn generate_disk_filename(original_name: &str, id: Uuid) -> String {
    let short_id = id.to_string()[0..8].to_string();
    if let Some(dot_pos) = original_name.rfind('.') {
        let name = &original_name[..dot_pos];
        let ext = &original_name[dot_pos + 1..];
        format!("{}-{}.{}", name, short_id, ext)
    } else {
        format!("{}-{}", original_name, short_id)
    }
}

/// Ensure directory exists and create it if needed
pub async fn ensure_dir(path: &Path) -> Result<(), std::io::Error> {
    if !path.exists() {
        tokio::fs::create_dir_all(path).await?;
    }
    Ok(())
}

/// Write file bytes to disk
/// If encryption_key is provided, data will be encrypted before writing
pub async fn write_file(
    path: &Path,
    data: &[u8],
    encryption_key: Option<&[u8; 32]>,
) -> Result<(), std::io::Error> {
    if let Some(parent) = path.parent() {
        ensure_dir(parent).await?;
    }

    let data_to_write = if let Some(key) = encryption_key {
        encrypt_file(data, key)
    } else {
        data.to_vec()
    };

    tokio::fs::write(path, data_to_write).await
}

/// Read file bytes from disk
/// If encryption_key is provided, data will be decrypted after reading
pub async fn read_file(
    path: &Path,
    encryption_key: Option<&[u8; 32]>,
) -> Result<Vec<u8>, std::io::Error> {
    let data = tokio::fs::read(path).await?;

    if let Some(key) = encryption_key {
        decrypt_file(&data, key).map_err(|e| {
            std::io::Error::new(
                std::io::ErrorKind::InvalidData,
                format!("Decryption failed: {}", e),
            )
        })
    } else {
        Ok(data)
    }
}

/// Delete file from disk (best-effort, logs errors but doesn't fail)
pub async fn delete_file(path: &Path) {
    if let Err(e) = tokio::fs::remove_file(path).await {
        eprintln!("Warning: Failed to delete file {:?}: {}", path, e);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_hash() {
        let hash1 = compute_hash(b"test data");
        let hash2 = compute_hash(b"test data");
        let hash3 = compute_hash(b"other data");

        assert_eq!(hash1, hash2);
        assert_ne!(hash1, hash3);
        assert_eq!(hash1.len(), 64); // SHA-256 hex is 64 chars
    }

    #[test]
    fn test_generate_disk_filename() {
        let id = Uuid::parse_str("550e8400-e29b-41d4-a716-446655440000").unwrap();
        let filename = generate_disk_filename("document.pdf", id);
        assert_eq!(filename, "document-550e8400.pdf");

        let filename2 = generate_disk_filename("report", id);
        assert_eq!(filename2, "report-550e8400");
    }
}
