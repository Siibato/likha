use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

use ::entity::{
    grade_record, grade_items, grade_scores, period_grades, class_participants,
};
use crate::utils::{AppError, AppResult};

pub struct GradeComputationRepository {
    db: DatabaseConnection,
}

impl GradeComputationRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    // ===== GRADE RECORD (formerly grade_components_config) =====

    pub async fn get_config(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Option<grade_record::Model>> {
        grade_record::Entity::find()
            .filter(grade_record::Column::ClassId.eq(class_id))
            .filter(grade_record::Column::GradingPeriodNumber.eq(grading_period_number))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn get_all_configs(
        &self,
        class_id: Uuid,
    ) -> AppResult<Vec<grade_record::Model>> {
        grade_record::Entity::find()
            .filter(grade_record::Column::ClassId.eq(class_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn upsert_config(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
        ww_weight: f64,
        pt_weight: f64,
        qa_weight: f64,
    ) -> AppResult<grade_record::Model> {
        let now = Utc::now().naive_utc();
        let id = Uuid::new_v4();

        let sql = r#"
            INSERT INTO grade_record (id, class_id, grading_period_number, ww_weight, pt_weight, qa_weight, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(class_id, grading_period_number) DO UPDATE SET
                ww_weight = excluded.ww_weight,
                pt_weight = excluded.pt_weight,
                qa_weight = excluded.qa_weight,
                updated_at = excluded.updated_at
        "#;

        let stmt = Statement::from_sql_and_values(
            DbBackend::Sqlite,
            sql,
            vec![
                id.into(),
                class_id.into(),
                grading_period_number.into(),
                ww_weight.into(),
                pt_weight.into(),
                qa_weight.into(),
                now.into(),
                now.into(),
            ],
        );

        self.db
            .execute(stmt)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to upsert config: {}", e)))?;

        self.get_config(class_id, grading_period_number)
            .await?
            .ok_or_else(|| AppError::InternalServerError("Config not found after upsert".to_string()))
    }

    pub async fn setup_defaults(
        &self,
        class_id: Uuid,
        subject_group: &str,
    ) -> AppResult<Vec<grade_record::Model>> {
        let preset = crate::services::grade_computation::deped_weights::get_preset(subject_group)
            .ok_or_else(|| {
                AppError::BadRequest(format!(
                    "Unknown subject group '{}'. No DepEd preset found.",
                    subject_group
                ))
            })?;

        let mut configs = Vec::new();
        for period in 1..=4 {
            let config = self
                .upsert_config(class_id, period, preset.ww, preset.pt, preset.qa)
                .await?;
            configs.push(config);
        }

        Ok(configs)
    }

    // ===== GRADE ITEMS =====

    pub async fn get_items(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<grade_items::Model>> {
        grade_items::Entity::find()
            .filter(grade_items::Column::ClassId.eq(class_id))
            .filter(grade_items::Column::GradingPeriodNumber.eq(grading_period_number))
            .filter(grade_items::Column::DeletedAt.is_null())
            .order_by_asc(grade_items::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn get_items_by_component(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
        component: &str,
    ) -> AppResult<Vec<grade_items::Model>> {
        grade_items::Entity::find()
            .filter(grade_items::Column::ClassId.eq(class_id))
            .filter(grade_items::Column::GradingPeriodNumber.eq(grading_period_number))
            .filter(grade_items::Column::Component.eq(component))
            .filter(grade_items::Column::DeletedAt.is_null())
            .order_by_asc(grade_items::Column::OrderIndex)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_item(&self, id: Uuid) -> AppResult<Option<grade_items::Model>> {
        grade_items::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_source(
        &self,
        source_type: &str,
        source_id: &str,
    ) -> AppResult<Option<grade_items::Model>> {
        grade_items::Entity::find()
            .filter(grade_items::Column::SourceType.eq(source_type))
            .filter(grade_items::Column::SourceId.eq(source_id))
            .filter(grade_items::Column::DeletedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn create_item(
        &self,
        class_id: Uuid,
        title: String,
        component: String,
        grading_period_number: Option<i32>,
        total_points: f64,
        source_type: String,
        source_id: Option<String>,
        order_index: i32,
    ) -> AppResult<grade_items::Model> {
        let item = grade_items::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(class_id),
            title: Set(title),
            component: Set(component),
            grading_period_number: Set(grading_period_number),
            total_points: Set(total_points),
            source_type: Set(source_type),
            source_id: Set(source_id),
            order_index: Set(order_index),
            created_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            deleted_at: Set(None),
        };

        item.insert(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create grade item: {}", e)))
    }

    pub async fn update_item(
        &self,
        id: Uuid,
        title: Option<String>,
        component: Option<String>,
        total_points: Option<f64>,
        order_index: Option<i32>,
    ) -> AppResult<grade_items::Model> {
        let mut item: grade_items::ActiveModel = grade_items::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Grade item not found".to_string()))?
            .into();

        if let Some(title) = title {
            item.title = Set(title);
        }
        if let Some(component) = component {
            item.component = Set(component);
        }
        if let Some(total_points) = total_points {
            item.total_points = Set(total_points);
        }
        if let Some(order_index) = order_index {
            item.order_index = Set(order_index);
        }
        item.updated_at = Set(Utc::now().naive_utc());

        item.update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update grade item: {}", e)))
    }

    pub async fn soft_delete_item(&self, id: Uuid) -> AppResult<()> {
        let mut item: grade_items::ActiveModel = grade_items::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Grade item not found".to_string()))?
            .into();

        item.deleted_at = Set(Some(Utc::now().naive_utc()));
        item.updated_at = Set(Utc::now().naive_utc());

        item.update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to soft delete grade item: {}", e)))?;

        Ok(())
    }

    // ===== GRADE SCORES =====

    pub async fn get_scores_by_item(
        &self,
        grade_item_id: Uuid,
    ) -> AppResult<Vec<grade_scores::Model>> {
        grade_scores::Entity::find()
            .filter(grade_scores::Column::GradeItemId.eq(grade_item_id))
            .filter(grade_scores::Column::DeletedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn get_scores_by_student_class_period(
        &self,
        student_id: Uuid,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<grade_scores::Model>> {
        let sql = r#"
            SELECT gs.id, gs.grade_item_id, gs.student_id, gs.score,
                   gs.is_auto_populated, gs.override_score,
                   gs.created_at, gs.updated_at, gs.deleted_at
            FROM grade_scores gs
            INNER JOIN grade_items gi ON gs.grade_item_id = gi.id
            WHERE gs.student_id = ?
              AND gi.class_id = ?
              AND gi.grading_period_number = ?
              AND gs.deleted_at IS NULL
              AND gi.deleted_at IS NULL
        "#;

        let stmt = Statement::from_sql_and_values(
            DbBackend::Sqlite,
            sql,
            vec![
                student_id.to_string().into(),
                class_id.to_string().into(),
                grading_period_number.into(),
            ],
        );

        let rows = self
            .db
            .query_all(stmt)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        let mut scores = Vec::new();
        for row in rows {
            let id: String = row
                .try_get("", "id")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
            let grade_item_id: String = row
                .try_get("", "grade_item_id")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
            let student_id_str: String = row
                .try_get("", "student_id")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
            let score: Option<f64> = row
                .try_get("", "score")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
            let is_auto_populated: bool = row
                .try_get("", "is_auto_populated")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
            let override_score: Option<f64> = row
                .try_get("", "override_score")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
            let created_at: String = row
                .try_get("", "created_at")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
            let updated_at: String = row
                .try_get("", "updated_at")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;
            let deleted_at: Option<String> = row
                .try_get("", "deleted_at")
                .map_err(|e| AppError::InternalServerError(format!("Row parse error: {}", e)))?;

            scores.push(grade_scores::Model {
                id: Uuid::parse_str(&id)
                    .map_err(|e| AppError::InternalServerError(format!("UUID parse error: {}", e)))?,
                grade_item_id: Uuid::parse_str(&grade_item_id)
                    .map_err(|e| AppError::InternalServerError(format!("UUID parse error: {}", e)))?,
                student_id: Uuid::parse_str(&student_id_str)
                    .map_err(|e| AppError::InternalServerError(format!("UUID parse error: {}", e)))?,
                score,
                is_auto_populated,
                override_score,
                created_at: chrono::NaiveDateTime::parse_from_str(&created_at, "%Y-%m-%d %H:%M:%S%.f")
                    .or_else(|_| chrono::NaiveDateTime::parse_from_str(&created_at, "%Y-%m-%dT%H:%M:%S%.f"))
                    .map_err(|e| AppError::InternalServerError(format!("DateTime parse error: {}", e)))?,
                updated_at: chrono::NaiveDateTime::parse_from_str(&updated_at, "%Y-%m-%d %H:%M:%S%.f")
                    .or_else(|_| chrono::NaiveDateTime::parse_from_str(&updated_at, "%Y-%m-%dT%H:%M:%S%.f"))
                    .map_err(|e| AppError::InternalServerError(format!("DateTime parse error: {}", e)))?,
                deleted_at: deleted_at
                    .map(|dt| {
                        chrono::NaiveDateTime::parse_from_str(&dt, "%Y-%m-%d %H:%M:%S%.f")
                            .or_else(|_| chrono::NaiveDateTime::parse_from_str(&dt, "%Y-%m-%dT%H:%M:%S%.f"))
                    })
                    .transpose()
                    .map_err(|e| AppError::InternalServerError(format!("DateTime parse error: {}", e)))?,
            });
        }

        Ok(scores)
    }

    pub async fn upsert_score(
        &self,
        grade_item_id: Uuid,
        student_id: Uuid,
        score: Option<f64>,
        is_auto_populated: bool,
    ) -> AppResult<grade_scores::Model> {
        let now = Utc::now().naive_utc();
        let id = Uuid::new_v4();

        let sql = r#"
            INSERT INTO grade_scores (id, grade_item_id, student_id, score, is_auto_populated, override_score, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, (SELECT override_score FROM grade_scores WHERE grade_item_id = ? AND student_id = ?), ?, ?)
            ON CONFLICT(grade_item_id, student_id) DO UPDATE SET
                score = excluded.score,
                is_auto_populated = excluded.is_auto_populated,
                updated_at = excluded.updated_at
        "#;

        let stmt = Statement::from_sql_and_values(
            DbBackend::Sqlite,
            sql,
            vec![
                id.to_string().into(),
                grade_item_id.to_string().into(),
                student_id.to_string().into(),
                score.map(Value::from).unwrap_or(Value::Double(None)),
                is_auto_populated.into(),
                grade_item_id.to_string().into(),
                student_id.to_string().into(),
                now.to_string().into(),
                now.to_string().into(),
            ],
        );

        self.db
            .execute(stmt)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to upsert score: {}", e)))?;

        grade_scores::Entity::find()
            .filter(grade_scores::Column::GradeItemId.eq(grade_item_id))
            .filter(grade_scores::Column::StudentId.eq(student_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::InternalServerError("Score not found after upsert".to_string()))
    }

    pub async fn bulk_upsert_scores(
        &self,
        grade_item_id: Uuid,
        scores: Vec<(Uuid, f64)>,
    ) -> AppResult<()> {
        for (student_id, score) in scores {
            self.upsert_score(grade_item_id, student_id, Some(score), false)
                .await?;
        }
        Ok(())
    }

    pub async fn set_override(
        &self,
        id: Uuid,
        override_score: f64,
    ) -> AppResult<grade_scores::Model> {
        let mut score: grade_scores::ActiveModel = grade_scores::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Grade score not found".to_string()))?
            .into();

        score.override_score = Set(Some(override_score));
        score.updated_at = Set(Utc::now().naive_utc());

        score
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to set override: {}", e)))
    }

    pub async fn clear_override(&self, id: Uuid) -> AppResult<grade_scores::Model> {
        let mut score: grade_scores::ActiveModel = grade_scores::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Grade score not found".to_string()))?
            .into();

        score.override_score = Set(None);
        score.updated_at = Set(Utc::now().naive_utc());

        score
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to clear override: {}", e)))
    }

    // ===== PERIOD GRADES (formerly quarterly_grades) =====

    pub async fn get_period_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Option<period_grades::Model>> {
        period_grades::Entity::find()
            .filter(period_grades::Column::ClassId.eq(class_id))
            .filter(period_grades::Column::StudentId.eq(student_id))
            .filter(period_grades::Column::GradingPeriodNumber.eq(grading_period_number))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn get_all_for_class(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<period_grades::Model>> {
        period_grades::Entity::find()
            .filter(period_grades::Column::ClassId.eq(class_id))
            .filter(period_grades::Column::GradingPeriodNumber.eq(grading_period_number))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn get_all_for_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<Vec<period_grades::Model>> {
        period_grades::Entity::find()
            .filter(period_grades::Column::ClassId.eq(class_id))
            .filter(period_grades::Column::StudentId.eq(student_id))
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn upsert_period_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        grading_period_number: i32,
        initial_grade: f64,
        transmuted_grade: i32,
        is_locked: bool,
    ) -> AppResult<period_grades::Model> {
        let now = Utc::now().naive_utc();
        let id = Uuid::new_v4();

        let sql = r#"
            INSERT INTO period_grades (id, class_id, student_id, grading_period_number,
                initial_grade, transmuted_grade, is_locked, computed_at,
                created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(class_id, student_id, grading_period_number) DO UPDATE SET
                initial_grade = excluded.initial_grade,
                transmuted_grade = excluded.transmuted_grade,
                is_locked = excluded.is_locked,
                computed_at = excluded.computed_at,
                updated_at = excluded.updated_at
        "#;

        let stmt = Statement::from_sql_and_values(
            DbBackend::Sqlite,
            sql,
            vec![
                id.to_string().into(),
                class_id.to_string().into(),
                student_id.to_string().into(),
                grading_period_number.into(),
                initial_grade.into(),
                transmuted_grade.into(),
                is_locked.into(),
                now.to_string().into(),
                now.to_string().into(),
                now.to_string().into(),
            ],
        );

        self.db
            .execute(stmt)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to upsert period grade: {}", e))
            })?;

        self.get_period_grade(class_id, student_id, grading_period_number)
            .await?
            .ok_or_else(|| {
                AppError::InternalServerError(
                    "Period grade not found after upsert".to_string(),
                )
            })
    }

    // ===== HELPER =====

    pub async fn get_enrolled_student_ids(&self, class_id: Uuid) -> AppResult<Vec<Uuid>> {
        let participants = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(participants.into_iter().map(|p| p.user_id).collect())
    }

    // ===== CROSS-CLASS QUERIES (GSA / SF9) =====

    /// Get all classes a student is enrolled in, optionally filtered by school_year.
    /// Returns (class_id, title, school_year).
    pub async fn get_student_enrolled_classes(
        &self,
        student_id: Uuid,
        school_year: Option<&str>,
    ) -> AppResult<Vec<StudentEnrolledClass>> {
        let mut sql = String::from(
            r#"
            SELECT c.id, c.title, c.school_year
            FROM classes c
            JOIN class_participants cp ON cp.class_id = c.id
            WHERE cp.user_id = $1
              AND cp.removed_at IS NULL
              AND c.deleted_at IS NULL
            "#,
        );
        let mut params: Vec<sea_orm::Value> = vec![student_id.into()];

        if let Some(sy) = school_year {
            params.push(sy.into());
            sql.push_str(&format!(" AND c.school_year = ${}", params.len()));
        }

        sql.push_str(" ORDER BY c.title");

        let rows = self
            .db
            .query_all(sea_orm::Statement::from_sql_and_values(
                sea_orm::DbBackend::Sqlite,
                &sql,
                params,
            ))
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to get student classes: {}", e))
            })?;

        let mut results = Vec::new();
        for row in rows {
            let id_str: String = row.try_get("", "id").unwrap_or_default();
            results.push(StudentEnrolledClass {
                class_id: Uuid::parse_str(&id_str).unwrap_or_default(),
                title: row.try_get("", "title").unwrap_or_default(),
                school_year: row.try_get("", "school_year").ok(),
            });
        }

        Ok(results)
    }

    /// Get all period grades for a student in a specific class.
    pub async fn get_period_grades_for_student_class(
        &self,
        student_id: Uuid,
        class_id: Uuid,
    ) -> AppResult<Vec<period_grades::Model>> {
        period_grades::Entity::find()
            .filter(period_grades::Column::StudentId.eq(student_id))
            .filter(period_grades::Column::ClassId.eq(class_id))
            .filter(period_grades::Column::DeletedAt.is_null())
            .order_by_asc(period_grades::Column::GradingPeriodNumber)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }
}

#[derive(Debug)]
pub struct StudentEnrolledClass {
    pub class_id: Uuid,
    pub title: String,
    pub school_year: Option<String>,
}
