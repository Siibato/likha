use crate::utils::AppResult;
use crate::schema::assessment_schema::*;

impl crate::services::assessment::AssessmentService {
    pub(super) async fn add_question_type_data(
        &self,
        question: &entity::assessment_questions::Model,
        request: &AddQuestionRequest,
    ) -> AppResult<()> {
        match request.question_type.as_str() {
            "multiple_choice" => {
                if let Some(choices) = &request.choices {
                    for choice in choices {
                        self.assessment_repo.add_choice(
                            question.id,
                            choice.choice_text.clone(),
                            choice.is_correct,
                            choice.order_index,
                        ).await?;
                    }
                }
            }
            "identification" => {
                if let Some(answers) = &request.correct_answers {
                    for answer in answers {
                        self.assessment_repo.add_correct_answer(question.id, answer.clone()).await?;
                    }
                }
            }
            "enumeration" => {
                if let Some(items) = &request.enumeration_items {
                    for item in items {
                        self.assessment_repo
                            .add_enumeration_item(question.id, item.acceptable_answers.clone())
                            .await?;
                    }
                }
            }
            "essay" => {}
            _ => {}
        }
        Ok(())
    }
}
