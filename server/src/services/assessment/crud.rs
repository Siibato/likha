use chrono::NaiveDateTime;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;
use md5;

impl super::AssessmentService {
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

        if role == "student" && !assessment.is_published {
            return Err(AppError::NotFound("Assessment not found".to_string()));
        }

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

    pub async fn soft_delete(
        &self,
        assessment_id: Uuid,
        user_id: Uuid,
        user_role: &str,
    ) -> AppResult<()> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if user_role != "admin" && class.teacher_id != user_id {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.assessment_repo.soft_delete(assessment_id).await?;

        let _ = self.change_log_repo.log_change(
            "assessment",
            assessment_id,
            "soft_delete",
            user_id,
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