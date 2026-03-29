use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use image::ImageEncoder;
use qrcode::QrCode;

use crate::schema::setup_schema::{QrCodeResponse, ShortCodeResponse};
use crate::utils::error::AppError;
use crate::utils::setup_crypto;

pub struct SetupService {
    setup_secret: String,
    school_url: String,
    school_name: String,
}

impl SetupService {
    pub fn new(setup_secret: String, school_url: String, school_name: String) -> Self {
        Self {
            setup_secret,
            school_url,
            school_name,
        }
    }

    fn build_payload_json(&self) -> String {
        serde_json::json!({
            "url": self.school_url,
            "name": self.school_name,
        })
        .to_string()
    }

    /// Generates an AES-encrypted QR code for school onboarding.
    /// Returns the raw encrypted payload and a base64-encoded PNG image.
    pub fn generate_qr_code(&self) -> Result<QrCodeResponse, AppError> {
        let json = self.build_payload_json();

        let payload = setup_crypto::encrypt_setup_payload(&json, &self.setup_secret)
            .map_err(|e| AppError::InternalServerError(format!("Crypto error: {}", e)))?;

        // Render QR to PNG bytes
        let qr = QrCode::new(payload.as_bytes())
            .map_err(|e| AppError::InternalServerError(format!("QR generation failed: {}", e)))?;

        let image = qr.render::<image::Luma<u8>>().build();

        let mut png_bytes: Vec<u8> = Vec::new();
        let encoder = image::codecs::png::PngEncoder::new(&mut png_bytes);
        encoder
            .write_image(
                image.as_raw(),
                image.width(),
                image.height(),
                image::ExtendedColorType::L8,
            )
            .map_err(|e| AppError::InternalServerError(format!("PNG encoding failed: {}", e)))?;

        Ok(QrCodeResponse {
            payload,
            qr_png_base64: BASE64.encode(&png_bytes),
        })
    }

    /// Generates the deterministic 6-character short code for this school.
    pub fn generate_short_code(&self) -> Result<ShortCodeResponse, AppError> {
        let json = self.build_payload_json();

        let code = setup_crypto::derive_short_code(&json, &self.setup_secret)
            .map_err(|e| AppError::InternalServerError(format!("Crypto error: {}", e)))?;

        Ok(ShortCodeResponse { code })
    }
}
