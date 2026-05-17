use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;

impl crate::services::assessment::AssessmentService {
    pub async fn save_answers(
        &self,
        submission_id: Uuid,
        request: SaveAnswersRequest,
        student_id: Uuid,
    ) -> AppResult<()> {
        println!("💾 [SERVICE] save_answers() START - submission_id: {}, student_id: {}, answer_count: {}", submission_id, student_id, request.answers.len());

        let submission = self.assessment_repo.find_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.user_id != student_id {
            println!("💾 [SERVICE] save_answers() ERROR - student mismatch");
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.submitted_at.is_some() {
            println!("💾 [SERVICE] save_answers() ERROR - submission already submitted");
            return Err(AppError::BadRequest("Assessment already submitted".to_string()));
        }

        for answer_input in &request.answers {
            let answer = self.assessment_repo
                .upsert_answer(submission_id, answer_input.question_id, answer_input.answer_text.clone())
                .await?;

            if let Some(choice_ids) = &answer_input.selected_choice_ids {
                self.assessment_repo
                    .save_answer_choices(answer.id, choice_ids.clone())
                    .await?;
            }

            if let Some(enum_answers) = &answer_input.enumeration_answers {
                let mut sorted = enum_answers.clone();
                sorted.sort_by_key(|e| e.order_index);

                let slots = self.assessment_repo
                    .find_enumeration_items_for_question(answer_input.question_id)
                    .await?;

                let items: Vec<(Option<Uuid>, String)> = sorted.iter().enumerate()
                    .map(|(i, e)| {
                        let key_id = slots.get(i).map(|(key, _)| key.id);
                        (key_id, e.answer_text.clone())
                    })
                    .collect();

                self.assessment_repo
                    .save_enumeration_answers_linked(answer.id, items)
                    .await?;
            }

            if let Some(answer_text) = &answer_input.answer_text {
                self.assessment_repo
                    .save_answer_text(answer.id, answer_text.clone())
                    .await?;
            }
        }

        println!("💾 [SERVICE] save_answers() SUCCESS - saved {} answers", request.answers.len());

        self.grading_service.grade_submission(submission_id).await?;

        Ok(())
    }
}
