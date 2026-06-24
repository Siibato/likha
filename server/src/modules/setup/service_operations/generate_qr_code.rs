use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use image::ImageEncoder;
use qrcode::QrCode;

use crate::modules::setup::repository::SetupRepository;
use crate::modules::setup::schema::QrCodeResponse;
use crate::utils::{AppError, AppResult};

pub async fn generate_qr_code(repo: &SetupRepository) -> AppResult<QrCodeResponse> {
    let row = repo.get_settings().await?;

    let qr = QrCode::new(row.school_code.as_bytes())
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
        code: row.school_code,
        qr_png_base64: BASE64.encode(&png_bytes),
    })
}
