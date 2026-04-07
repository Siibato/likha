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
        quarter: i32,
        title: &str,
        classification_mode: &str,
        total_items: i32,
    ) -> AppResult<table_of_specifications::Model> {
        let now = Utc::now().naive_utc();
        let tos = table_of_specifications::ActiveModel {
            id: Set(id),
            class_id: Set(class_id),
            quarter: Set(quarter),
            title: Set(title.to_string()),
            classification_mode: Set(classification_mode.to_string()),
            total_items: Set(total_items),
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
            .order_by_asc(table_of_specifications::Column::Quarter)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_tos_by_class_and_quarter(
        &self,
        class_id: Uuid,
        quarter: i32,
    ) -> AppResult<Option<table_of_specifications::Model>> {
        table_of_specifications::Entity::find()
            .filter(table_of_specifications::Column::ClassId.eq(class_id))
            .filter(table_of_specifications::Column::Quarter.eq(quarter))
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
        days_taught: i32,
        order_index: i32,
    ) -> AppResult<tos_competencies::Model> {
        let now = Utc::now().naive_utc();
        let comp = tos_competencies::ActiveModel {
            id: Set(id),
            tos_id: Set(tos_id),
            competency_code: Set(competency_code.map(|s| s.to_string())),
            competency_text: Set(competency_text.to_string()),
            days_taught: Set(days_taught),
            order_index: Set(order_index),
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
        days_taught: Option<i32>,
        order_index: Option<i32>,
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
        if let Some(days) = days_taught {
            active.days_taught = Set(days);
        }
        if let Some(idx) = order_index {
            active.order_index = Set(idx);
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
        competencies: Vec<(Option<String>, String, i32, i32)>, // (code, text, days, order)
    ) -> AppResult<Vec<tos_competencies::Model>> {
        let mut results = Vec::new();
        for (code, text, days, order) in competencies {
            let comp = self
                .create_competency(
                    Uuid::new_v4(),
                    tos_id,
                    code.as_deref(),
                    &text,
                    days,
                    order,
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
