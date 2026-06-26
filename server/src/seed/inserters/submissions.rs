use chrono::Utc;
use sea_orm::{DatabaseConnection, EntityTrait, Set};

use crate::seed::specs::{AssessmentSubmissionSpec, AssignmentSubmissionSpec};
use crate::seed::tools::seed_id;
use crate::utils::AppError;
use ::entity::{
    assessment_submissions, assignment_submissions, submission_answer_items,
    submission_answers,
};

const CHUNK_SIZE: usize = 100;

pub async fn insert_assessment_submissions(
    db: &DatabaseConnection,
    specs: &[AssessmentSubmissionSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let now = Utc::now().naive_utc();

    // Phase 1: Batch insert all assessment_submissions
    let sub_models: Vec<assessment_submissions::ActiveModel> = specs
        .iter()
        .map(|spec| assessment_submissions::ActiveModel {
            id: Set(spec.id),
            assessment_id: Set(spec.assessment_id),
            user_id: Set(spec.student_id),
            started_at: Set(spec.started_at),
            submitted_at: Set(spec.submitted_at),
            total_points: Set(spec.total_points),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        })
        .collect();

    for chunk in sub_models.chunks(CHUNK_SIZE) {
        assessment_submissions::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!(
                    "Failed to batch insert assessment submissions: {}",
                    e
                ))
            })?;
    }

    // Phase 2: Collect all submission_answers and submission_answer_items
    let mut answer_models: Vec<submission_answers::ActiveModel> = Vec::new();
    let mut item_models: Vec<submission_answer_items::ActiveModel> = Vec::new();

    for spec in specs {
        for answer in &spec.answers {
            let answer_id = seed_id(
                "submission_answers",
                &format!("{}_{}", spec.id, answer.question_id),
            );

            answer_models.push(submission_answers::ActiveModel {
                id: Set(answer_id),
                submission_id: Set(spec.id),
                question_id: Set(answer.question_id),
                points: Set(answer.points),
                overridden_by: Set(None),
                overridden_at: Set(None),
                updated_at: Set(now),
            });

            // Answer items for selected choices
            for &choice_id in &answer.choice_ids {
                let item_id = seed_id(
                    "submission_answer_items",
                    &format!("{}_{}", answer_id, choice_id),
                );
                item_models.push(submission_answer_items::ActiveModel {
                    id: Set(item_id),
                    submission_answer_id: Set(answer_id),
                    answer_key_id: Set(None),
                    choice_id: Set(Some(choice_id)),
                    answer_text: Set(None),
                    is_correct: Set(answer.is_correct.unwrap_or(false)),
                    updated_at: Set(now),
                });
            }

            // Answer items for text answers
            if let Some(text) = &answer.text {
                let item_id =
                    seed_id("submission_answer_items", &format!("{}_text", answer_id));
                item_models.push(submission_answer_items::ActiveModel {
                    id: Set(item_id),
                    submission_answer_id: Set(answer_id),
                    answer_key_id: Set(None),
                    choice_id: Set(None),
                    answer_text: Set(Some(text.clone())),
                    is_correct: Set(false),
                    updated_at: Set(now),
                });
            }
        }
    }

    // Phase 3: Batch insert all submission_answers
    for chunk in answer_models.chunks(CHUNK_SIZE) {
        submission_answers::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!(
                    "Failed to batch insert submission answers: {}",
                    e
                ))
            })?;
    }

    // Phase 4: Batch insert all submission_answer_items
    for chunk in item_models.chunks(CHUNK_SIZE) {
        submission_answer_items::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!(
                    "Failed to batch insert answer items: {}",
                    e
                ))
            })?;
    }

    Ok(())
}

pub async fn insert_assignment_submissions(
    db: &DatabaseConnection,
    specs: &[AssignmentSubmissionSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let now = Utc::now().naive_utc();

    let models: Vec<assignment_submissions::ActiveModel> = specs
        .iter()
        .map(|spec| {
            let is_graded = spec.points.is_some()
                && spec.feedback.is_some()
                && spec.graded_by.is_some();
            assignment_submissions::ActiveModel {
                id: Set(spec.id),
                assignment_id: Set(spec.assignment_id),
                student_id: Set(spec.student_id),
                status: Set(if is_graded {
                    "graded".to_string()
                } else {
                    spec.status.clone()
                }),
                text_content: Set(spec.text.clone()),
                submitted_at: Set(Some(spec.submitted_at)),
                points: Set(spec.points),
                graded_by: Set(spec.graded_by),
                feedback: Set(spec.feedback.clone()),
                graded_at: Set(spec.graded_at),
                created_at: Set(now),
                updated_at: Set(now),
                deleted_at: Set(None),
            }
        })
        .collect();

    for chunk in models.chunks(CHUNK_SIZE) {
        assignment_submissions::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!(
                    "Failed to batch insert assignment submissions: {}",
                    e
                ))
            })?;
    }

    Ok(())
}
