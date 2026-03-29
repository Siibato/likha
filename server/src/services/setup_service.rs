use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use chrono::Utc;
use image::ImageEncoder;
use qrcode::QrCode;
use sea_orm::{
    ActiveModelTrait, ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, Set,
};

use crate::schema::setup_schema::{
    QrCodeResponse, SchoolSettingsResponse, ShortCodeResponse, UpdateSchoolSettingsRequest,
    VerifyResponse,
};
use crate::utils::error::AppError;

pub struct SetupService {
    db: DatabaseConnection,
}

impl SetupService {
    /// Creates the service and seeds the school_settings row if it doesn't exist.
    pub async fn new(db: DatabaseConnection, default_school_code: String) -> Self {
        let service = Self { db };
        if let Err(e) = service.seed_if_needed(&default_school_code).await {
            tracing::error!("Failed to seed school_settings: {}", e);
        }
        service
    }

    async fn seed_if_needed(&self, default_code: &str) -> Result<(), sea_orm::DbErr> {
        use entity::school_settings;
        let existing = school_settings::Entity::find_by_id(1).one(&self.db).await?;
        if existing.is_none() {
            let model = school_settings::ActiveModel {
                id: Set(1),
                school_code: Set(default_code.to_uppercase()),
                school_name: Set(None),
                school_region: Set(None),
                school_division: Set(None),
                school_year: Set(None),
                updated_at: Set(Utc::now().naive_utc()),
            };
            model.insert(&self.db).await?;
            tracing::info!("Seeded school_settings with code: {}", default_code);
        }
        Ok(())
    }

    async fn get_settings_row(&self) -> Result<entity::school_settings::Model, AppError> {
        use entity::school_settings;
        school_settings::Entity::find_by_id(1)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("DB error: {}", e)))?
            .ok_or_else(|| AppError::InternalServerError("School settings not initialized".to_string()))
    }

    // ---------------------------------------------------------------------------
    // Public endpoints
    // ---------------------------------------------------------------------------

    /// Verifies a school code (case-insensitive). Returns school_name on match.
    pub async fn verify_code(&self, code: &str) -> Result<VerifyResponse, AppError> {
        let row = self.get_settings_row().await?;
        if code.to_uppercase() == row.school_code.to_uppercase() {
            Ok(VerifyResponse {
                school_name: row.school_name,
            })
        } else {
            Err(AppError::Forbidden("Invalid school code".to_string()))
        }
    }

    /// Returns public school info (school_name only).
    pub async fn get_school_info(&self) -> Result<VerifyResponse, AppError> {
        let row = self.get_settings_row().await?;
        Ok(VerifyResponse {
            school_name: row.school_name,
        })
    }

    // ---------------------------------------------------------------------------
    // Admin endpoints
    // ---------------------------------------------------------------------------

    /// Returns all school settings.
    pub async fn get_school_settings(&self) -> Result<SchoolSettingsResponse, AppError> {
        let row = self.get_settings_row().await?;
        Ok(SchoolSettingsResponse {
            school_code: row.school_code,
            school_name: row.school_name,
            school_region: row.school_region,
            school_division: row.school_division,
            school_year: row.school_year,
        })
    }

    /// Updates school details (name, region, division, year).
    pub async fn update_school_settings(
        &self,
        request: UpdateSchoolSettingsRequest,
    ) -> Result<SchoolSettingsResponse, AppError> {
        use entity::school_settings;
        let row = self.get_settings_row().await?;
        let mut active: school_settings::ActiveModel = row.into();
        active.school_name = Set(Some(request.school_name));
        active.school_region = Set(request.school_region);
        active.school_division = Set(request.school_division);
        active.school_year = Set(request.school_year);
        active.updated_at = Set(Utc::now().naive_utc());
        let updated = active
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("DB error: {}", e)))?;

        Ok(SchoolSettingsResponse {
            school_code: updated.school_code,
            school_name: updated.school_name,
            school_region: updated.school_region,
            school_division: updated.school_division,
            school_year: updated.school_year,
        })
    }

    /// Updates the school code in the database.
    pub async fn update_code(&self, new_code: String) -> Result<(), AppError> {
        use entity::school_settings;
        let trimmed = new_code.trim().to_uppercase();
        if trimmed.is_empty() || trimmed.len() > 10 {
            return Err(AppError::BadRequest("Code must be 1-10 characters".to_string()));
        }
        let row = self.get_settings_row().await?;
        let mut active: school_settings::ActiveModel = row.into();
        active.school_code = Set(trimmed);
        active.updated_at = Set(Utc::now().naive_utc());
        active
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("DB error: {}", e)))?;
        Ok(())
    }

    /// Returns the current school code.
    pub async fn get_school_code(&self) -> Result<ShortCodeResponse, AppError> {
        let row = self.get_settings_row().await?;
        Ok(ShortCodeResponse {
            code: row.school_code,
        })
    }

    /// Generates a QR code PNG containing the plain school code text.
    pub async fn generate_qr_code(&self) -> Result<QrCodeResponse, AppError> {
        let row = self.get_settings_row().await?;

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
}
