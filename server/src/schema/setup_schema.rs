use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct QrCodeResponse {
    /// Base64-encoded AES-256-GCM encrypted JSON payload.
    /// The mobile app scans this and decrypts it to get the server URL.
    pub payload: String,
    /// Base64-encoded PNG image of the QR code.
    /// Render with: <img src="data:image/png;base64,{qr_png_base64}">
    pub qr_png_base64: String,
}

#[derive(Debug, Serialize)]
pub struct ShortCodeResponse {
    /// 6-character Base36 code (uppercase alphanumeric).
    /// Student enters this on the SchoolSetupPage to connect.
    pub code: String,
}
