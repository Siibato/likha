use sea_orm::{ConnectionTrait, DatabaseConnection, DbBackend, Statement};
use uuid::Uuid;

use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::grade_computation_repository::GradeComputationRepository;
use crate::schema::grading_schema::*;
use crate::utils::{AppError, AppResult};

pub struct GradeComputationService {
    pub repo: GradeComputationRepository,
    pub class_repo: ClassRepository,
    pub db: DatabaseConnection,
}

impl GradeComputationService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            repo: GradeComputationRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            db,
        }
    }

    // ===== GRADING CONFIG =====

    pub async fn setup_grading(
        &self,
        class_id: Uuid,
        grade_level: String,
        subject_group: String,
        school_year: String,
        semester: Option<i32>,
    ) -> AppResult<ClassGradingSetupResponse> {
        // Verify class exists
        self.class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        // Update class columns via raw SQL
        let now = chrono::Utc::now().naive_utc();
        let sql = "UPDATE classes SET grade_level = ?, subject_group = ?, school_year = ?, semester = ?, updated_at = ? WHERE id = ?";
        let stmt = Statement::from_sql_and_values(
            DbBackend::Sqlite,
            sql,
            vec![
                grade_level.clone().into(),
                subject_group.clone().into(),
                school_year.clone().into(),
                semester.map(sea_orm::Value::from).unwrap_or(sea_orm::Value::Int(None)),
                now.to_string().into(),
                class_id.to_string().into(),
            ],
        );
        self.db
            .execute(stmt)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update class: {}", e)))?;

        // Seed weight configs from DepEd presets
        let configs = self.repo.setup_defaults(class_id, &subject_group).await?;

        Ok(ClassGradingSetupResponse {
            class_id: class_id.to_string(),
            grade_level,
            subject_group,
            school_year,
            semester,
            configs: configs.into_iter().map(GradingConfigResponse::from).collect(),
        })
    }

    pub async fn get_grading_config(
        &self,
        class_id: Uuid,
    ) -> AppResult<Vec<GradingConfigResponse>> {
        let configs = self.repo.get_all_configs(class_id).await?;
        Ok(configs.into_iter().map(GradingConfigResponse::from).collect())
    }

    pub async fn update_grading_config(
        &self,
        class_id: Uuid,
        quarter: i32,
        ww: f64,
        pt: f64,
        qa: f64,
    ) -> AppResult<GradingConfigResponse> {
        // Validate quarter range
        if !(1..=4).contains(&quarter) {
            return Err(AppError::BadRequest("Quarter must be between 1 and 4".to_string()));
        }

        // Validate weights sum to 100 (with tolerance)
        let sum = ww + pt + qa;
        if (sum - 100.0).abs() > 0.01 {
            return Err(AppError::BadRequest(format!(
                "Weights must sum to 100 (got {})",
                sum
            )));
        }

        let config = self.repo.upsert_config(class_id, quarter, ww, pt, qa).await?;
        Ok(GradingConfigResponse::from(config))
    }

    // ===== GRADE ITEMS =====

    pub async fn create_grade_item(
        &self,
        class_id: Uuid,
        req: CreateGradeItemRequest,
    ) -> AppResult<GradeItemResponse> {
        // Validate component
        let valid_components = ["written_work", "performance_task", "quarterly_assessment"];
        if !valid_components.contains(&req.component.as_str()) {
            return Err(AppError::BadRequest(format!(
                "Invalid component '{}'. Must be one of: {}",
                req.component,
                valid_components.join(", ")
            )));
        }

        // Validate quarter range
        if !(1..=4).contains(&req.quarter) {
            return Err(AppError::BadRequest("Quarter must be between 1 and 4".to_string()));
        }

        let is_dept_exam = req.is_departmental_exam.unwrap_or(false);

        // If departmental exam, verify no existing one for this class/quarter/component
        if is_dept_exam {
            let existing = self
                .repo
                .get_items_by_component(class_id, req.quarter, &req.component)
                .await?;
            let has_dept = existing.iter().any(|item| item.is_departmental_exam);
            if has_dept {
                return Err(AppError::Conflict(format!(
                    "A departmental exam already exists for quarter {} component '{}'",
                    req.quarter, req.component
                )));
            }
        }

        // Determine order_index (append to end)
        let existing_items = self.repo.get_items_by_component(class_id, req.quarter, &req.component).await?;
        let order_index = existing_items.len() as i32;

        let item = self
            .repo
            .create_item(
                class_id,
                req.title,
                req.component,
                req.quarter,
                req.total_points,
                is_dept_exam,
                "manual".to_string(),
                None,
                order_index,
            )
            .await?;

        Ok(GradeItemResponse::from(item))
    }

    pub async fn get_grade_items(
        &self,
        class_id: Uuid,
        quarter: i32,
    ) -> AppResult<Vec<GradeItemResponse>> {
        let items = self.repo.get_items(class_id, quarter).await?;
        Ok(items.into_iter().map(GradeItemResponse::from).collect())
    }

    pub async fn update_grade_item(
        &self,
        id: Uuid,
        req: UpdateGradeItemRequest,
    ) -> AppResult<GradeItemResponse> {
        let item = self
            .repo
            .update_item(id, req.title, req.component, req.total_points, req.order_index)
            .await?;
        Ok(GradeItemResponse::from(item))
    }

    pub async fn delete_grade_item(&self, id: Uuid) -> AppResult<()> {
        // Find item first to check source_type
        let item = self
            .repo
            .find_item(id)
            .await?
            .ok_or_else(|| AppError::NotFound("Grade item not found".to_string()))?;

        if item.source_type != "manual" {
            return Err(AppError::BadRequest(
                "Cannot delete linked grade items. Only manually created items can be deleted."
                    .to_string(),
            ));
        }

        self.repo.soft_delete_item(id).await
    }

    // ===== SCORES =====

    pub async fn get_item_scores(
        &self,
        grade_item_id: Uuid,
    ) -> AppResult<Vec<GradeScoreResponse>> {
        let scores = self.repo.get_scores_by_item(grade_item_id).await?;
        Ok(scores.into_iter().map(GradeScoreResponse::from).collect())
    }

    pub async fn save_scores(
        &self,
        grade_item_id: Uuid,
        scores: Vec<(Uuid, f64)>,
    ) -> AppResult<Vec<GradeScoreResponse>> {
        // Verify grade item exists
        self.repo
            .find_item(grade_item_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Grade item not found".to_string()))?;

        // Bulk upsert scores
        self.repo.bulk_upsert_scores(grade_item_id, scores).await?;

        // Return all scores for the item
        self.get_item_scores(grade_item_id).await
    }

    pub async fn set_override(
        &self,
        score_id: Uuid,
        override_score: f64,
    ) -> AppResult<GradeScoreResponse> {
        let score = self.repo.set_override(score_id, override_score).await?;
        Ok(GradeScoreResponse::from(score))
    }

    pub async fn clear_override(&self, score_id: Uuid) -> AppResult<GradeScoreResponse> {
        let score = self.repo.clear_override(score_id).await?;
        Ok(GradeScoreResponse::from(score))
    }

    // ===== QUARTERLY GRADES =====

    pub async fn get_quarterly_grades(
        &self,
        class_id: Uuid,
        quarter: i32,
    ) -> AppResult<Vec<QuarterlyGradeResponse>> {
        let grades = self.repo.get_all_for_class(class_id, quarter).await?;
        Ok(grades
            .into_iter()
            .map(QuarterlyGradeResponse::from)
            .collect())
    }

    pub async fn get_student_quarterly_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        quarter: i32,
    ) -> AppResult<Option<QuarterlyGradeResponse>> {
        let grade = self
            .repo
            .get_quarterly_grade(class_id, student_id, quarter)
            .await?;
        Ok(grade.map(QuarterlyGradeResponse::from))
    }

    pub async fn get_student_all_quarters(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<QuarterlyGradeResponse>> {
        let grades = self.repo.get_all_for_student(class_id, student_id).await?;
        Ok(grades
            .into_iter()
            .map(QuarterlyGradeResponse::from)
            .collect())
    }
}
