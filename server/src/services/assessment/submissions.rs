use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;
use crate::services::grading::GradingService;

impl super::AssessmentService {
    pub async fn start_assessment(
        &self,
        assessment_id: Uuid,
        student_id: Uuid,
        submission_id: Option<Uuid>,
    ) -> AppResult<StartSubmissionResponse> {
        println!("🚀 [SERVICE] start_assessment() START - assessment_id: {}, student_id: {}", assessment_id, student_id);

        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        if !assessment.is_published {
            println!("🚀 [SERVICE] start_assessment() ERROR - assessment not published");
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

        let now = chrono::Utc::now().naive_utc();
        if now < assessment.open_at {
            println!("🚀 [SERVICE] start_assessment() ERROR - assessment not yet open");
            return Err(AppError::BadRequest("Assessment is not yet open".to_string()));
        }
        if now > assessment.close_at {
            println!("🚀 [SERVICE] start_assessment() ERROR - assessment closed");
            return Err(AppError::BadRequest("Assessment is closed".to_string()));
        }

        let enrolled = self.class_repo
            .is_student_enrolled(assessment.class_id, student_id).await?;
        if !enrolled {
            println!("🚀 [SERVICE] start_assessment() ERROR - student not enrolled in class");
            return Err(AppError::Forbidden("You are not enrolled in this class".to_string()));
        }

        let existing = self.submission_repo
            .find_by_student_and_assessment(student_id, assessment_id).await?;
        if existing.is_some() {
            println!("🚀 [SERVICE] start_assessment() ERROR - already has submission: {:?}", existing);
            return Err(AppError::BadRequest("You have already started this assessment".to_string()));
        }

        println!("🚀 [SERVICE] start_assessment() - creating new submission...");
        let submission = self.submission_repo
            .create_submission(assessment_id, student_id, submission_id).await?;
        println!("🚀 [SERVICE] start_assessment() - submission created: id={}, submitted={}", submission.id, submission.submitted_at.is_some());

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        let mut student_questions = Vec::new();
        for q in questions {
            let choices = if q.question_type == "multiple_choice" {
                let choices = self.assessment_repo
                    .find_choices_by_question_id(q.id).await?;
                Some(
                    choices.into_iter().map(|c| StudentChoiceResponse {
                        id: c.id,
                        choice_text: c.choice_text,
                        order_index: c.order_index,
                    }).collect()
                )
            } else {
                None
            };

            let (enumeration_count, enumeration_items) = if q.question_type == "enumeration" {
                let items = self.assessment_repo.find_enumeration_items_for_question(q.id).await?;
                let count = items.len();
                let item_responses: Vec<StudentEnumerationItemResponse> = items
                    .into_iter()
                    .enumerate()
                    .map(|(idx, (key, answers))| StudentEnumerationItemResponse {
                        id: key.id,
                        order_index: idx,
                        acceptable_answers: answers.into_iter().map(|a| StudentEnumerationAnswerResponse {
                            id: a.id,
                            answer_text: a.answer_text,
                        }).collect(),
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

    pub async fn save_answers(
        &self,
        submission_id: Uuid,
        request: SaveAnswersRequest,
        student_id: Uuid,
    ) -> AppResult<()> {
        println!("💾 [SERVICE] save_answers() START - submission_id: {}, student_id: {}, answer_count: {}", submission_id, student_id, request.answers.len());

        let submission = self.submission_repo.find_by_id(submission_id).await?
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
            let answer = self.submission_repo
                .upsert_answer(submission_id, answer_input.question_id, answer_input.answer_text.clone())
                .await?;

            if let Some(choice_ids) = &answer_input.selected_choice_ids {
                self.submission_repo
                    .save_answer_choices(answer.id, choice_ids.clone())
                    .await?;
            }

            if let Some(enum_answers) = &answer_input.enumeration_answers {
                // Sort by order_index to maintain consistent slot ordering
                let mut sorted = enum_answers.clone();
                sorted.sort_by_key(|e| e.order_index);

                // Look up the enumeration slots for this question
                let slots = self.assessment_repo
                    .find_enumeration_items_for_question(answer_input.question_id)
                    .await?;

                // Link each answer to its corresponding answer_key (slot) by position
                let items: Vec<(Option<Uuid>, String)> = sorted.iter().enumerate()
                    .map(|(i, e)| {
                        let key_id = slots.get(i).map(|(key, _)| key.id);
                        (key_id, e.answer_text.clone())
                    })
                    .collect();

                self.submission_repo
                    .save_enumeration_answers_linked(answer.id, items)
                    .await?;
            }

            if let Some(answer_text) = &answer_input.answer_text {
                // Identification: save text to answer items
                self.submission_repo
                    .save_answer_text(answer.id, answer_text.clone())
                    .await?;
            }
        }

        println!("💾 [SERVICE] save_answers() SUCCESS - saved {} answers", request.answers.len());

        // Auto-grade immediately after saving answers
        GradingService::grade_submission(submission_id, &self.assessment_repo, &self.submission_repo).await?;

        Ok(())
    }

    pub async fn submit_assessment(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<SubmissionSummaryResponse> {
        println!("📤 [SERVICE] submit_assessment() START - submission_id: {}, student_id: {}", submission_id, student_id);

        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        println!("📤 [SERVICE] submit_assessment() - submission found: submitted_at={:?}, assessment_id={}",
            submission.submitted_at, submission.assessment_id);

        if submission.user_id != student_id {
            println!("📤 [SERVICE] submit_assessment() ERROR - student mismatch: expected {}, got {}", submission.user_id, student_id);
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.submitted_at.is_some() {
            println!("📤 [SERVICE] submit_assessment() ERROR - already submitted at {:?}", submission.submitted_at);
            return Err(AppError::BadRequest("Assessment already submitted".to_string()));
        }

        println!("📤 [SERVICE] submit_assessment() - grading submission...");
        let (auto_score, final_score) = GradingService::grade_submission(
            submission_id,
            &self.assessment_repo,
            &self.submission_repo,
        ).await?;
        println!("📤 [SERVICE] submit_assessment() - grading complete: auto_score={}, final_score={}", auto_score, final_score);

        println!("📤 [SERVICE] submit_assessment() - marking as submitted...");
        let submitted = self.submission_repo.mark_submitted(submission_id).await?;

        println!("📤 [SERVICE] submit_assessment() - mark_submitted() returned: submitted_at={:?}",
            submitted.submitted_at);

        let student = self.user_repo.find_by_id(student_id).await?
            .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

        let response = SubmissionSummaryResponse {
            id: submitted.id,
            student_id: submitted.user_id,
            student_name: student.full_name,
            student_username: student.username,
            started_at: submitted.started_at.to_string(),
            submitted_at: submitted.submitted_at.map(|dt| dt.to_string()),
            total_points: submitted.total_points,
        };

        Ok(response)
    }
}