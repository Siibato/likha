use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::{table_of_specifications, tos_competencies};
use crate::db::repositories::repository_operations::tos as ops;
use crate::utils::AppResult;

pub use ops::MelcRow;

pub struct TosRepository {
    db: DatabaseConnection,
}

impl TosRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    // ===== TABLE OF SPECIFICATIONS CRUD =====

    pub async fn create_tos(
        &self,
        id: Uuid,
        class_id: Uuid,
        grading_period_number: i32,
        title: &str,
        classification_mode: &str,
        total_items: i32,
        time_unit: &str,
        easy_percentage: f64,
        medium_percentage: f64,
        hard_percentage: f64,
        remembering_percentage: f64,
        understanding_percentage: f64,
        applying_percentage: f64,
        analyzing_percentage: f64,
        evaluating_percentage: f64,
        creating_percentage: f64,
    ) -> AppResult<table_of_specifications::Model> {
        ops::create_tos(
            &self.db, id, class_id, grading_period_number, title, classification_mode,
            total_items, time_unit, easy_percentage, medium_percentage, hard_percentage,
            remembering_percentage, understanding_percentage, applying_percentage,
            analyzing_percentage, evaluating_percentage, creating_percentage,
        ).await
    }

    pub async fn find_tos_by_id(&self, id: Uuid) -> AppResult<Option<table_of_specifications::Model>> {
        ops::find_tos_by_id(&self.db, id).await
    }

    pub async fn find_tos_by_class(&self, class_id: Uuid) -> AppResult<Vec<table_of_specifications::Model>> {
        ops::find_tos_by_class(&self.db, class_id).await
    }

    pub async fn find_tos_by_class_and_period(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Option<table_of_specifications::Model>> {
        ops::find_tos_by_class_and_period(&self.db, class_id, grading_period_number).await
    }

    pub async fn update_tos(
        &self,
        id: Uuid,
        title: Option<&str>,
        classification_mode: Option<&str>,
        total_items: Option<i32>,
        time_unit: Option<&str>,
        easy_percentage: Option<f64>,
        medium_percentage: Option<f64>,
        hard_percentage: Option<f64>,
        remembering_percentage: Option<f64>,
        understanding_percentage: Option<f64>,
        applying_percentage: Option<f64>,
        analyzing_percentage: Option<f64>,
        evaluating_percentage: Option<f64>,
        creating_percentage: Option<f64>,
    ) -> AppResult<table_of_specifications::Model> {
        ops::update_tos(
            &self.db, id, title, classification_mode, total_items, time_unit,
            easy_percentage, medium_percentage, hard_percentage, remembering_percentage,
            understanding_percentage, applying_percentage, analyzing_percentage,
            evaluating_percentage, creating_percentage,
        ).await
    }

    pub async fn soft_delete_tos(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete_tos(&self.db, id).await
    }

    // ===== COMPETENCIES CRUD =====

    pub async fn create_competency(
        &self,
        id: Uuid,
        tos_id: Uuid,
        competency_code: Option<&str>,
        competency_text: &str,
        time_units_taught: i32,
        order_index: i32,
        easy_count: Option<i32>,
        medium_count: Option<i32>,
        hard_count: Option<i32>,
        remembering_count: Option<i32>,
        understanding_count: Option<i32>,
        applying_count: Option<i32>,
        analyzing_count: Option<i32>,
        evaluating_count: Option<i32>,
        creating_count: Option<i32>,
    ) -> AppResult<tos_competencies::Model> {
        ops::create_competency(
            &self.db, id, tos_id, competency_code, competency_text, time_units_taught,
            order_index, easy_count, medium_count, hard_count, remembering_count,
            understanding_count, applying_count, analyzing_count, evaluating_count, creating_count,
        ).await
    }

    pub async fn find_competencies_by_tos(&self, tos_id: Uuid) -> AppResult<Vec<tos_competencies::Model>> {
        ops::find_competencies_by_tos(&self.db, tos_id).await
    }

    pub async fn find_competency_by_id(&self, id: Uuid) -> AppResult<Option<tos_competencies::Model>> {
        ops::find_competency_by_id(&self.db, id).await
    }

    pub async fn update_competency(
        &self,
        id: Uuid,
        competency_code: Option<Option<&str>>,
        competency_text: Option<&str>,
        time_units_taught: Option<i32>,
        order_index: Option<i32>,
        easy_count: Option<Option<i32>>,
        medium_count: Option<Option<i32>>,
        hard_count: Option<Option<i32>>,
        remembering_count: Option<Option<i32>>,
        understanding_count: Option<Option<i32>>,
        applying_count: Option<Option<i32>>,
        analyzing_count: Option<Option<i32>>,
        evaluating_count: Option<Option<i32>>,
        creating_count: Option<Option<i32>>,
    ) -> AppResult<tos_competencies::Model> {
        ops::update_competency(
            &self.db, id, competency_code, competency_text, time_units_taught, order_index,
            easy_count, medium_count, hard_count, remembering_count, understanding_count,
            applying_count, analyzing_count, evaluating_count, creating_count,
        ).await
    }

    pub async fn soft_delete_competency(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete_competency(&self.db, id).await
    }

    pub async fn bulk_create_competencies(
        &self,
        tos_id: Uuid,
        competencies: Vec<(Option<String>, String, i32, i32, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>)>,
    ) -> AppResult<Vec<tos_competencies::Model>> {
        ops::bulk_create_competencies(&self.db, tos_id, competencies).await
    }

    // ===== MELCS SEARCH =====

    pub async fn search_melcs(
        &self,
        subject: Option<&str>,
        grade_level: Option<&str>,
        quarter: Option<i32>,
        query: Option<&str>,
        limit: i64,
        offset: i64,
    ) -> AppResult<Vec<MelcRow>> {
        ops::search_melcs(&self.db, subject, grade_level, quarter, query, limit, offset).await
    }
}
