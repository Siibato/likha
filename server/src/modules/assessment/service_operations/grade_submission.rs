use uuid::Uuid;
use crate::utils::AppResult;
use crate::modules::assessment::helpers::graders::{multiple_choice, identification, enumeration};

impl crate::modules::assessment::service::AssessmentService {
    pub async fn grade_submission(
        &self,
        submission_id: Uuid,
    ) -> AppResult<(f64, f64)> {
        let answers = self.assessment_repo.find_answers_by_submission_id(submission_id).await?;
        let mut auto_score = 0.0_f64;

        for answer in &answers {
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
                    multiple_choice::grade_multiple_choice(
                        answer.id,
                        question.id,
                        question.points,
                        question.is_multi_select,
                        &self.assessment_repo,
                        &self.assessment_repo,
                    )
                    .await?
                }
                "identification" => {
                    let items = self.assessment_repo.find_enumeration_answers(answer.id).await?;
                    let answer_text = items.into_iter().next();
                    identification::grade_identification(
                        &answer_text,
                        question.id,
                        question.points,
                        &self.assessment_repo,
                    )
                    .await?
                }
                "enumeration" => {
                    enumeration::grade_enumeration(
                        answer.id,
                        question.id,
                        question.points,
                        &self.assessment_repo,
                        &self.assessment_repo,
                    )
                    .await?
                }
                "essay" => (false, 0.0),
                _ => (false, 0.0),
            };

            self.assessment_repo
                .update_answer_grade(answer.id, Some(is_correct), points_awarded)
                .await?;

            auto_score += points_awarded;
        }

        self.assessment_repo
            .update_submission_scores(submission_id, auto_score)
            .await?;

        Ok((auto_score, auto_score))
    }
}
