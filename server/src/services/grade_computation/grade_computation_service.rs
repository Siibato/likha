use sea_orm::DatabaseConnection;
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

    pub async fn get_grading_config(&self, class_id: Uuid) -> AppResult<ClassGradingSetupResponse> {
        let configs = self.repo.get_all_configs(class_id).await?;
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;
        Ok(ClassGradingSetupResponse {
            class_id: class_id.to_string(),
            grade_level: class.grade_level.unwrap_or_default(),
            school_year: class.school_year.unwrap_or_default(),
            grading_period_type: class.grading_period_type,
            configs: configs.into_iter().map(GradingConfigResponse::from).collect(),
        })
    }

    pub async fn setup_grading(
        &self,
        class_id: Uuid,
        _grade_level: String,
        subject_group: String,
        _school_year: String,
        _semester: Option<i32>,
    ) -> AppResult<ClassGradingSetupResponse> {
        self.repo.setup_defaults(class_id, &subject_group).await?;
        self.get_grading_config(class_id).await
    }

    pub async fn update_grading_config(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
        ww_weight: f64,
        pt_weight: f64,
        qa_weight: f64,
    ) -> AppResult<GradingConfigResponse> {
        let config = self
            .repo
            .upsert_config(class_id, grading_period_number, ww_weight, pt_weight, qa_weight)
            .await?;
        Ok(GradingConfigResponse::from(config))
    }

    // ===== GRADE ITEMS =====

    pub async fn get_grade_items(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<GradeItemResponse>> {
        let items = self.repo.get_items(class_id, grading_period_number).await?;
        Ok(items.into_iter().map(GradeItemResponse::from).collect())
    }

    pub async fn create_grade_item(
        &self,
        class_id: Uuid,
        request: CreateGradeItemRequest,
    ) -> AppResult<GradeItemResponse> {
        let grading_period_number = request.grading_period_number.unwrap_or(1);
        let existing = self
            .repo
            .get_items_by_component(class_id, grading_period_number, &request.component)
            .await?;
        let order_index = existing.len() as i32;
        let item = self
            .repo
            .create_item(
                class_id,
                request.title,
                request.component,
                request.grading_period_number,
                request.total_points,
                "manual".to_string(),
                None,
                order_index,
            )
            .await?;
        Ok(GradeItemResponse::from(item))
    }

    pub async fn update_grade_item(
        &self,
        id: Uuid,
        request: UpdateGradeItemRequest,
    ) -> AppResult<GradeItemResponse> {
        let item = self
            .repo
            .update_item(id, request.title, request.component, request.total_points, request.order_index)
            .await?;
        Ok(GradeItemResponse::from(item))
    }

    pub async fn delete_grade_item(&self, id: Uuid) -> AppResult<()> {
        self.repo.soft_delete_item(id).await
    }

    // ===== GRADE SCORES =====

    pub async fn get_item_scores(&self, grade_item_id: Uuid) -> AppResult<Vec<GradeScoreResponse>> {
        let scores = self.repo.get_scores_by_item(grade_item_id).await?;
        Ok(scores.into_iter().map(GradeScoreResponse::from).collect())
    }

    pub async fn save_scores(
        &self,
        grade_item_id: Uuid,
        scores: Vec<(Uuid, f64)>,
    ) -> AppResult<Vec<GradeScoreResponse>> {
        self.repo.bulk_upsert_scores(grade_item_id, scores).await?;
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

    // ===== PERIOD GRADES =====

    /// Get a single student's period grade (used by students viewing their own grade).
    pub async fn get_student_quarterly_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<PeriodGradeResponse> {
        let grade = self
            .repo
            .get_period_grade(class_id, student_id, grading_period_number)
            .await?
            .ok_or_else(|| AppError::NotFound("Grade not found for this period".to_string()))?;
        Ok(PeriodGradeResponse::from(grade))
    }

    /// Get all students' period grades for a class/period (used by teachers).
    pub async fn get_quarterly_grades(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<PeriodGradeResponse>> {
        let grades = self.repo.get_all_for_class(class_id, grading_period_number).await?;
        Ok(grades.into_iter().map(PeriodGradeResponse::from).collect())
    }

    /// Get all period grades for a student across all periods.
    pub async fn get_student_all_quarters(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<PeriodGradeResponse>> {
        let grades = self.repo.get_all_for_student(class_id, student_id).await?;
        Ok(grades.into_iter().map(PeriodGradeResponse::from).collect())
    }
}
