use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::{parse_datetime, fmt_utc, validators::Validator};
use crate::schema::assessment_schema::*;
use crate::services::grade_computation::auto_populate;
use md5;

impl super::AssessmentService {
    pub async fn create_assessment(
        &self,
        class_id: Uuid,
        request: CreateAssessmentRequest,
        teacher_id: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<AssessmentResponse> {
        let _ = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("You can only create assessments in your own classes".to_string()));
        }

        let title = Validator::validate_title(&request.title)?;

        let open_at = parse_datetime(&request.open_at)?;
        let close_at = parse_datetime(&request.close_at)?;

        if close_at <= open_at {
            return Err(AppError::BadRequest("Close date must be after open date".to_string()));
        }

        let max_order = self.assessment_repo.get_max_order_index(class_id).await?;
        let order_index = max_order + 1;

        let assessment = self.assessment_repo.create_assessment(
            class_id,
            title,
            request.description,
            request.time_limit_minutes,
            open_at,
            close_at,
            request.show_results_immediately.unwrap_or(true),
            order_index,
            client_id,
            request.is_published.unwrap_or(false),
            request.quarter,
            request.component.clone(),
            request.is_departmental_exam,
            request.linked_tos_id,
        ).await?;


        // NEW: if questions provided in the request, insert them atomically
        let question_count = if let Some(questions) = request.questions {
            if !questions.is_empty() {
                let created = self.insert_questions_for_assessment(assessment.id, questions, teacher_id).await?;
                created.len() as usize
            } else {
                0
            }
        } else {
            0
        };

        Ok(AssessmentResponse {
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
            question_count,
            submission_count: 0,
            quarter: assessment.quarter,
            component: assessment.component.clone(),
            is_departmental_exam: assessment.is_departmental_exam,
            linked_tos_id: assessment.linked_tos_id.clone(),
            created_at: fmt_utc(assessment.created_at),
            updated_at: fmt_utc(assessment.updated_at),
        })
    }

    pub async fn get_assessments(
        &self,
        class_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<AssessmentListResponse> {
        let _ = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let is_teacher_of_class = role == "teacher" && self.class_repo.is_teacher_of_class(user_id, class_id).await?;
        let assessments = if is_teacher_of_class {
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
                open_at: fmt_utc(a.open_at),
                close_at: fmt_utc(a.close_at),
                show_results_immediately: a.show_results_immediately,
                results_released: a.results_released,
                is_published: a.is_published,
                order_index: a.order_index,
                total_points: a.total_points,
                question_count,
                submission_count,
                quarter: a.quarter,
                component: a.component.clone(),
                is_departmental_exam: a.is_departmental_exam,
                linked_tos_id: a.linked_tos_id.clone(),
                created_at: fmt_utc(a.created_at),
                updated_at: fmt_utc(a.updated_at),
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

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if role == "student" && !assessment.is_published {
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

        if role == "teacher" && !self.class_repo.is_teacher_of_class(user_id, assessment.class_id).await? {
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
            open_at: fmt_utc(assessment.open_at),
            close_at: fmt_utc(assessment.close_at),
            show_results_immediately: assessment.show_results_immediately,
            results_released: assessment.results_released,
            is_published: assessment.is_published,
            order_index: assessment.order_index,
            total_points: assessment.total_points,
            quarter: assessment.quarter,
            component: assessment.component.clone(),
            is_departmental_exam: assessment.is_departmental_exam,
            linked_tos_id: assessment.linked_tos_id.clone(),
            questions: question_responses,
            created_at: fmt_utc(assessment.created_at),
            updated_at: fmt_utc(assessment.updated_at),
        })
    }

    pub async fn get_student_assessments(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<crate::schema::tasks_schema::StudentAssessmentListItem>> {
        let assessments = self
            .assessment_repo
            .find_published_by_class_id(class_id)
            .await?;

        let mut items = Vec::new();
        for a in assessments {
            let submission = self
                .submission_repo
                .find_by_student_and_assessment(student_id, a.id)
                .await?;

            items.push(crate::schema::tasks_schema::StudentAssessmentListItem {
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

    pub async fn update_assessment(
        &self,
        assessment_id: Uuid,
        request: UpdateAssessmentRequest,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if assessment.is_published {
            return Err(AppError::BadRequest("Cannot edit a published assessment".to_string()));
        }

        let title = Validator::validate_optional_title(request.title)?;

        let open_at = match &request.open_at {
            Some(s) => Some(parse_datetime(s)?),
            None => None,
        };
        let close_at = match &request.close_at {
            Some(s) => Some(parse_datetime(s)?),
            None => None,
        };

        let updated = self.assessment_repo.update_assessment(
            assessment_id,
            title,
            request.description,
            request.time_limit_minutes,
            open_at,
            close_at,
            request.show_results_immediately,
            request.quarter.map(|q| Some(q)),
            request.component.clone().map(|c| Some(c)),
            request.is_departmental_exam.map(|d| Some(d)),
            request.linked_tos_id,
        ).await?;

        let question_count = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?.len();
        let submission_count = self.submission_repo
            .count_by_assessment_id(assessment_id).await?;


        Ok(AssessmentResponse {
            id: updated.id,
            class_id: updated.class_id,
            title: updated.title,
            description: updated.description,
            time_limit_minutes: updated.time_limit_minutes,
            open_at: fmt_utc(updated.open_at),
            close_at: fmt_utc(updated.close_at),
            show_results_immediately: updated.show_results_immediately,
            results_released: updated.results_released,
            is_published: updated.is_published,
            order_index: updated.order_index,
            total_points: updated.total_points,
            question_count,
            submission_count,
            quarter: updated.quarter,
            component: updated.component.clone(),
            is_departmental_exam: updated.is_departmental_exam,
            linked_tos_id: updated.linked_tos_id.clone(),
            created_at: fmt_utc(updated.created_at),
            updated_at: fmt_utc(updated.updated_at),
        })
    }

    pub async fn delete_assessment(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.submission_repo.soft_delete_by_assessment(assessment_id).await?;
        self.assessment_repo.soft_delete(assessment_id).await?;

        Ok(())
    }

    pub async fn soft_delete(
        &self,
        assessment_id: Uuid,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<()> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if user_role != "admin" && !self.class_repo.is_teacher_of_class(user_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.assessment_repo.soft_delete(assessment_id).await?;


        Ok(())
    }

    pub async fn publish_assessment(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
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

        // Auto-create linked grade item if grading metadata present
        if let (Some(quarter), Some(ref component)) = (published.quarter, &published.component) {
            let _ = auto_populate::create_linked_grade_item(
                &self.db, "assessment", published.id, published.class_id,
                &published.title, component, quarter,
                published.total_points as f64,
                published.is_departmental_exam.unwrap_or(false),
            ).await;
        }

        let question_count = questions.len();
        let submission_count = self.submission_repo.count_by_assessment_id(assessment_id).await?;


        Ok(AssessmentResponse {
            id: published.id,
            class_id: published.class_id,
            title: published.title,
            description: published.description,
            time_limit_minutes: published.time_limit_minutes,
            open_at: fmt_utc(published.open_at),
            close_at: fmt_utc(published.close_at),
            show_results_immediately: published.show_results_immediately,
            results_released: published.results_released,
            is_published: published.is_published,
            order_index: published.order_index,
            total_points: published.total_points,
            question_count,
            submission_count,
            quarter: published.quarter,
            component: published.component.clone(),
            is_departmental_exam: published.is_departmental_exam,
            linked_tos_id: published.linked_tos_id.clone(),
            created_at: fmt_utc(published.created_at),
            updated_at: fmt_utc(published.updated_at),
        })
    }

    pub async fn unpublish_assessment(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if !assessment.is_published {
            return Err(AppError::BadRequest("Assessment is not published".to_string()));
        }

        if assessment.results_released {
            return Err(AppError::BadRequest("Cannot unpublish — results have already been released".to_string()));
        }

        let unpublished = self.assessment_repo.unpublish_assessment(assessment_id).await?;

        let question_count = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?.len();
        let submission_count = self.submission_repo.count_by_assessment_id(assessment_id).await?;

        Ok(AssessmentResponse {
            id: unpublished.id,
            class_id: unpublished.class_id,
            title: unpublished.title,
            description: unpublished.description,
            time_limit_minutes: unpublished.time_limit_minutes,
            open_at: fmt_utc(unpublished.open_at),
            close_at: fmt_utc(unpublished.close_at),
            show_results_immediately: unpublished.show_results_immediately,
            results_released: unpublished.results_released,
            is_published: unpublished.is_published,
            order_index: unpublished.order_index,
            total_points: unpublished.total_points,
            question_count,
            submission_count,
            quarter: unpublished.quarter,
            component: unpublished.component.clone(),
            is_departmental_exam: unpublished.is_departmental_exam,
            linked_tos_id: unpublished.linked_tos_id.clone(),
            created_at: fmt_utc(unpublished.created_at),
            updated_at: fmt_utc(unpublished.updated_at),
        })
    }

    pub async fn release_results(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
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


        Ok(AssessmentResponse {
            id: released.id,
            class_id: released.class_id,
            title: released.title,
            description: released.description,
            time_limit_minutes: released.time_limit_minutes,
            open_at: fmt_utc(released.open_at),
            close_at: fmt_utc(released.close_at),
            show_results_immediately: released.show_results_immediately,
            results_released: released.results_released,
            is_published: released.is_published,
            order_index: released.order_index,
            total_points: released.total_points,
            question_count,
            submission_count,
            quarter: released.quarter,
            component: released.component.clone(),
            is_departmental_exam: released.is_departmental_exam,
            linked_tos_id: released.linked_tos_id.clone(),
            created_at: fmt_utc(released.created_at),
            updated_at: fmt_utc(released.updated_at),
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
            last_modified: fmt_utc(last_modified),
            record_count: count,
            etag,
        })
    }

    pub async fn reorder_assessments(
        &self,
        class_id: Uuid,
        request: ReorderAssessmentsRequest,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let _class = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden(
                "You can only reorder assessments in your own classes".to_string(),
            ));
        }

        if request.assessment_ids.is_empty() {
            return Ok(());
        }

        self.assessment_repo
            .reorder_assessments(class_id, request.assessment_ids)
            .await?;

        Ok(())
    }
}