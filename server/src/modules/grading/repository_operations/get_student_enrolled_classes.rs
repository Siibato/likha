use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};
use super::StudentEnrolledClass;

pub async fn get_student_enrolled_classes(
    db: &DatabaseConnection,
    student_id: Uuid,
    school_year: Option<&str>,
) -> AppResult<Vec<StudentEnrolledClass>> {
    let mut sql = String::from(
        r#"
        SELECT c.id, c.title, c.school_year
        FROM classes c
        JOIN class_participants cp ON cp.class_id = c.id
        WHERE cp.user_id = $1
          AND cp.removed_at IS NULL
          AND c.deleted_at IS NULL
          AND c.is_advisory = 0
        "#,
    );
    let mut params: Vec<sea_orm::Value> = vec![student_id.into()];

    if let Some(sy) = school_year {
        params.push(sy.into());
        sql.push_str(&format!(" AND c.school_year = ${}", params.len()));
    }

    sql.push_str(" ORDER BY c.title");

    let rows = db
        .query_all(sea_orm::Statement::from_sql_and_values(
            sea_orm::DbBackend::Sqlite,
            &sql,
            params,
        ))
        .await
        .map_err(|e| AppError::InternalServerError(format!("Failed to get student classes: {}", e)))?;

    let mut results = Vec::new();
    for row in rows {
        results.push(StudentEnrolledClass {
            class_id: row.try_get("", "id").unwrap_or_default(),
            title: row.try_get("", "title").unwrap_or_default(),
            school_year: row.try_get("", "school_year").ok(),
        });
    }

    Ok(results)
}
