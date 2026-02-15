use chrono::NaiveDateTime;
use sea_orm::DatabaseConnection;
use uuid::Uuid;
use md5;

use crate::db::repositories::assessment_repository::AssessmentRepository;
use crate::db::repositories::change_log_repository::ChangeLogRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::submission_repository::SubmissionRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::schema::assessment_schema::*;
use crate::services::grading_service::GradingService;
use crate::utils::error::{AppError, AppResult};

pub struct AssessmentService {
    assessment_repo: AssessmentRepository,
    submission_repo: SubmissionRepository,
    class_repo: ClassRepository,
    user_repo: UserRepository,
    change_log_repo: ChangeLogRepository,
}

impl AssessmentService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            assessment_repo: AssessmentRepository::new(db.clone()),
            submission_repo: SubmissionRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db.clone()),
            change_log_repo: ChangeLogRepository::new(db),
        }
    }

    fn parse_datetime(s: &str) -> AppResult<NaiveDateTime> {
        NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S")
            .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%d %H:%M:%S"))
            .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.f"))
            .map_err(|_| AppError::BadRequest(format!("Invalid datetime format: {}. Use YYYY-MM-DDTHH:MM:SS", s)))
    }

    // ===== ASSESSMENT CRUD =====

    pub async fn create_assessment(
        &self,
        class_id: Uuid,
        request: CreateAssessmentRequest,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let class = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("You can only create assessments in your own classes".to_string()));
        }

        if request.title.trim().is_empty() {
            return Err(AppError::BadRequest("Title is required".to_string()));
        }

        let open_at = Self::parse_datetime(&request.open_at)?;
        let close_at = Self::parse_datetime(&request.close_at)?;

        if close_at <= open_at {
            return Err(AppError::BadRequest("Close date must be after open date".to_string()));
        }

        let assessment = self.assessment_repo.create_assessment(
            class_id,
            request.title.trim().to_string(),
            request.description,
            request.time_limit_minutes,
            open_at,
            close_at,
            request.show_results_immediately.unwrap_or(true),
        ).await?;

        // Log change for sync
        let _ = self.change_log_repo.log_change(
            "assessment",
            assessment.id,
            "create",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "id": assessment.id,
                "class_id": assessment.class_id,
                "title": assessment.title,
                "description": assessment.description,
                "time_limit_minutes": assessment.time_limit_minutes,
                "open_at": assessment.open_at.to_string(),
                "close_at": assessment.close_at.to_string(),
                "show_results_immediately": assessment.show_results_immediately,
                "is_published": assessment.is_published,
                "created_at": assessment.created_at.to_string(),
                "updated_at": assessment.updated_at.to_string(),
            })).unwrap_or_default()),
        ).await;

        Ok(AssessmentResponse {
            id: assessment.id,
            class_id: assessment.class_id,
            title: assessment.title,
            description: assessment.description,
            time_limit_minutes: assessment.time_limit_minutes,
            open_at: assessment.open_at.to_string(),
            close_at: assessment.close_at.to_string(),
            show_results_immediately: assessment.show_results_immediately,
            results_released: assessment.results_released,
            is_published: assessment.is_published,
            total_points: assessment.total_points,
            question_count: 0,
            submission_count: 0,
            created_at: assessment.created_at.to_string(),
            updated_at: assessment.updated_at.to_string(),
        })
    }

    pub async fn get_assessments(
        &self,
        class_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssessmentListResponse> {
        let class = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let assessments = if role == "teacher" && class.teacher_id == user_id {
            self.assessment_repo.find_by_class_id(class_id).await?
        } else {
            self.assessment_repo.find_published_by_class_id(class_id).await?
        };

        let mut responses = Vec::new();
        for a in assessments {
            let question_count = self.assessment_repo
                .find_questions_by_assessment_id(a.id).await?.len();
            let submission_count = self.submission_repo
                .count_by_assessment_id(a.id).await?;

            responses.push(AssessmentResponse {
                id: a.id,
                class_id: a.class_id,
                title: a.title,
                description: a.description,
                time_limit_minutes: a.time_limit_minutes,
                open_at: a.open_at.to_string(),
                close_at: a.close_at.to_string(),
                show_results_immediately: a.show_results_immediately,
                results_released: a.results_released,
                is_published: a.is_published,
                total_points: a.total_points,
                question_count,
                submission_count,
                created_at: a.created_at.to_string(),
                updated_at: a.updated_at.to_string(),
            });
        }

        Ok(AssessmentListResponse { assessments: responses })
    }

    pub async fn get_assessment_detail(
        &self,
        assessment_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssessmentDetailResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        // Students can only see published assessments
        if role == "student" && !assessment.is_published {
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

        // Teachers can only see their own class assessments
        if role == "teacher" && class.teacher_id != user_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        let mut question_responses = Vec::new();
        for q in questions {
            let question_response = self.build_question_response(&q, role).await?;
            question_responses.push(question_response);
        }

        Ok(AssessmentDetailResponse {
            id: assessment.id,
            class_id: assessment.class_id,
            title: assessment.title,
            description: assessment.description,
            time_limit_minutes: assessment.time_limit_minutes,
            open_at: assessment.open_at.to_string(),
            close_at: assessment.close_at.to_string(),
            show_results_immediately: assessment.show_results_immediately,
            results_released: assessment.results_released,
            is_published: assessment.is_published,
            total_points: assessment.total_points,
            questions: question_responses,
            created_at: assessment.created_at.to_string(),
            updated_at: assessment.updated_at.to_string(),
        })
    }

    pub async fn update_assessment(
        &self,
        assessment_id: Uuid,
        request: UpdateAssessmentRequest,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot edit a published assessment".to_string()));
        }

        let open_at = match &request.open_at {
            Some(s) => Some(Self::parse_datetime(s)?),
            None => None,
        };
        let close_at = match &request.close_at {
            Some(s) => Some(Self::parse_datetime(s)?),
            None => None,
        };

        let updated = self.assessment_repo.update_assessment(
            assessment_id,
            request.title,
            request.description,
            request.time_limit_minutes,
            open_at,
            close_at,
            request.show_results_immediately,
        ).await?;

        let question_count = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?.len();
        let submission_count = self.submission_repo
            .count_by_assessment_id(assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "assessment",
            assessment_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "title": updated.title,
                "description": updated.description,
            })).unwrap_or_default()),
        ).await;

        Ok(AssessmentResponse {
            id: updated.id,
            class_id: updated.class_id,
            title: updated.title,
            description: updated.description,
            time_limit_minutes: updated.time_limit_minutes,
            open_at: updated.open_at.to_string(),
            close_at: updated.close_at.to_string(),
            show_results_immediately: updated.show_results_immediately,
            results_released: updated.results_released,
            is_published: updated.is_published,
            total_points: updated.total_points,
            question_count,
            submission_count,
            created_at: updated.created_at.to_string(),
            updated_at: updated.updated_at.to_string(),
        })
    }

    pub async fn delete_assessment(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submission_count = self.submission_repo.count_by_assessment_id(assessment_id).await?;
        if submission_count > 0 {
            return Err(AppError::BadRequest("Cannot delete assessment with existing submissions".to_string()));
        }

        self.assessment_repo.delete_assessment(assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "assessment",
            assessment_id,
            "delete",
            teacher_id,
            None,
        ).await;

        Ok(())
    }

    pub async fn publish_assessment(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Assessment is already published".to_string()));
        }

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;
        if questions.is_empty() {
            return Err(AppError::BadRequest("Cannot publish assessment with no questions".to_string()));
        }

        self.assessment_repo.update_total_points(assessment_id).await?;
        let published = self.assessment_repo.publish_assessment(assessment_id).await?;

        let question_count = questions.len();
        let submission_count = self.submission_repo.count_by_assessment_id(assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "assessment",
            assessment_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "is_published": true,
            })).unwrap_or_default()),
        ).await;

        Ok(AssessmentResponse {
            id: published.id,
            class_id: published.class_id,
            title: published.title,
            description: published.description,
            time_limit_minutes: published.time_limit_minutes,
            open_at: published.open_at.to_string(),
            close_at: published.close_at.to_string(),
            show_results_immediately: published.show_results_immediately,
            results_released: published.results_released,
            is_published: published.is_published,
            total_points: published.total_points,
            question_count,
            submission_count,
            created_at: published.created_at.to_string(),
            updated_at: published.updated_at.to_string(),
        })
    }

    pub async fn release_results(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if !assessment.is_published {
            return Err(AppError::BadRequest("Assessment must be published first".to_string()));
        }

        let released = self.assessment_repo.release_results(assessment_id).await?;

        let question_count = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?.len();
        let submission_count = self.submission_repo
            .count_by_assessment_id(assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "assessment",
            assessment_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "results_released": true,
            })).unwrap_or_default()),
        ).await;

        Ok(AssessmentResponse {
            id: released.id,
            class_id: released.class_id,
            title: released.title,
            description: released.description,
            time_limit_minutes: released.time_limit_minutes,
            open_at: released.open_at.to_string(),
            close_at: released.close_at.to_string(),
            show_results_immediately: released.show_results_immediately,
            results_released: released.results_released,
            is_published: released.is_published,
            total_points: released.total_points,
            question_count,
            submission_count,
            created_at: released.created_at.to_string(),
            updated_at: released.updated_at.to_string(),
        })
    }

    // ===== QUESTIONS =====

    pub async fn add_questions(
        &self,
        assessment_id: Uuid,
        request: AddQuestionsRequest,
        teacher_id: Uuid,
    ) -> AppResult<Vec<QuestionResponse>> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot add questions to a published assessment".to_string()));
        }

        let mut responses = Vec::new();

        for q_request in request.questions {
            let valid_types = ["multiple_choice", "identification", "enumeration"];
            if !valid_types.contains(&q_request.question_type.as_str()) {
                return Err(AppError::BadRequest(format!(
                    "Invalid question type: {}. Must be one of: {:?}",
                    q_request.question_type, valid_types
                )));
            }

            let question = self.assessment_repo.add_question(
                assessment_id,
                q_request.question_type.clone(),
                q_request.question_text.clone(),
                q_request.points,
                q_request.order_index,
                q_request.is_multi_select.unwrap_or(false),
            ).await?;

            let _ = self.change_log_repo.log_change(
                "question",
                question.id,
                "create",
                teacher_id,
                Some(serde_json::to_string(&serde_json::json!({
                    "question_type": q_request.question_type,
                    "points": q_request.points,
                })).unwrap_or_default()),
            ).await;

            // Add type-specific data
            match q_request.question_type.as_str() {
                "multiple_choice" => {
                    if let Some(choices) = q_request.choices {
                        for choice in choices {
                            self.assessment_repo.add_choice(
                                question.id,
                                choice.choice_text,
                                choice.is_correct,
                                choice.order_index,
                            ).await?;
                        }
                    }
                }
                "identification" => {
                    if let Some(answers) = q_request.correct_answers {
                        for answer in answers {
                            self.assessment_repo.add_correct_answer(question.id, answer).await?;
                        }
                    }
                }
                "enumeration" => {
                    if let Some(items) = q_request.enumeration_items {
                        for item_input in items {
                            let item = self.assessment_repo
                                .add_enumeration_item(question.id, item_input.order_index)
                                .await?;
                            for answer in item_input.acceptable_answers {
                                self.assessment_repo
                                    .add_enumeration_item_answer(item.id, answer)
                                    .await?;
                            }
                        }
                    }
                }
                _ => {}
            }

            let response = self.build_question_response(&question, "teacher").await?;
            responses.push(response);
        }

        self.assessment_repo.update_total_points(assessment_id).await?;

        Ok(responses)
    }

    pub async fn update_question(
        &self,
        question_id: Uuid,
        request: UpdateQuestionRequest,
        teacher_id: Uuid,
    ) -> AppResult<QuestionResponse> {
        let question = self.assessment_repo.find_question_by_id(question_id).await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(question.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot edit questions in a published assessment".to_string()));
        }

        let updated = self.assessment_repo.update_question(
            question_id,
            request.question_text,
            request.points,
            request.order_index,
            request.is_multi_select,
        ).await?;

        // Update type-specific data if provided
        if let Some(choices) = request.choices {
            self.assessment_repo.delete_choices_by_question_id(question_id).await?;
            for choice in choices {
                self.assessment_repo.add_choice(
                    question_id,
                    choice.choice_text,
                    choice.is_correct,
                    choice.order_index,
                ).await?;
            }
        }

        if let Some(answers) = request.correct_answers {
            self.assessment_repo.delete_correct_answers_by_question_id(question_id).await?;
            for answer in answers {
                self.assessment_repo.add_correct_answer(question_id, answer).await?;
            }
        }

        if let Some(items) = request.enumeration_items {
            self.assessment_repo.delete_enumeration_items_by_question_id(question_id).await?;
            for item_input in items {
                let item = self.assessment_repo
                    .add_enumeration_item(question_id, item_input.order_index)
                    .await?;
                for answer in item_input.acceptable_answers {
                    self.assessment_repo
                        .add_enumeration_item_answer(item.id, answer)
                        .await?;
                }
            }
        }

        self.assessment_repo.update_total_points(question.assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "question",
            question_id,
            "update",
            teacher_id,
            Some(serde_json::to_string(&serde_json::json!({
                "points": updated.points,
            })).unwrap_or_default()),
        ).await;

        let response = self.build_question_response(&updated, "teacher").await?;
        Ok(response)
    }

    pub async fn delete_question(
        &self,
        question_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let question = self.assessment_repo.find_question_by_id(question_id).await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(question.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot delete questions from a published assessment".to_string()));
        }

        self.assessment_repo.delete_question(question_id).await?;
        self.assessment_repo.update_total_points(question.assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "question",
            question_id,
            "delete",
            teacher_id,
            None,
        ).await;

        Ok(())
    }

    // ===== STUDENT SUBMISSION FLOW =====

    pub async fn start_assessment(
        &self,
        assessment_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<StartSubmissionResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        if !assessment.is_published {
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

        let now = chrono::Utc::now().naive_utc();
        if now < assessment.open_at {
            return Err(AppError::BadRequest("Assessment is not yet open".to_string()));
        }
        if now > assessment.close_at {
            return Err(AppError::BadRequest("Assessment is closed".to_string()));
        }

        // Check if student is enrolled
        let enrolled = self.class_repo
            .is_student_enrolled(assessment.class_id, student_id).await?;
        if !enrolled {
            return Err(AppError::Forbidden("You are not enrolled in this class".to_string()));
        }

        // Check if already started
        let existing = self.submission_repo
            .find_by_student_and_assessment(student_id, assessment_id).await?;
        if existing.is_some() {
            return Err(AppError::BadRequest("You have already started this assessment".to_string()));
        }

        let submission = self.submission_repo
            .create_submission(assessment_id, student_id).await?;

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

            let enumeration_count = if q.question_type == "enumeration" {
                let items = self.assessment_repo
                    .find_enumeration_items_by_question_id(q.id).await?;
                Some(items.len())
            } else {
                None
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
        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.is_submitted {
            return Err(AppError::BadRequest("Assessment already submitted".to_string()));
        }

        for answer_input in request.answers {
            let answer = self.submission_repo
                .upsert_answer(submission_id, answer_input.question_id, answer_input.answer_text)
                .await?;

            if let Some(choice_ids) = answer_input.selected_choice_ids {
                self.submission_repo
                    .save_answer_choices(answer.id, choice_ids)
                    .await?;
            }

            if let Some(enum_answers) = answer_input.enumeration_answers {
                self.submission_repo
                    .save_enumeration_answers(answer.id, enum_answers)
                    .await?;
            }
        }

        Ok(())
    }

    pub async fn submit_assessment(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<SubmissionSummaryResponse> {
        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if submission.is_submitted {
            return Err(AppError::BadRequest("Assessment already submitted".to_string()));
        }

        // Grade the submission
        let (auto_score, final_score) = GradingService::grade_submission(
            submission_id,
            &self.assessment_repo,
            &self.submission_repo,
        ).await?;

        // Mark as submitted
        let submitted = self.submission_repo.mark_submitted(submission_id).await?;

        let student = self.user_repo.find_by_id(student_id).await?
            .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

        Ok(SubmissionSummaryResponse {
            id: submitted.id,
            student_id: submitted.student_id,
            student_name: student.full_name,
            student_username: student.username,
            started_at: submitted.started_at.to_string(),
            submitted_at: submitted.submitted_at.map(|dt| dt.to_string()),
            auto_score,
            final_score,
            is_submitted: submitted.is_submitted,
        })
    }

    // ===== TEACHER: SUBMISSIONS & GRADING =====

    pub async fn get_submissions(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionListResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submissions = self.submission_repo
            .find_by_assessment_id(assessment_id).await?;

        let mut responses = Vec::new();
        for s in submissions {
            let student = self.user_repo.find_by_id(s.student_id).await?
                .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

            responses.push(SubmissionSummaryResponse {
                id: s.id,
                student_id: s.student_id,
                student_name: student.full_name,
                student_username: student.username,
                started_at: s.started_at.to_string(),
                submitted_at: s.submitted_at.map(|dt| dt.to_string()),
                auto_score: s.auto_score,
                final_score: s.final_score,
                is_submitted: s.is_submitted,
            });
        }

        Ok(SubmissionListResponse { submissions: responses })
    }

    pub async fn get_submission_detail(
        &self,
        submission_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionDetailResponse> {
        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(submission.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let student = self.user_repo.find_by_id(submission.student_id).await?
            .ok_or_else(|| AppError::NotFound("Student not found".to_string()))?;

        let answers = self.submission_repo
            .find_answers_by_submission_id(submission_id).await?;

        let mut answer_responses = Vec::new();
        for a in answers {
            let question = self.assessment_repo.find_question_by_id(a.question_id).await?;
            let question = match question {
                Some(q) => q,
                None => continue,
            };

            let selected_choices = if question.question_type == "multiple_choice" {
                let selections = self.submission_repo.find_answer_choices(a.id).await?;
                let mut choice_responses = Vec::new();
                for sel in selections {
                    let choices = self.assessment_repo.find_choices_by_question_id(question.id).await?;
                    if let Some(choice) = choices.iter().find(|c| c.id == sel.choice_id) {
                        choice_responses.push(SelectedChoiceResponse {
                            choice_id: choice.id,
                            choice_text: choice.choice_text.clone(),
                            is_correct: choice.is_correct,
                        });
                    }
                }
                Some(choice_responses)
            } else {
                None
            };

            let enumeration_answers = if question.question_type == "enumeration" {
                let enum_answers = self.submission_repo.find_enumeration_answers(a.id).await?;
                Some(
                    enum_answers.into_iter().map(|ea| EnumerationAnswerResponse {
                        id: ea.id,
                        answer_text: ea.answer_text,
                        matched_item_id: ea.matched_item_id,
                        is_auto_correct: ea.is_auto_correct,
                        is_override_correct: ea.is_override_correct,
                    }).collect()
                )
            } else {
                None
            };

            answer_responses.push(SubmissionAnswerResponse {
                id: a.id,
                question_id: a.question_id,
                question_text: question.question_text,
                question_type: question.question_type,
                points: question.points,
                answer_text: a.answer_text,
                selected_choices,
                enumeration_answers,
                is_auto_correct: a.is_auto_correct,
                is_override_correct: a.is_override_correct,
                points_awarded: a.points_awarded,
            });
        }

        Ok(SubmissionDetailResponse {
            id: submission.id,
            assessment_id: submission.assessment_id,
            student_id: submission.student_id,
            student_name: student.full_name,
            started_at: submission.started_at.to_string(),
            submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
            auto_score: submission.auto_score,
            final_score: submission.final_score,
            is_submitted: submission.is_submitted,
            answers: answer_responses,
        })
    }

    pub async fn override_answer(
        &self,
        answer_id: Uuid,
        request: OverrideAnswerRequest,
        teacher_id: Uuid,
    ) -> AppResult<SubmissionAnswerResponse> {
        let answer = self.submission_repo.find_answer_by_id(answer_id).await?
            .ok_or_else(|| AppError::NotFound("Answer not found".to_string()))?;

        let submission = self.submission_repo.find_by_id(answer.submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        let assessment = self.assessment_repo.find_by_id(submission.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let question = self.assessment_repo.find_question_by_id(answer.question_id).await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        let points = if request.is_correct { question.points as f64 } else { 0.0 };

        let updated = self.submission_repo
            .override_answer(answer_id, request.is_correct, points)
            .await?;

        GradingService::recalculate_final_score(submission.id, &self.submission_repo).await?;

        Ok(SubmissionAnswerResponse {
            id: updated.id,
            question_id: updated.question_id,
            question_text: question.question_text,
            question_type: question.question_type,
            points: question.points,
            answer_text: updated.answer_text,
            selected_choices: None,
            enumeration_answers: None,
            is_auto_correct: updated.is_auto_correct,
            is_override_correct: updated.is_override_correct,
            points_awarded: updated.points_awarded,
        })
    }

    // ===== STUDENT RESULTS =====

    pub async fn get_student_results(
        &self,
        submission_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<StudentResultResponse> {
        let submission = self.submission_repo.find_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Submission not found".to_string()))?;

        if submission.student_id != student_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if !submission.is_submitted {
            return Err(AppError::BadRequest("Assessment not yet submitted".to_string()));
        }

        let assessment = self.assessment_repo.find_by_id(submission.assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        if !assessment.show_results_immediately && !assessment.results_released {
            return Err(AppError::Forbidden("Results have not been released yet".to_string()));
        }

        let answers = self.submission_repo
            .find_answers_by_submission_id(submission_id).await?;

        let mut answer_results = Vec::new();
        for a in answers {
            let question = self.assessment_repo.find_question_by_id(a.question_id).await?;
            let question = match question {
                Some(q) => q,
                None => continue,
            };

            let is_correct = a.is_override_correct.or(a.is_auto_correct);

            let selected_choices = if question.question_type == "multiple_choice" {
                let selections = self.submission_repo.find_answer_choices(a.id).await?;
                let choices = self.assessment_repo.find_choices_by_question_id(question.id).await?;
                let texts: Vec<String> = selections.iter().filter_map(|s| {
                    choices.iter().find(|c| c.id == s.choice_id).map(|c| c.choice_text.clone())
                }).collect();
                Some(texts)
            } else {
                None
            };

            let enumeration_answers = if question.question_type == "enumeration" {
                let enum_ans = self.submission_repo.find_enumeration_answers(a.id).await?;
                Some(enum_ans.into_iter().map(|ea| {
                    let is_correct = ea.is_override_correct.or(ea.is_auto_correct);
                    StudentEnumAnswerResult {
                        answer_text: ea.answer_text,
                        is_correct,
                    }
                }).collect())
            } else {
                None
            };

            // Get correct answers for display
            let correct_answers = match question.question_type.as_str() {
                "multiple_choice" => {
                    let choices = self.assessment_repo.find_choices_by_question_id(question.id).await?;
                    Some(choices.iter().filter(|c| c.is_correct).map(|c| c.choice_text.clone()).collect())
                }
                "identification" => {
                    let answers = self.assessment_repo.find_correct_answers_by_question_id(question.id).await?;
                    Some(answers.iter().map(|a| a.answer_text.clone()).collect())
                }
                "enumeration" => {
                    let items = self.assessment_repo.find_enumeration_items_by_question_id(question.id).await?;
                    let mut all_answers = Vec::new();
                    for item in items {
                        let item_answers = self.assessment_repo.find_enumeration_item_answers(item.id).await?;
                        if let Some(first) = item_answers.first() {
                            all_answers.push(first.answer_text.clone());
                        }
                    }
                    Some(all_answers)
                }
                _ => None,
            };

            answer_results.push(StudentAnswerResultResponse {
                question_id: question.id,
                question_text: question.question_text,
                question_type: question.question_type,
                points: question.points,
                points_awarded: a.points_awarded,
                is_correct,
                answer_text: a.answer_text,
                selected_choices,
                enumeration_answers,
                correct_answers,
            });
        }

        Ok(StudentResultResponse {
            submission_id: submission.id,
            auto_score: submission.auto_score,
            final_score: submission.final_score,
            total_points: assessment.total_points,
            submitted_at: submission.submitted_at.map(|dt| dt.to_string()),
            answers: answer_results,
        })
    }

    // ===== STATISTICS =====

    pub async fn get_statistics(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentStatisticsResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submissions = self.submission_repo
            .find_by_assessment_id(assessment_id).await?;

        let submitted: Vec<_> = submissions.iter().filter(|s| s.is_submitted).collect();
        let submission_count = submitted.len();

        let scores: Vec<f64> = submitted.iter().map(|s| s.final_score).collect();

        let class_statistics = if scores.is_empty() {
            ClassStatistics {
                mean: 0.0,
                median: 0.0,
                highest: 0.0,
                lowest: 0.0,
                score_distribution: Vec::new(),
            }
        } else {
            let mut sorted_scores = scores.clone();
            sorted_scores.sort_by(|a, b| a.partial_cmp(b).unwrap());

            let mean = scores.iter().sum::<f64>() / scores.len() as f64;
            let median = if sorted_scores.len() % 2 == 0 {
                let mid = sorted_scores.len() / 2;
                (sorted_scores[mid - 1] + sorted_scores[mid]) / 2.0
            } else {
                sorted_scores[sorted_scores.len() / 2]
            };
            let highest = *sorted_scores.last().unwrap();
            let lowest = *sorted_scores.first().unwrap();

            let total = assessment.total_points as f64;
            let distribution = if total > 0.0 {
                let buckets = vec![
                    ("0-20%", 0.0, 0.2),
                    ("21-40%", 0.2, 0.4),
                    ("41-60%", 0.4, 0.6),
                    ("61-80%", 0.6, 0.8),
                    ("81-100%", 0.8, 1.0),
                ];
                buckets.into_iter().map(|(range, low, high)| {
                    let count = scores.iter().filter(|&&s| {
                        let pct = s / total;
                        pct >= low && (pct < high || (high == 1.0 && pct <= high))
                    }).count();
                    ScoreBucket {
                        range: range.to_string(),
                        count,
                    }
                }).collect()
            } else {
                Vec::new()
            };

            ClassStatistics {
                mean,
                median,
                highest,
                lowest,
                score_distribution: distribution,
            }
        };

        // Per-question statistics
        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        let mut question_stats = Vec::new();
        for q in questions {
            let mut correct_count = 0;
            let mut incorrect_count = 0;

            for s in &submitted {
                let answers = self.submission_repo
                    .find_answers_by_submission_id(s.id).await?;
                if let Some(a) = answers.iter().find(|a| a.question_id == q.id) {
                    let is_correct = a.is_override_correct.or(a.is_auto_correct).unwrap_or(false);
                    if is_correct {
                        correct_count += 1;
                    } else {
                        incorrect_count += 1;
                    }
                }
            }

            let total_answered = correct_count + incorrect_count;
            let correct_percentage = if total_answered > 0 {
                (correct_count as f64 / total_answered as f64) * 100.0
            } else {
                0.0
            };

            question_stats.push(QuestionStatistics {
                question_id: q.id,
                question_text: q.question_text,
                question_type: q.question_type,
                points: q.points,
                correct_count,
                incorrect_count,
                correct_percentage,
            });
        }

        Ok(AssessmentStatisticsResponse {
            assessment_id: assessment.id,
            title: assessment.title,
            total_points: assessment.total_points,
            submission_count,
            class_statistics,
            question_statistics: question_stats,
        })
    }

    // ===== HELPERS =====

    async fn build_question_response(
        &self,
        question: &::entity::assessment_questions::Model,
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
                .find_enumeration_items_by_question_id(question.id).await?;
            let mut item_responses = Vec::new();
            for item in items {
                let answers = self.assessment_repo
                    .find_enumeration_item_answers(item.id).await?;
                item_responses.push(EnumerationItemResponse {
                    id: item.id,
                    order_index: item.order_index,
                    acceptable_answers: answers.into_iter().map(|a| {
                        EnumerationItemAnswerResponse {
                            id: a.id,
                            answer_text: a.answer_text,
                        }
                    }).collect(),
                });
            }
            Some(item_responses)
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

    pub async fn get_assessments_metadata(&self) -> AppResult<AssessmentMetadataResponse> {
        let assessments = self.assessment_repo.find_all().await?;
        let count = assessments.len();

        let last_modified = if count > 0 {
            assessments
                .iter()
                .map(|a| a.updated_at)
                .max()
                .unwrap_or_else(|| chrono::Utc::now().naive_utc())
        } else {
            chrono::Utc::now().naive_utc()
        };

        let etag_data = format!("{}-{}", count, last_modified);
        let etag = format!("{:x}", md5::compute(etag_data.as_bytes()));

        Ok(AssessmentMetadataResponse {
            last_modified: last_modified.to_string(),
            record_count: count,
            etag,
        })
    }
}
