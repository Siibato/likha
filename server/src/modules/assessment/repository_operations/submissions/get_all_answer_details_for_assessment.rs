use sea_orm::*;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};

#[derive(Debug)]
pub struct AnswerDetail {
    pub student_id: Uuid,
    pub submission_total_points: f64,
    pub question_id: Uuid,
    pub answer_points: f64,
    pub choice_id: Option<Uuid>,
    pub item_is_correct: bool,
}

pub async fn get_all_answer_details_for_assessment(
    db: &DatabaseConnection,
    assessment_id: Uuid,
) -> AppResult<Vec<AnswerDetail>> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            DbBackend::Sqlite,
            r#"
            SELECT
                s.user_id,
                s.total_points,
                sa.question_id,
                sa.points,
                sai.choice_id,
                sai.is_correct
            FROM assessment_submissions s
            LEFT JOIN submission_answers sa ON sa.submission_id = s.id
            LEFT JOIN submission_answer_items sai ON sai.submission_answer_id = sa.id
            WHERE s.assessment_id = ?
              AND s.submitted_at IS NOT NULL
              AND s.deleted_at IS NULL
            ORDER BY s.total_points DESC, sa.question_id
            "#,
            [assessment_id.into()],
        ))
        .await
        .map_err(|e| {
            AppError::InternalServerError(format!("Failed to query answer details: {}", e))
        })?;

    let mut details = Vec::new();
    for row in rows {
        let student_id: String = row.try_get("", "user_id").unwrap_or_default();
        let submission_total_points: f64 = row.try_get("", "total_points").unwrap_or(0.0);
        let question_id: Option<String> = row.try_get("", "question_id").ok();
        let answer_points: f64 = row.try_get("", "points").unwrap_or(0.0);
        let choice_id: Option<String> = row.try_get("", "choice_id").ok();
        let item_is_correct: bool = row.try_get("", "is_correct").unwrap_or(false);

        let student_uuid = match Uuid::parse_str(&student_id) {
            Ok(uuid) => uuid,
            Err(_) => {
                tracing::warn!("Skipping row with unparseable student_id: {}", student_id);
                continue;
            }
        };

        let question_uuid = match question_id {
            Some(ref qid) => match Uuid::parse_str(qid) {
                Ok(uuid) => Some(uuid),
                Err(_) => {
                    tracing::warn!("Skipping row with unparseable question_id: {}", qid);
                    continue;
                }
            },
            None => None,
        };

        details.push(AnswerDetail {
            student_id: student_uuid,
            submission_total_points,
            question_id: question_uuid.unwrap_or_default(),
            answer_points,
            choice_id: choice_id.and_then(|s| Uuid::parse_str(&s).ok()),
            item_is_correct,
        });
    }

    Ok(details)
}
