use sea_orm::*;

use crate::utils::{AppError, AppResult};

#[derive(Debug)]
pub struct MelcRow {
    pub id: i64,
    pub subject: String,
    pub grade_level: String,
    pub quarter: Option<i32>,
    pub competency_code: String,
    pub competency_text: String,
    pub domain: Option<String>,
}

pub async fn search_melcs(
    db: &DatabaseConnection,
    subject: Option<&str>,
    grade_level: Option<&str>,
    quarter: Option<i32>,
    query: Option<&str>,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<MelcRow>> {
    let mut sql = String::from(
        "SELECT id, subject, grade_level, quarter, competency_code, competency_text, domain FROM melcs WHERE 1=1",
    );
    let mut params: Vec<sea_orm::Value> = Vec::new();

    if let Some(s) = subject {
        params.push(s.into());
        sql.push_str(&format!(" AND subject = ${}", params.len()));
    }
    if let Some(g) = grade_level {
        params.push(g.into());
        sql.push_str(&format!(" AND grade_level = ${}", params.len()));
    }
    if let Some(q) = quarter {
        params.push(q.into());
        sql.push_str(&format!(" AND (quarter = ${} OR quarter IS NULL)", params.len()));
    }
    if let Some(text) = query {
        let search_term = format!("%{}%", text);
        params.push(search_term.clone().into());
        let idx = params.len();
        params.push(search_term.into());
        sql.push_str(&format!(
            " AND (competency_text LIKE ${} OR competency_code LIKE ${})",
            idx,
            idx + 1
        ));
    }

    params.push(limit.into());
    params.push(offset.into());
    sql.push_str(&format!(
        " ORDER BY grade_level, quarter, competency_code LIMIT ${} OFFSET ${}",
        params.len() - 1,
        params.len()
    ));

    let rows = db
        .query_all(sea_orm::Statement::from_sql_and_values(
            sea_orm::DbBackend::Sqlite,
            &sql,
            params,
        ))
        .await
        .map_err(|e| AppError::InternalServerError(format!("MELCS search error: {}", e)))?;

    let mut results = Vec::new();
    for row in rows {
        results.push(MelcRow {
            id: row.try_get("", "id").unwrap_or(0),
            subject: row.try_get("", "subject").unwrap_or_default(),
            grade_level: row.try_get("", "grade_level").unwrap_or_default(),
            quarter: row.try_get("", "quarter").ok(),
            competency_code: row.try_get("", "competency_code").unwrap_or_default(),
            competency_text: row.try_get("", "competency_text").unwrap_or_default(),
            domain: row.try_get("", "domain").ok(),
        });
    }

    Ok(results)
}
