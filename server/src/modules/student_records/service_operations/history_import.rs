use sea_orm::{ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter};
use serde_json::Value;
use uuid::Uuid;

use crate::modules::admin::csv_handler;
use crate::modules::student_records::import_schema::{
    AttendanceCsvRow, ImportResultResponse, PreviewResponse, PreviewRowResponse,
    SchoolHistoryCsvRow, SubjectsCsvRow,
};
use crate::modules::student_records::repository_operations as ops;
use crate::utils::{AppError, AppResult};
use ::entity::{
    previous_school_attendance, previous_school_subjects, student_school_history, users,
};

/// Resolve a username to a user UUID.
async fn resolve_user_id(db: &DatabaseConnection, username: &str) -> AppResult<Option<Uuid>> {
    let user = users::Entity::find()
        .filter(users::Column::Username.eq(username))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(user.map(|u| u.id))
}

/// Resolve school_history_id from (student_id, school_name, school_year).
async fn resolve_school_history_id(
    db: &DatabaseConnection,
    student_id: Uuid,
    school_name: &str,
    school_year: &str,
) -> AppResult<Option<Uuid>> {
    let hist = student_school_history::Entity::find()
        .filter(student_school_history::Column::StudentId.eq(student_id))
        .filter(student_school_history::Column::SchoolName.eq(school_name))
        .filter(student_school_history::Column::SchoolYear.eq(school_year))
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    Ok(hist.map(|h| h.id))
}

// ── School History Preview ──

pub async fn preview_school_history(
    db: &DatabaseConnection,
    csv_bytes: &[u8],
) -> AppResult<PreviewResponse> {
    let parsed = csv_handler::parse_csv::<SchoolHistoryCsvRow>(csv_bytes);
    let mut rows = Vec::new();

    for (i, result) in parsed.into_iter().enumerate() {
        let row_index = i + 1;
        let mut errors = Vec::new();
        let mut warnings = Vec::new();

        let row_data: Value = match result {
            Ok(row) => {
                let username = row.username.as_deref().unwrap_or("").trim().to_string();
                let school_name = row.school_name.as_deref().unwrap_or("").trim().to_string();
                let school_year = row.school_year.as_deref().unwrap_or("").trim().to_string();
                let grade_level = row.grade_level.as_deref().unwrap_or("").trim().to_string();

                if username.is_empty() {
                    errors.push("username is required".to_string());
                }
                if school_name.is_empty() {
                    errors.push("school_name is required".to_string());
                }
                if school_year.is_empty() {
                    errors.push("school_year is required".to_string());
                }
                if grade_level.is_empty() {
                    errors.push("grade_level is required".to_string());
                }

                // Resolve student_id
                if errors.is_empty() {
                    match resolve_user_id(db, &username).await {
                        Ok(Some(student_id)) => {
                            // Check for existing record
                            match resolve_school_history_id(
                                db,
                                student_id,
                                &school_name,
                                &school_year,
                            )
                            .await
                            {
                                Ok(Some(_)) => {
                                    warnings.push("Record exists and will be updated".to_string());
                                }
                                Ok(None) => {}
                                Err(e) => errors.push(format!("Database error: {}", e)),
                            }
                        }
                        Ok(None) => errors.push(format!("User '{}' not found", username)),
                        Err(e) => errors.push(format!("Database error: {}", e)),
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

// ── Subjects Preview ──

pub async fn preview_subjects(
    db: &DatabaseConnection,
    csv_bytes: &[u8],
) -> AppResult<PreviewResponse> {
    let parsed = csv_handler::parse_csv::<SubjectsCsvRow>(csv_bytes);
    let mut rows = Vec::new();

    for (i, result) in parsed.into_iter().enumerate() {
        let row_index = i + 1;
        let mut errors = Vec::new();
        let mut warnings = Vec::new();

        let row_data: Value = match result {
            Ok(row) => {
                let username = row.username.as_deref().unwrap_or("").trim().to_string();
                let school_name = row.school_name.as_deref().unwrap_or("").trim().to_string();
                let school_year = row.school_year.as_deref().unwrap_or("").trim().to_string();
                let subject_name = row.subject_name.as_deref().unwrap_or("").trim().to_string();
                let term_type = row.term_type.as_deref().unwrap_or("").trim().to_string();

                if username.is_empty() {
                    errors.push("username is required".to_string());
                }
                if school_name.is_empty() {
                    errors.push("school_name is required".to_string());
                }
                if school_year.is_empty() {
                    errors.push("school_year is required".to_string());
                }
                if subject_name.is_empty() {
                    errors.push("subject_name is required".to_string());
                }
                if term_type.is_empty() {
                    errors.push("term_type is required".to_string());
                }

                if errors.is_empty() {
                    match resolve_user_id(db, &username).await {
                        Ok(Some(student_id)) => {
                            match resolve_school_history_id(
                                db,
                                student_id,
                                &school_name,
                                &school_year,
                            )
                            .await
                            {
                                Ok(Some(history_id)) => {
                                    // Check for duplicate subject
                                    let existing = previous_school_subjects::Entity::find()
                                        .filter(
                                            previous_school_subjects::Column::StudentId
                                                .eq(student_id),
                                        )
                                        .filter(
                                            previous_school_subjects::Column::SchoolHistoryId
                                                .eq(history_id),
                                        )
                                        .filter(
                                            previous_school_subjects::Column::SubjectName
                                                .eq(&subject_name),
                                        )
                                        .one(db)
                                        .await
                                        .map_err(|e| {
                                            AppError::InternalServerError(format!(
                                                "Database error: {}",
                                                e
                                            ))
                                        });

                                    match existing {
                                        Ok(Some(_)) => warnings
                                            .push("Record exists and will be updated".to_string()),
                                        Ok(None) => {}
                                        Err(e) => errors.push(format!("Database error: {}", e)),
                                    }
                                }
                                Ok(None) => errors.push("School history not found".to_string()),
                                Err(e) => errors.push(format!("Database error: {}", e)),
                            }
                        }
                        Ok(None) => errors.push(format!("User '{}' not found", username)),
                        Err(e) => errors.push(format!("Database error: {}", e)),
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

// ── Attendance Preview ──

pub async fn preview_attendance(
    db: &DatabaseConnection,
    csv_bytes: &[u8],
) -> AppResult<PreviewResponse> {
    let parsed = csv_handler::parse_csv::<AttendanceCsvRow>(csv_bytes);
    let mut rows = Vec::new();

    for (i, result) in parsed.into_iter().enumerate() {
        let row_index = i + 1;
        let mut errors = Vec::new();
        let mut warnings = Vec::new();

        let row_data: Value = match result {
            Ok(row) => {
                let username = row.username.as_deref().unwrap_or("").trim().to_string();
                let school_name = row.school_name.as_deref().unwrap_or("").trim().to_string();
                let school_year = row.school_year.as_deref().unwrap_or("").trim().to_string();
                let month = row.month.as_deref().unwrap_or("").trim().to_string();

                if username.is_empty() {
                    errors.push("username is required".to_string());
                }
                if school_name.is_empty() {
                    errors.push("school_name is required".to_string());
                }
                if school_year.is_empty() {
                    errors.push("school_year is required".to_string());
                }
                if month.is_empty() {
                    errors.push("month is required".to_string());
                }

                if errors.is_empty() {
                    match resolve_user_id(db, &username).await {
                        Ok(Some(student_id)) => {
                            match resolve_school_history_id(
                                db,
                                student_id,
                                &school_name,
                                &school_year,
                            )
                            .await
                            {
                                Ok(Some(history_id)) => {
                                    // Check for duplicate attendance
                                    let existing = previous_school_attendance::Entity::find()
                                        .filter(
                                            previous_school_attendance::Column::StudentId
                                                .eq(student_id),
                                        )
                                        .filter(
                                            previous_school_attendance::Column::SchoolHistoryId
                                                .eq(history_id),
                                        )
                                        .filter(
                                            previous_school_attendance::Column::SchoolYear
                                                .eq(&school_year),
                                        )
                                        .filter(
                                            previous_school_attendance::Column::Month.eq(&month),
                                        )
                                        .one(db)
                                        .await
                                        .map_err(|e| {
                                            AppError::InternalServerError(format!(
                                                "Database error: {}",
                                                e
                                            ))
                                        });

                                    match existing {
                                        Ok(Some(_)) => warnings
                                            .push("Record exists and will be updated".to_string()),
                                        Ok(None) => {}
                                        Err(e) => errors.push(format!("Database error: {}", e)),
                                    }
                                }
                                Ok(None) => errors.push("School history not found".to_string()),
                                Err(e) => errors.push(format!("Database error: {}", e)),
                            }
                        }
                        Ok(None) => errors.push(format!("User '{}' not found", username)),
                        Err(e) => errors.push(format!("Database error: {}", e)),
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

// ── Import Operations ──

pub async fn import_school_history(
    db: &DatabaseConnection,
    rows: &[Value],
) -> AppResult<ImportResultResponse> {
    let mut imported = 0usize;
    let mut errors = Vec::new();

    for (i, row_data) in rows.iter().enumerate() {
        let row: SchoolHistoryCsvRow = match serde_json::from_value(row_data.clone()) {
            Ok(r) => r,
            Err(e) => {
                errors.push(format!("Row {}: parse error: {}", i + 1, e));
                continue;
            }
        };

        let username = row.username.unwrap_or_default().trim().to_string();
        let school_name = row.school_name.unwrap_or_default().trim().to_string();
        let school_year = row.school_year.unwrap_or_default().trim().to_string();
        let grade_level = row.grade_level.unwrap_or_default().trim().to_string();

        let student_id = match resolve_user_id(db, &username).await {
            Ok(Some(id)) => id,
            Ok(None) => {
                errors.push(format!("Row {}: user '{}' not found", i + 1, username));
                continue;
            }
            Err(e) => {
                errors.push(format!("Row {}: {}", i + 1, e));
                continue;
            }
        };

        // Check if existing — upsert
        let existing = resolve_school_history_id(db, student_id, &school_name, &school_year)
            .await
            .unwrap_or(None);

        if let Some(history_id) = existing {
            // Update
            if let Err(e) = ops::update_school_history(
                db,
                history_id,
                Some(school_name),
                None,
                Some(grade_level),
                Some(school_year),
                Some(row.section.filter(|s| !s.trim().is_empty())),
                row.date_from
                    .as_ref()
                    .and_then(|s| {
                        if s.trim().is_empty() {
                            None
                        } else {
                            Some(s.parse::<chrono::NaiveDate>().ok())
                        }
                    })
                    .flatten()
                    .map(Some),
                row.date_to
                    .as_ref()
                    .and_then(|s| {
                        if s.trim().is_empty() {
                            None
                        } else {
                            Some(s.parse::<chrono::NaiveDate>().ok())
                        }
                    })
                    .flatten()
                    .map(Some),
                Some(row.record_type.unwrap_or_else(|| "transferred".to_string())),
            )
            .await
            {
                errors.push(format!("Row {}: failed to update: {}", i + 1, e));
                continue;
            }
        } else {
            // Create
            if let Err(e) = ops::create_school_history(
                db,
                student_id,
                school_name,
                row.school_id.filter(|s| !s.trim().is_empty()),
                grade_level,
                school_year,
                row.section.filter(|s| !s.trim().is_empty()),
                row.date_from.as_deref().and_then(|s| {
                    if s.trim().is_empty() {
                        None
                    } else {
                        s.parse::<chrono::NaiveDate>().ok()
                    }
                }),
                row.date_to.as_deref().and_then(|s| {
                    if s.trim().is_empty() {
                        None
                    } else {
                        s.parse::<chrono::NaiveDate>().ok()
                    }
                }),
                row.record_type.unwrap_or_else(|| "transferred".to_string()),
            )
            .await
            {
                errors.push(format!("Row {}: failed to create: {}", i + 1, e));
                continue;
            }
        }

        imported += 1;
    }

    Ok(ImportResultResponse { imported, errors })
}

pub async fn import_subjects(
    db: &DatabaseConnection,
    rows: &[Value],
) -> AppResult<ImportResultResponse> {
    let mut imported = 0usize;
    let mut errors = Vec::new();

    for (i, row_data) in rows.iter().enumerate() {
        let row: SubjectsCsvRow = match serde_json::from_value(row_data.clone()) {
            Ok(r) => r,
            Err(e) => {
                errors.push(format!("Row {}: parse error: {}", i + 1, e));
                continue;
            }
        };

        let username = row.username.unwrap_or_default().trim().to_string();
        let school_name = row.school_name.unwrap_or_default().trim().to_string();
        let school_year = row.school_year.unwrap_or_default().trim().to_string();
        let subject_name = row.subject_name.unwrap_or_default().trim().to_string();
        let term_type = row
            .term_type
            .unwrap_or_else(|| "quarterly".to_string())
            .trim()
            .to_string();

        let student_id = match resolve_user_id(db, &username).await {
            Ok(Some(id)) => id,
            Ok(None) => {
                errors.push(format!("Row {}: user '{}' not found", i + 1, username));
                continue;
            }
            Err(e) => {
                errors.push(format!("Row {}: {}", i + 1, e));
                continue;
            }
        };

        let history_id =
            match resolve_school_history_id(db, student_id, &school_name, &school_year).await {
                Ok(Some(id)) => id,
                Ok(None) => {
                    errors.push(format!("Row {}: school history not found", i + 1));
                    continue;
                }
                Err(e) => {
                    errors.push(format!("Row {}: {}", i + 1, e));
                    continue;
                }
            };

        let term_grades = vec![
            row.term1_grade,
            row.term2_grade,
            row.term3_grade,
            row.term4_grade,
        ];

        if let Err(e) = ops::upsert_previous_subject(
            db,
            student_id,
            history_id,
            subject_name,
            row.subject_group.filter(|s| !s.trim().is_empty()),
            term_type,
            term_grades,
            row.final_grade,
            row.descriptor.filter(|s| !s.trim().is_empty()),
        )
        .await
        {
            errors.push(format!("Row {}: failed to upsert: {}", i + 1, e));
            continue;
        }

        imported += 1;
    }

    Ok(ImportResultResponse { imported, errors })
}

pub async fn import_attendance(
    db: &DatabaseConnection,
    rows: &[Value],
) -> AppResult<ImportResultResponse> {
    let mut imported = 0usize;
    let mut errors = Vec::new();

    for (i, row_data) in rows.iter().enumerate() {
        let row: AttendanceCsvRow = match serde_json::from_value(row_data.clone()) {
            Ok(r) => r,
            Err(e) => {
                errors.push(format!("Row {}: parse error: {}", i + 1, e));
                continue;
            }
        };

        let username = row.username.unwrap_or_default().trim().to_string();
        let school_name = row.school_name.unwrap_or_default().trim().to_string();
        let school_year = row.school_year.unwrap_or_default().trim().to_string();
        let month = row.month.unwrap_or_default().trim().to_string();

        let student_id = match resolve_user_id(db, &username).await {
            Ok(Some(id)) => id,
            Ok(None) => {
                errors.push(format!("Row {}: user '{}' not found", i + 1, username));
                continue;
            }
            Err(e) => {
                errors.push(format!("Row {}: {}", i + 1, e));
                continue;
            }
        };

        let history_id =
            match resolve_school_history_id(db, student_id, &school_name, &school_year).await {
                Ok(Some(id)) => id,
                Ok(None) => {
                    errors.push(format!("Row {}: school history not found", i + 1));
                    continue;
                }
                Err(e) => {
                    errors.push(format!("Row {}: {}", i + 1, e));
                    continue;
                }
            };

        let school_days = row.school_days.unwrap_or(0);
        let days_present = row.days_present.unwrap_or(0);

        if let Err(e) = ops::upsert_previous_attendance(
            db,
            student_id,
            history_id,
            school_year,
            month,
            school_days,
            days_present,
        )
        .await
        {
            errors.push(format!("Row {}: failed to upsert: {}", i + 1, e));
            continue;
        }

        imported += 1;
    }

    Ok(ImportResultResponse { imported, errors })
}
