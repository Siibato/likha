use crate::db::repositories::tos_repository::TosRepository;
use crate::schema::tos_schema::*;
use crate::utils::AppResult;

pub async fn search_melcs(
    tos_repo: &TosRepository,
    subject: Option<&str>,
    grade_level: Option<&str>,
    quarter: Option<i32>,
    query: Option<&str>,
    limit: i64,
    offset: i64,
) -> AppResult<MelcSearchResponse> {
    let rows = tos_repo
        .search_melcs(subject, grade_level, quarter, query, limit, offset)
        .await?;

    Ok(MelcSearchResponse {
        melcs: rows
            .into_iter()
            .map(|r| MelcEntry {
                id: r.id,
                subject: r.subject,
                grade_level: r.grade_level,
                quarter: r.quarter,
                competency_code: r.competency_code,
                competency_text: r.competency_text,
                domain: r.domain,
            })
            .collect(),
    })
}
