use sea_orm::{ActiveModelTrait, DatabaseConnection, EntityTrait, Set};

use crate::modules::assessment::repository::AssessmentRepository;
use crate::modules::assignment::repository::AssignmentRepository;
use crate::seed::specs::{AssessmentSubmissionSpec, AssignmentSubmissionSpec};
use crate::utils::AppError;
use ::entity::{assessment_submissions, assignment_submissions};

pub async fn insert_assessment_submissions(
    db: &DatabaseConnection,
    specs: &[AssessmentSubmissionSpec],
) -> Result<(), AppError> {
    let repo = AssessmentRepository::new(db.clone());

    for spec in specs {
        repo.create_submission(spec.assessment_id, spec.student_id, Some(spec.id))
            .await?;

        let sub = assessment_submissions::Entity::find_by_id(spec.id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?
            .ok_or_else(|| AppError::NotFound(format!("Submission {} not found", spec.id)))?;

        let mut sam: assessment_submissions::ActiveModel = sub.into();
        sam.started_at = Set(spec.started_at);
        sam.submitted_at = Set(spec.submitted_at);
        sam.update(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

        for answer in &spec.answers {
            let answer_record = repo
                .upsert_answer(spec.id, answer.question_id, None)
                .await?;

            if !answer.choice_ids.is_empty() {
                let question_choices = repo
                    .find_choices_by_question_id(answer.question_id)
                    .await?;
                let correct_ids: std::collections::HashSet<uuid::Uuid> = question_choices
                    .iter()
                    .filter(|c| c.is_correct)
                    .map(|c| c.id)
                    .collect();
                let choices_with_correctness: Vec<(uuid::Uuid, bool)> = answer
                    .choice_ids
                    .iter()
                    .map(|&cid| (cid, correct_ids.contains(&cid)))
                    .collect();
                repo.save_answer_choices(answer_record.id, choices_with_correctness)
                    .await?;
            }

            if let Some(text) = &answer.text {
                repo.save_answer_text(answer_record.id, text.clone()).await?;
            }

            repo.update_answer_grade(
                answer_record.id,
                answer.is_correct,
                answer.points,
            )
            .await?;
        }

        if spec.submitted_at.is_some() {
            repo.mark_submitted(spec.id).await?;
            repo.update_submission_scores(spec.id, spec.total_points)
                .await?;
        }
    }

    Ok(())
}

pub async fn insert_assignment_submissions(
    db: &DatabaseConnection,
    specs: &[AssignmentSubmissionSpec],
) -> Result<(), AppError> {
    let repo = AssignmentRepository::new(db.clone());

    for spec in specs {
        repo.create_submission(spec.assignment_id, spec.student_id, Some(spec.id))
            .await?;

        if let Some(text) = &spec.text {
            repo.update_submission_text(spec.id, Some(text.clone()))
                .await?;
        }

        repo.update_submission_status(spec.id, &spec.status)
            .await?;

        if let (Some(points), Some(feedback), Some(graded_by)) =
            (spec.points, &spec.feedback, spec.graded_by)
        {
            repo.grade_submission(spec.id, points, Some(feedback.clone()), Some(graded_by))
                .await?;
        }

        let sub = assignment_submissions::Entity::find_by_id(spec.id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?
            .ok_or_else(|| AppError::NotFound(format!("Submission {} not found", spec.id)))?;

        let mut sam: assignment_submissions::ActiveModel = sub.into();
        sam.submitted_at = Set(Some(spec.submitted_at));
        if let Some(graded_at) = spec.graded_at {
            sam.graded_at = Set(Some(graded_at));
        }
        sam.update(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
