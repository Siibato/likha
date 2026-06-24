use crate::modules::assessment::schema::*;
use crate::utils::error::{AppError, AppResult};
use crate::utils::fmt_utc;
use entity::question_choices;
use std::collections::HashMap;
use uuid::Uuid;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn get_assessment_detail(
        &self,
        assessment_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssessmentDetailResponse> {
        let assessment = self
            .assessment_repo
            .find_by_id(assessment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self
            .class_repo
            .find_by_id(assessment.class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if role == "student" && !assessment.is_published {
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

        if role == "teacher"
            && !self
                .class_repo
                .is_teacher_of_class(user_id, assessment.class_id)
                .await?
        {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let questions = self
            .assessment_repo
            .find_questions_by_assessment_id(assessment_id)
            .await?;

        let question_ids: Vec<Uuid> = questions.iter().map(|q| q.id).collect();

        // Batch fetch all question-related data in parallel
        let (choices_map, correct_answers_map, enumeration_map) = if question_ids.is_empty() {
            (HashMap::new(), HashMap::new(), HashMap::new())
        } else {
            let mut choices_fut = None;
            let mut correct_answers_fut = None;
            let mut enumeration_fut = None;

            if questions
                .iter()
                .any(|q| q.question_type == "multiple_choice")
            {
                choices_fut = Some(
                    self.assessment_repo
                        .find_choices_by_question_ids(&question_ids),
                );
            }
            if role == "teacher"
                && questions
                    .iter()
                    .any(|q| q.question_type == "identification")
            {
                correct_answers_fut = Some(
                    self.assessment_repo
                        .find_correct_answers_by_question_ids(&question_ids),
                );
            }
            if role == "teacher" && questions.iter().any(|q| q.question_type == "enumeration") {
                enumeration_fut = Some(
                    self.assessment_repo
                        .find_enumeration_items_for_questions(&question_ids),
                );
            }

            let choices_vec = if let Some(fut) = choices_fut {
                fut.await?
            } else {
                vec![]
            };
            let choices: HashMap<Uuid, Vec<question_choices::Model>> =
                choices_vec.into_iter().fold(HashMap::new(), |mut acc, c| {
                    acc.entry(c.question_id).or_default().push(c);
                    acc
                });
            let correct_answers = if let Some(fut) = correct_answers_fut {
                fut.await?
            } else {
                HashMap::new()
            };
            let enumeration = if let Some(fut) = enumeration_fut {
                fut.await?
            } else {
                HashMap::new()
            };

            (choices, correct_answers, enumeration)
        };

        let question_responses: Vec<QuestionResponse> = questions
            .into_iter()
            .map(|q| {
                let choices = if q.question_type == "multiple_choice" {
                    choices_map.get(&q.id).map(|choices| {
                        choices
                            .iter()
                            .map(|c| ChoiceResponse {
                                id: c.id,
                                choice_text: c.choice_text.clone(),
                                is_correct: c.is_correct,
                                order_index: c.order_index,
                            })
                            .collect()
                    })
                } else {
                    None
                };

                let correct_answers = if q.question_type == "identification" && role == "teacher" {
                    correct_answers_map.get(&q.id).map(|answers| {
                        answers
                            .iter()
                            .map(|a| CorrectAnswerResponse {
                                id: a.id,
                                answer_text: a.answer_text.clone(),
                            })
                            .collect()
                    })
                } else {
                    None
                };

                let enumeration_items = if q.question_type == "enumeration" && role == "teacher" {
                    enumeration_map.get(&q.id).map(|items| {
                        items
                            .iter()
                            .enumerate()
                            .map(|(i, (key, answers))| EnumerationItemResponse {
                                id: key.id,
                                order_index: i as i32,
                                acceptable_answers: answers
                                    .iter()
                                    .map(|a| EnumerationItemAnswerResponse {
                                        id: a.id,
                                        answer_text: a.answer_text.clone(),
                                    })
                                    .collect(),
                            })
                            .collect()
                    })
                } else {
                    None
                };

                QuestionResponse {
                    id: q.id,
                    question_type: q.question_type,
                    question_text: q.question_text,
                    points: q.points,
                    order_index: q.order_index,
                    is_multi_select: q.is_multi_select,
                    choices,
                    correct_answers,
                    enumeration_items,
                    tos_competency_id: q.tos_competency_id.map(|u| u.to_string()),
                    cognitive_level: q.cognitive_level,
                }
            })
            .collect();

        Ok(AssessmentDetailResponse {
            id: assessment.id,
            class_id: assessment.class_id,
            title: assessment.title,
            description: assessment.description,
            time_limit_minutes: assessment.time_limit_minutes,
            open_at: fmt_utc(assessment.open_at),
            close_at: fmt_utc(assessment.close_at),
            show_results_immediately: assessment.show_results_immediately,
            results_released: assessment.results_released,
            is_published: assessment.is_published,
            order_index: assessment.order_index,
            total_points: assessment.total_points,
            term_number: assessment.term_number,
            component: assessment.component.clone(),
            tos_id: assessment.tos_id.map(|u| u.to_string()),
            questions: question_responses,
            created_at: fmt_utc(assessment.created_at),
            updated_at: fmt_utc(assessment.updated_at),
        })
    }
}
