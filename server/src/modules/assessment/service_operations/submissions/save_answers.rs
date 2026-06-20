use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
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
                let question_choices = self.assessment_repo
                    .find_choices_by_question_id(answer_input.question_id)
                    .await?;
                let correct_ids: std::collections::HashSet<Uuid> = question_choices
                    .iter()
                    .filter(|c| c.is_correct)
                    .map(|c| c.id)
                    .collect();
                let choices_with_correctness: Vec<(Uuid, bool)> = choice_ids
                    .iter()
                    .map(|&cid| (cid, correct_ids.contains(&cid)))
                    .collect();
                self.assessment_repo
                    .save_answer_choices(answer.id, choices_with_correctness)
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

        self.grade_submission(submission_id).await?;

        Ok(())
    }
}
