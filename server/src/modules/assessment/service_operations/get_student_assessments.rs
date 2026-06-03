use uuid::Uuid;
use crate::utils::AppResult;
use crate::utils::fmt_utc;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn get_student_assessments(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<crate::modules::tasks::schema::StudentAssessmentListItem>> {
        let assessments = self
            .assessment_repo
            .find_published_by_class_id(class_id)
            .await?;

        let mut items = Vec::new();
        for a in assessments {
            let submission = self
                .assessment_repo
                .find_by_student_and_assessment(student_id, a.id)
                .await?;

            items.push(crate::modules::tasks::schema::StudentAssessmentListItem {
                id: a.id,
                title: a.title,
                total_points: a.total_points,
                open_at: fmt_utc(a.open_at),
                close_at: fmt_utc(a.close_at),
                time_limit_minutes: a.time_limit_minutes,
                is_submitted: submission.map(|s| s.submitted_at.is_some()),
            });
        }

        Ok(items)
    }
}
