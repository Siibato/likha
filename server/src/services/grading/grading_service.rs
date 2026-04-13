use sea_orm::DatabaseConnection;
use uuid::Uuid;
use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::submission_repository::SubmissionRepository;
use crate::utils::AppResult;

pub struct GradingService {
    pub assessment_repo: AssessmentRepository,
    pub submission_repo: SubmissionRepository,
    pub db: DatabaseConnection,
}

impl GradingService {
    pub fn new(db: DatabaseConnection) -> Self {
        let db_clone = db.clone();
        Self {
            assessment_repo: AssessmentRepository::new(db.clone()),
            submission_repo: SubmissionRepository::new(db),
            db: db_clone,
        }
    }

    pub async fn grade_submission(
        &self,
        submission_id: Uuid,
    ) -> AppResult<(f64, f64)> {
        let answers = self.submission_repo.find_answers_by_submission_id(submission_id).await?;
        let mut auto_score = 0.0_f64;

        for answer in &answers {
            // Skip re-grading teacher-overridden answers; keep their existing points
            if answer.overridden_at.is_some() {
                auto_score += answer.points;
                continue;
            }

            let question = self.assessment_repo
                .find_question_by_id(answer.question_id)
                .await?;

            let question = match question {
                Some(q) => q,
                None => continue,
            };

            let (is_correct, points_awarded) = match question.question_type.as_str() {
                "multiple_choice" => {
                    super::multiple_choice::grade_multiple_choice(
                        answer.id,
                        question.id,
                        question.points,
                        question.is_multi_select,
                        &self.assessment_repo,
                        &self.submission_repo,
                    )
                    .await?
                }
                "identification" => {
                    let items = self.submission_repo.find_enumeration_answers(answer.id).await?;
                    let answer_text = items.into_iter().next();
                    super::identification::grade_identification(
                        &answer_text,
                        question.id,
                        question.points,
                        &self.assessment_repo,
                    )
                    .await?
                }
                "enumeration" => {
                    super::enumeration::grade_enumeration(
                        answer.id,
                        question.id,
                        question.points,
                        &self.assessment_repo,
                        &self.submission_repo,
                    )
                    .await?
                }
                // Essays are graded manually by the teacher; auto-grade assigns 0
                "essay" => (false, 0.0),
                _ => (false, 0.0),
            };

            self.submission_repo
                .update_answer_grade(answer.id, Some(is_correct), points_awarded)
                .await?;

            auto_score += points_awarded;
        }

        self.submission_repo
            .update_submission_scores(submission_id, auto_score)
            .await?;

        Ok((auto_score, auto_score))
    }

    pub async fn recalculate_final_score(
        &self,
        submission_id: Uuid,
    ) -> AppResult<f64> {
        let answers = self.submission_repo.find_answers_by_submission_id(submission_id).await?;
        let final_score: f64 = answers.iter().map(|a| a.points).sum();

        self.submission_repo
            .update_submission_scores(submission_id, final_score)
            .await?;

        Ok(final_score)
    }
}