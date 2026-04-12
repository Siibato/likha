use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{table_of_specifications, tos_competencies};
use crate::utils::{AppError, AppResult};

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
        let now = Utc::now().naive_utc();
        let tos = table_of_specifications::ActiveModel {
            id: Set(id),
            class_id: Set(class_id),
            grading_period_number: Set(grading_period_number),
            title: Set(title.to_string()),
            classification_mode: Set(classification_mode.to_string()),
            total_items: Set(total_items),
            time_unit: Set(time_unit.to_string()),
            easy_percentage: Set(easy_percentage),
            medium_percentage: Set(medium_percentage),
            hard_percentage: Set(hard_percentage),
            remembering_percentage: Set(remembering_percentage),
            understanding_percentage: Set(understanding_percentage),
            applying_percentage: Set(applying_percentage),
            analyzing_percentage: Set(analyzing_percentage),
            evaluating_percentage: Set(evaluating_percentage),
            creating_percentage: Set(creating_percentage),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };

        tos.insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create TOS: {}", e)))
    }

    pub async fn find_tos_by_id(
        &self,
        id: Uuid,
    ) -> AppResult<Option<table_of_specifications::Model>> {
        table_of_specifications::Entity::find_by_id(id)
            .filter(table_of_specifications::Column::DeletedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_tos_by_class(
        &self,
        class_id: Uuid,
    ) -> AppResult<Vec<table_of_specifications::Model>> {
        table_of_specifications::Entity::find()
            .filter(table_of_specifications::Column::ClassId.eq(class_id))
            .filter(table_of_specifications::Column::DeletedAt.is_null())
            .order_by_asc(table_of_specifications::Column::GradingPeriodNumber)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_tos_by_class_and_period(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Option<table_of_specifications::Model>> {
        table_of_specifications::Entity::find()
            .filter(table_of_specifications::Column::ClassId.eq(class_id))
            .filter(table_of_specifications::Column::GradingPeriodNumber.eq(grading_period_number))
            .filter(table_of_specifications::Column::DeletedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
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
        let tos = table_of_specifications::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        let mut active: table_of_specifications::ActiveModel = tos.into();

        if let Some(t) = title {
            active.title = Set(t.to_string());
        }
        if let Some(m) = classification_mode {
            active.classification_mode = Set(m.to_string());
        }
        if let Some(n) = total_items {
            active.total_items = Set(n);
        }
        if let Some(u) = time_unit {
            active.time_unit = Set(u.to_string());
        }
        if let Some(e) = easy_percentage {
            active.easy_percentage = Set(e);
        }
        if let Some(m) = medium_percentage {
            active.medium_percentage = Set(m);
        }
        if let Some(h) = hard_percentage {
            active.hard_percentage = Set(h);
        }
        if let Some(r) = remembering_percentage {
            active.remembering_percentage = Set(r);
        }
        if let Some(u) = understanding_percentage {
            active.understanding_percentage = Set(u);
        }
        if let Some(ap) = applying_percentage {
            active.applying_percentage = Set(ap);
        }
        if let Some(an) = analyzing_percentage {
            active.analyzing_percentage = Set(an);
        }
        if let Some(e) = evaluating_percentage {
            active.evaluating_percentage = Set(e);
        }
        if let Some(c) = creating_percentage {
            active.creating_percentage = Set(c);
        }
        active.updated_at = Set(Utc::now().naive_utc());

        active
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update TOS: {}", e)))
    }

    pub async fn soft_delete_tos(&self, id: Uuid) -> AppResult<()> {
        let tos = table_of_specifications::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        let mut active: table_of_specifications::ActiveModel = tos.into();
        let now = Utc::now().naive_utc();
        active.deleted_at = Set(Some(now));
        active.updated_at = Set(now);

        active
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete TOS: {}", e)))?;

        Ok(())
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
        let now = Utc::now().naive_utc();
        let comp = tos_competencies::ActiveModel {
            id: Set(id),
            tos_id: Set(tos_id),
            competency_code: Set(competency_code.map(|s| s.to_string())),
            competency_text: Set(competency_text.to_string()),
            time_units_taught: Set(time_units_taught),
            order_index: Set(order_index),
            easy_count: Set(easy_count),
            medium_count: Set(medium_count),
            hard_count: Set(hard_count),
            remembering_count: Set(remembering_count),
            understanding_count: Set(understanding_count),
            applying_count: Set(applying_count),
            analyzing_count: Set(analyzing_count),
            evaluating_count: Set(evaluating_count),
            creating_count: Set(creating_count),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };

        comp.insert(&self.db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to create competency: {}", e))
            })
    }

    pub async fn find_competencies_by_tos(
        &self,
        tos_id: Uuid,
    ) -> AppResult<Vec<tos_competencies::Model>> {
        tos_competencies::Entity::find()
            .filter(tos_competencies::Column::TosId.eq(tos_id))
            .filter(tos_competencies::Column::DeletedAt.is_null())
            .order_by_asc(tos_competencies::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_competency_by_id(
        &self,
        id: Uuid,
    ) -> AppResult<Option<tos_competencies::Model>> {
        tos_competencies::Entity::find_by_id(id)
            .filter(tos_competencies::Column::DeletedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
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
        let comp = tos_competencies::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

        let mut active: tos_competencies::ActiveModel = comp.into();

        if let Some(code) = competency_code {
            active.competency_code = Set(code.map(|s| s.to_string()));
        }
        if let Some(text) = competency_text {
            active.competency_text = Set(text.to_string());
        }
        if let Some(units) = time_units_taught {
            active.time_units_taught = Set(units);
        }
        if let Some(idx) = order_index {
            active.order_index = Set(idx);
        }
        if let Some(e) = easy_count {
            active.easy_count = Set(e);
        }
        if let Some(m) = medium_count {
            active.medium_count = Set(m);
        }
        if let Some(h) = hard_count {
            active.hard_count = Set(h);
        }
        if let Some(r) = remembering_count {
            active.remembering_count = Set(r);
        }
        if let Some(u) = understanding_count {
            active.understanding_count = Set(u);
        }
        if let Some(ap) = applying_count {
            active.applying_count = Set(ap);
        }
        if let Some(an) = analyzing_count {
            active.analyzing_count = Set(an);
        }
        if let Some(e) = evaluating_count {
            active.evaluating_count = Set(e);
        }
        if let Some(c) = creating_count {
            active.creating_count = Set(c);
        }
        active.updated_at = Set(Utc::now().naive_utc());

        active
            .update(&self.db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to update competency: {}", e))
            })
    }

    pub async fn soft_delete_competency(&self, id: Uuid) -> AppResult<()> {
        let comp = tos_competencies::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

        let mut active: tos_competencies::ActiveModel = comp.into();
        let now = Utc::now().naive_utc();
        active.deleted_at = Set(Some(now));
        active.updated_at = Set(now);

        active
            .update(&self.db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to delete competency: {}", e))
            })?;

        Ok(())
    }

    pub async fn bulk_create_competencies(
        &self,
        tos_id: Uuid,
        // (code, text, time_units, order, easy_count, medium_count, hard_count,
        //  remembering, understanding, applying, analyzing, evaluating, creating)
        competencies: Vec<(Option<String>, String, i32, i32, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>, Option<i32>)>,
    ) -> AppResult<Vec<tos_competencies::Model>> {
        let mut results = Vec::new();
        for (code, text, units, order, easy, medium, hard, rem, und, app, ana, eva, cre) in competencies {
            let comp = self
                .create_competency(
                    Uuid::new_v4(),
                    tos_id,
                    code.as_deref(),
                    &text,
                    units,
                    order,
                    easy,
                    medium,
                    hard,
                    rem,
                    und,
                    app,
                    ana,
                    eva,
                    cre,
                )
                .await?;
            results.push(comp);
        }
        Ok(results)
    }

    // ===== MELCS SEARCH =====

    pub async fn search_melcs(
        &self,
        subject: Option<&str>,
        grade_level: Option<&str>,
        quarter: Option<i32>,
        query: Option<&str>,
    ) -> AppResult<Vec<MelcRow>> {
        let mut sql = String::from(
            "SELECT id, subject, grade_level, quarter, competency_code, competency_text, domain FROM melcs WHERE 1=1",
        );
        let mut params: Vec<sea_orm::Value> = Vec::new();

        if let Some(s) = subject {
            params.push(s.into());
            sql.push_str(&format!(" AND subject = ${}", params.len()));
        }
        if let Some(g) = grade_level {
            params.push(g.into());
            sql.push_str(&format!(" AND grade_level = ${}", params.len()));
        }
        if let Some(q) = quarter {
            params.push(q.into());
            sql.push_str(&format!(" AND (quarter = ${} OR quarter IS NULL)", params.len()));
        }
        if let Some(text) = query {
            let search_term = format!("%{}%", text);
            params.push(search_term.clone().into());
            let idx = params.len();
            params.push(search_term.into());
            sql.push_str(&format!(
                " AND (competency_text LIKE ${} OR competency_code LIKE ${})",
                idx,
                idx + 1
            ));
            // Fix: we pushed twice, so params.len() is already idx+1
        }

        sql.push_str(" ORDER BY grade_level, quarter, competency_code LIMIT 100");

        let rows = self
            .db
            .query_all(sea_orm::Statement::from_sql_and_values(
                sea_orm::DbBackend::Sqlite,
                &sql,
                params,
            ))
            .await
            .map_err(|e| AppError::InternalServerError(format!("MELCS search error: {}", e)))?;

        let mut results = Vec::new();
        for row in rows {
            results.push(MelcRow {
                id: row.try_get("", "id").unwrap_or(0),
                subject: row.try_get("", "subject").unwrap_or_default(),
                grade_level: row.try_get("", "grade_level").unwrap_or_default(),
                quarter: row.try_get("", "quarter").ok(),
                competency_code: row.try_get("", "competency_code").unwrap_or_default(),
                competency_text: row.try_get("", "competency_text").unwrap_or_default(),
                domain: row.try_get("", "domain").ok(),
            });
        }

        Ok(results)
    }
}

#[derive(Debug)]
pub struct MelcRow {
    pub id: i64,
    pub subject: String,
    pub grade_level: String,
    pub quarter: Option<i32>,
    pub competency_code: String,
    pub competency_text: String,
    pub domain: Option<String>,
}
