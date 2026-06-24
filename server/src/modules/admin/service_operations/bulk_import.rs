use sea_orm::{ActiveModelTrait, ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter};
use serde_json::Value;

use ::entity::users;
use chrono::Utc;

use crate::modules::admin::csv_handler;
use crate::modules::admin::import_schema::{
    ImportResultResponse, PreviewResponse, PreviewRowResponse, StudentCsvRow,
};
use crate::modules::admin::schema::LearnerDetailsPayload;
use crate::modules::admin::service_operations::upsert_account_details::upsert_account_details;
use crate::modules::auth::UserRepository;
use crate::utils::validators::Validator;
use crate::utils::{AppError, AppResult};

/// Parse CSV bytes and validate each row for student import.
/// Returns a preview with per-row errors and warnings.
pub async fn preview_students(
    _db: &DatabaseConnection,
    user_repo: &UserRepository,
    csv_bytes: &[u8],
) -> AppResult<PreviewResponse> {
    let parsed = csv_handler::parse_csv::<StudentCsvRow>(csv_bytes);
    let mut rows = Vec::new();

    for (i, result) in parsed.into_iter().enumerate() {
        let row_index = i + 1;
        let mut errors = Vec::new();
        let warnings = Vec::new();

        let row_data: Value = match result {
            Ok(row) => {
                // Validate required fields
                let username = row.username.as_deref().unwrap_or("").trim();
                if username.is_empty() {
                    errors.push("username is required".to_string());
                } else if let Err(e) = Validator::validate_username(username) {
                    errors.push(format!("username: {}", e));
                } else {
                    // Check DB for existing username
                    if let Ok(Some(_)) = user_repo.find_by_username(username).await {
                        errors.push(format!("username '{}' already exists", username));
                    }
                }

                if row.first_name.as_deref().unwrap_or("").trim().is_empty() {
                    errors.push("first_name is required".to_string());
                }
                if row.last_name.as_deref().unwrap_or("").trim().is_empty() {
                    errors.push("last_name is required".to_string());
                }

                if row.age.is_some() {
                    errors.push(
                        "age column is no longer supported. Remove it and rely on birthdate."
                            .to_string(),
                    );
                }

                // Type-check birthdate if present
                if let Some(ref bd) = row.birthdate {
                    if bd.trim().is_empty() {
                        // empty is fine (treated as None)
                    } else if bd.parse::<chrono::NaiveDate>().is_err() {
                        errors.push("birthdate must be in YYYY-MM-DD format".to_string());
                    }
                }

                if let Some(ref da) = row.date_admitted {
                    if da.trim().is_empty() {
                        // empty is fine
                    } else if da.parse::<chrono::NaiveDate>().is_err() {
                        errors.push("date_admitted must be in YYYY-MM-DD format".to_string());
                    }
                }

                serde_json::to_value(&row).unwrap_or(Value::Null)
            }
            Err(e) => {
                errors.push(e);
                Value::Null
            }
        };

        rows.push(PreviewRowResponse {
            row_index,
            data: row_data,
            errors,
            warnings,
        });
    }

    Ok(PreviewResponse { rows })
}

/// Batch insert students from validated preview rows.
/// Each row is processed independently — partial success is reported.
pub async fn import_students(
    db: &DatabaseConnection,
    _user_repo: &UserRepository,
    rows: &[Value],
) -> AppResult<ImportResultResponse> {
    let mut imported = 0usize;
    let mut errors = Vec::new();

    for (i, row_data) in rows.iter().enumerate() {
        let row: StudentCsvRow = match serde_json::from_value(row_data.clone()) {
            Ok(r) => r,
            Err(e) => {
                errors.push(format!("Row {}: parse error: {}", i + 1, e));
                continue;
            }
        };

        let username = row.username.unwrap_or_default().trim().to_string();
        let first_name = row.first_name.unwrap_or_default().trim().to_string();
        let last_name = row.last_name.unwrap_or_default().trim().to_string();

        if username.is_empty() || first_name.is_empty() || last_name.is_empty() {
            errors.push(format!("Row {}: missing required fields", i + 1));
            continue;
        }

        // Check if user already exists
        let existing = users::Entity::find()
            .filter(users::Column::Username.eq(&username))
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
        if existing.is_some() {
            errors.push(format!(
                "Row {}: username '{}' already exists",
                i + 1,
                username
            ));
            continue;
        }

        if row.age.is_some() {
            errors.push(format!(
                "Row {}: age column is no longer supported. Remove it before importing.",
                i + 1
            ));
            continue;
        }

        // Create the user account
        let user = users::ActiveModel {
            id: sea_orm::ActiveValue::Set(uuid::Uuid::new_v4()),
            username: sea_orm::ActiveValue::Set(username),
            password_hash: sea_orm::ActiveValue::Set(None),
            first_name: sea_orm::ActiveValue::Set(first_name),
            last_name: sea_orm::ActiveValue::Set(last_name),
            role: sea_orm::ActiveValue::Set("student".to_string()),
            account_status: sea_orm::ActiveValue::Set("pending_activation".to_string()),
            activated_at: sea_orm::ActiveValue::Set(None),
            created_at: sea_orm::ActiveValue::Set(Utc::now().naive_utc()),
            updated_at: sea_orm::ActiveValue::Set(Utc::now().naive_utc()),
            deleted_at: sea_orm::ActiveValue::Set(None),
        };
        let user = match user.insert(db).await {
            Ok(u) => u,
            Err(e) => {
                errors.push(format!("Row {}: failed to create account: {}", i + 1, e));
                continue;
            }
        };

        // Upsert learner details if any are present
        let has_learner_details = row.lrn.is_some()
            || row.sex.is_some()
            || row.track_strand.is_some()
            || row.curriculum.is_some()
            || row.birthdate.is_some()
            || row.birthplace.is_some()
            || row.home_address.is_some()
            || row.father_name.is_some()
            || row.father_contact.is_some()
            || row.mother_name.is_some()
            || row.mother_contact.is_some()
            || row.guardian_name.is_some()
            || row.guardian_contact.is_some()
            || row.date_admitted.is_some();

        if has_learner_details {
            let payload = LearnerDetailsPayload {
                lrn: row.lrn.filter(|s| !s.trim().is_empty()),
                sex: row.sex.filter(|s| !s.trim().is_empty()),
                track_strand: row.track_strand.filter(|s| !s.trim().is_empty()),
                curriculum: row.curriculum.filter(|s| !s.trim().is_empty()),
                birthdate: row.birthdate.filter(|s| !s.trim().is_empty()),
                birthplace: row.birthplace.filter(|s| !s.trim().is_empty()),
                home_address: row.home_address.filter(|s| !s.trim().is_empty()),
                father_name: row.father_name.filter(|s| !s.trim().is_empty()),
                father_contact: row.father_contact.filter(|s| !s.trim().is_empty()),
                mother_name: row.mother_name.filter(|s| !s.trim().is_empty()),
                mother_contact: row.mother_contact.filter(|s| !s.trim().is_empty()),
                guardian_name: row.guardian_name.filter(|s| !s.trim().is_empty()),
                guardian_contact: row.guardian_contact.filter(|s| !s.trim().is_empty()),
                date_admitted: row.date_admitted.filter(|s| !s.trim().is_empty()),
            };

            if let Err(e) =
                upsert_account_details(db, user.id, "student", Some(payload), None).await
            {
                errors.push(format!(
                    "Row {}: failed to save learner details: {}",
                    i + 1,
                    e
                ));
                continue;
            }
        }

        imported += 1;
    }

    Ok(ImportResultResponse { imported, errors })
}
