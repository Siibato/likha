use axum::extract::Multipart;
use serde::de::DeserializeOwned;
use csv::ReaderBuilder;

/// Extract raw bytes from the first file field in a Multipart body.
pub async fn extract_csv_bytes(multipart: &mut Multipart) -> Result<Vec<u8>, String> {
    while let Some(field) = multipart.next_field().await.map_err(|e| format!("Multipart error: {}", e))? {
        let _name = field.name().unwrap_or("file").to_string();
        let bytes = field.bytes().await.map_err(|e| format!("Failed to read field: {}", e))?;
        if !bytes.is_empty() {
            return Ok(bytes.to_vec());
        }
    }
    Err("No file field found in multipart body".to_string())
}

/// Parse CSV bytes into a list of results — each row either deserializes into T or produces an error string.
pub fn parse_csv<T: DeserializeOwned>(bytes: &[u8]) -> Vec<Result<T, String>> {
    let mut reader = ReaderBuilder::new()
        .has_headers(true)
        .flexible(true)
        .from_reader(bytes);

    let mut results = Vec::new();
    for result in reader.deserialize::<T>() {
        match result {
            Ok(record) => results.push(Ok(record)),
            Err(e) => results.push(Err(format!("Row parse error: {}", e))),
        }
    }
    results
}

/// Generate a CSV template with the given headers and one empty row.
pub fn generate_template(headers: &[&str]) -> Vec<u8> {
    let mut wtr = csv::Writer::from_writer(Vec::new());
    wtr.write_record(headers).unwrap();
    wtr.write_record(headers.iter().map(|_| "")).unwrap();
    wtr.flush().unwrap();
    wtr.into_inner().unwrap()
}
