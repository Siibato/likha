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

    let headers = match reader.headers() {
        Ok(h) => h.iter().map(|s| s.to_string()).collect::<Vec<_>>(),
        Err(e) => return vec![Err(format!("Failed to read CSV headers: {}", e))],
    };

    let mut results = Vec::new();
    for record in reader.records() {
        match record {
            Ok(r) => {
                let mut json_obj = serde_json::Map::new();
                for (i, header) in headers.iter().enumerate() {
                    let val = r.get(i).unwrap_or("");
                    // Store empty strings as null so optional fields work
                    if val.is_empty() {
                        json_obj.insert(header.clone(), serde_json::Value::Null);
                    } else {
                        json_obj.insert(header.clone(), serde_json::Value::String(val.to_string()));
                    }
                }
                let json_value = serde_json::Value::Object(json_obj);
                match serde_json::from_value::<T>(json_value) {
                    Ok(parsed) => results.push(Ok(parsed)),
                    Err(e) => results.push(Err(format!("Row parse error: {}", e))),
                }
            }
            Err(e) => {
                results.push(Err(format!("CSV record error: {}", e)));
            }
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
