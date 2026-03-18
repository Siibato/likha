use chrono::NaiveDateTime;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;
use entity::assessment_questions;

impl super::AssessmentService {
    pub fn parse_datetime(s: &str) -> AppResult<NaiveDateTime> {
        NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S")
            .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%d %H:%M:%S"))
            .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.f"))
            .map_err(|_| AppError::BadRequest(format!(
                "Invalid datetime format: {}. Use YYYY-MM-DDTHH:MM:SS", s
            )))
    }

    pub async fn build_question_response(
        &self,
        question: &assessment_questions::Model,
        role: &str,
    ) -> AppResult<QuestionResponse> {
        let choices = if question.question_type == "multiple_choice" {
            let choices = self.assessment_repo
                .find_choices_by_question_id(question.id).await?;
            Some(
                choices.into_iter().map(|c| ChoiceResponse {
                    id: c.id,
                    choice_text: c.choice_text,
                    is_correct: c.is_correct,
                    order_index: c.order_index,
                }).collect()
            )
        } else {
            None
        };

        let correct_answers = if question.question_type == "identification" && role == "teacher" {
            let answers = self.assessment_repo
                .find_correct_answers_by_question_id(question.id).await?;
            Some(
                answers.into_iter().map(|a| CorrectAnswerResponse {
                    id: a.id,
                    answer_text: a.answer_text,
                }).collect()
            )
        } else {
            None
        };

        let enumeration_items = if question.question_type == "enumeration" && role == "teacher" {
            let items = self.assessment_repo
                .find_enumeration_items_for_question(question.id).await?;
            Some(
                items.into_iter().enumerate().map(|(i, (key, answers))| EnumerationItemResponse {
                    id: key.id,
                    order_index: i as i32,
                    acceptable_answers: answers.into_iter().map(|a| EnumerationItemAnswerResponse {
                        id: a.id,
                        answer_text: a.answer_text,
                    }).collect(),
                }).collect()
            )
        } else {
            None
        };

        Ok(QuestionResponse {
            id: question.id,
            question_type: question.question_type.clone(),
            question_text: question.question_text.clone(),
            points: question.points,
            order_index: question.order_index,
            is_multi_select: question.is_multi_select,
            choices,
            correct_answers,
            enumeration_items,
        })
    }
}