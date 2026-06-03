use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize)]
pub struct VerifyResponse {
    pub school_name: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct QrCodeResponse {
    pub code: String,
    pub qr_png_base64: String,
}

#[derive(Debug, Serialize)]
pub struct ShortCodeResponse {
    pub code: String,
}

#[derive(Debug, Serialize)]
pub struct SchoolSettingsResponse {
    pub school_code: String,
    pub school_name: Option<String>,
    pub school_region: Option<String>,
    pub school_division: Option<String>,
    pub school_year: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateCodeRequest {
    pub code: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateSchoolSettingsRequest {
    pub school_name: String,
    pub school_region: Option<String>,
    pub school_division: Option<String>,
    pub school_year: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct VerifyQuery {
    pub code: String,
}
