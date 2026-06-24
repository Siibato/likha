use crate::modules::assessment::schema::*;
use crate::utils::error::{AppError, AppResult};
use uuid::Uuid;

impl crate::modules::assessment::service::AssessmentService {
    pub async fn start_assessment(
        &self,
        assessment_id: Uuid,
        student_id: Uuid,
        submission_id: Option<Uuid>,
    ) -> AppResult<StartSubmissionResponse> {
        println!(
            "🚀 [SERVICE] start_assessment() START - assessment_id: {}, student_id: {}",
            assessment_id, student_id
        );

        let assessment = self
            .assessment_repo
            .find_by_id(assessment_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        if !assessment.is_published {
            println!("🚀 [SERVICE] start_assessment() ERROR - assessment not published");
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

        let now = chrono::Utc::now().naive_utc();
        if now < assessment.open_at {
            println!("🚀 [SERVICE] start_assessment() ERROR - assessment not yet open");
            return Err(AppError::BadRequest(
                "Assessment is not yet open".to_string(),
            ));
        }
        if now > assessment.close_at {
            println!("🚀 [SERVICE] start_assessment() ERROR - assessment closed");
            return Err(AppError::BadRequest("Assessment is closed".to_string()));
        }

        let enrolled = self
            .class_repo
            .is_student_enrolled(assessment.class_id, student_id)
            .await?;
        if !enrolled {
            println!("🚀 [SERVICE] start_assessment() ERROR - student not enrolled in class");
            return Err(AppError::Forbidden(
                "You are not enrolled in this class".to_string(),
            ));
        }

        let existing = self
            .assessment_repo
            .find_by_student_and_assessment(student_id, assessment_id)
            .await?;
        if existing.is_some() {
            println!(
                "🚀 [SERVICE] start_assessment() ERROR - already has submission: {:?}",
                existing
            );
            return Err(AppError::BadRequest(
                "You have already started this assessment".to_string(),
            ));
        }

        println!("🚀 [SERVICE] start_assessment() - creating new submission...");
        let submission = self
            .assessment_repo
            .create_submission(assessment_id, student_id, submission_id)
            .await?;
        println!(
            "🚀 [SERVICE] start_assessment() - submission created: id={}, submitted={}",
            submission.id,
            submission.submitted_at.is_some()
        );

        let questions = self
            .assessment_repo
            .find_questions_by_assessment_id(assessment_id)
            .await?;

        let mut student_questions = Vec::new();
        for q in questions {
            let choices = if q.question_type == "multiple_choice" {
                let choices = self
                    .assessment_repo
                    .find_choices_by_question_id(q.id)
                    .await?;
                Some(
                    choices
                        .into_iter()
                        .map(|c| StudentChoiceResponse {
                            id: c.id,
                            choice_text: c.choice_text,
                            order_index: c.order_index,
                        })
                        .collect(),
                )
            } else {
                None
            };

            let (enumeration_count, enumeration_items) = if q.question_type == "enumeration" {
                let items = self
                    .assessment_repo
                    .find_enumeration_items_for_question(q.id)
                    .await?;
                let count = items.len();
                let item_responses: Vec<StudentEnumerationItemResponse> = items
                    .into_iter()
                    .enumerate()
                    .map(|(idx, (key, answers))| StudentEnumerationItemResponse {
                        id: key.id,
                        order_index: idx,
                        acceptable_answers: answers
                            .into_iter()
                            .map(|a| StudentEnumerationAnswerResponse {
                                id: a.id,
                                answer_text: a.answer_text,
                            })
                            .collect(),
                    })
                    .collect();
                (Some(count), Some(item_responses))
            } else {
                (None, None)
            };

            student_questions.push(StudentQuestionResponse {
                id: q.id,
                question_type: q.question_type,
                question_text: q.question_text,
                points: q.points,
                order_index: q.order_index,
                is_multi_select: q.is_multi_select,
                choices,
                enumeration_count,
                enumeration_items,
            });
        }

        Ok(StartSubmissionResponse {
            submission_id: submission.id,
            started_at: submission.started_at.to_string(),
            questions: student_questions,
        })
    }
}
