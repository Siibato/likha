use uuid::Uuid;
use crate::utils::AppResult;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn recalculate_final_score(
        &self,
        submission_id: Uuid,
    ) -> AppResult<f64> {
        let answers = self.assessment_repo.find_answers_by_submission_id(submission_id).await?;
        let final_score: f64 = answers.iter().map(|a| a.points).sum();

        self.assessment_repo
            .update_submission_scores(submission_id, final_score)
            .await?;

        Ok(final_score)
    }
}
