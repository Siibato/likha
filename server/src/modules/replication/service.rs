use chrono::{DateTime, NaiveDateTime, Utc};
use entity::{
    self,
    answer_key_acceptable_answers,
    answer_keys,
    assessment_questions,
    assignment_submissions,
    assignments,
    attendance_records,
    class_participants,
    classes,
    core_values,
    core_values_records,
    grade_items,
    grade_record,
    grade_scores,
    learner_details,
    learning_materials,
    previous_school_attendance,
    previous_school_subjects,
    previous_school_term_grades,
    question_choices,
    school_details,
    student_school_history,
    submission_answer_items,
    submission_answers,
    table_of_specifications,
    teacher_details,
    term_grades,
    tos_competencies,
    users,
};
use sea_orm::prelude::*;
use sea_orm::{
    ColumnTrait,
    Condition,
    DatabaseBackend,
    DatabaseConnection,
    EntityTrait,
    Order,
    QueryFilter,
    QueryOrder,
    QuerySelect,
    Set,
    Statement,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use crate::utils::{AppError, AppResult};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ReplicationDeltaResponse {
    pub server_time: String,
    pub node_id: String,
    pub deltas: ReplicationDeltas,
}

#[derive(Debug, Serialize, Deserialize, Default, Clone)]
pub struct ReplicationDeltas {
    pub users: Vec<Value>,
    pub classes: Vec<Value>,
    pub class_participants: Vec<Value>,
    pub assessments: Vec<Value>,
    pub assessment_questions: Vec<Value>,
    pub question_choices: Vec<Value>,
    pub answer_keys: Vec<Value>,
    pub answer_key_acceptable_answers: Vec<Value>,
    pub assessment_submissions: Vec<Value>,
    pub submission_answers: Vec<Value>,
    pub submission_answer_items: Vec<Value>,
    pub assignments: Vec<Value>,
    pub assignment_submissions: Vec<Value>,
    pub learning_materials: Vec<Value>,
    pub grade_record: Vec<Value>,
    pub grade_items: Vec<Value>,
    pub grade_scores: Vec<Value>,
    pub term_grades: Vec<Value>,
    pub table_of_specifications: Vec<Value>,
    pub tos_competencies: Vec<Value>,
    pub activity_logs: Vec<Value>,
    pub school_details: Vec<Value>,
    pub learner_details: Vec<Value>,
    pub attendance_records: Vec<Value>,
    pub core_values: Vec<Value>,
    pub core_values_records: Vec<Value>,
    pub student_school_history: Vec<Value>,
    pub previous_school_subjects: Vec<Value>,
    pub previous_school_term_grades: Vec<Value>,
    pub previous_school_attendance: Vec<Value>,
    pub teacher_details: Vec<Value>,
}

#[derive(Debug, Deserialize)]
pub struct ReplicationApplyRequest {
    pub source_node_id: String,
    pub deltas: ReplicationDeltas,
}

#[derive(Debug, Serialize)]
pub struct ReplicationApplyResponse {
    pub applied: usize,
    pub skipped: usize,
    pub errors: Vec<String>,
}

#[derive(Clone)]
pub struct ReplicationService {
    db: DatabaseConnection,
    node_id: String,
}

impl ReplicationService {
    pub fn new(db: DatabaseConnection, node_id: String) -> Self {
        Self { db, node_id }
    }

    pub async fn get_deltas(&self, since: Option<String>) -> AppResult<ReplicationDeltaResponse> {
        let since_dt = parse_since_param(since)?;

        let (answer_keys, changed_answer_key_ids) = self.fetch_answer_keys_since(since_dt).await?;
        let answer_key_acceptable_answers = self
            .fetch_acceptable_answers_since(&changed_answer_key_ids)
            .await?;

        let deltas = ReplicationDeltas {
            users: self
                .fetch_since::<users::Entity>(users::Column::UpdatedAt, since_dt)
                .await?,
            classes: self
                .fetch_since::<classes::Entity>(classes::Column::UpdatedAt, since_dt)
                .await?,
            class_participants: self
                .fetch_since::<class_participants::Entity>(
                    class_participants::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            assessments: self
                .fetch_since::<entity::assessments::Entity>(entity::assessments::Column::UpdatedAt, since_dt)
                .await?,
            assessment_questions: self
                .fetch_since::<assessment_questions::Entity>(assessment_questions::Column::UpdatedAt, since_dt)
                .await?,
            question_choices: self
                .fetch_since::<question_choices::Entity>(question_choices::Column::UpdatedAt, since_dt)
                .await?,
            answer_keys,
            answer_key_acceptable_answers,
            assessment_submissions: self
                .fetch_since::<entity::assessment_submissions::Entity>(
                    entity::assessment_submissions::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            submission_answers: self
                .fetch_since::<submission_answers::Entity>(submission_answers::Column::UpdatedAt, since_dt)
                .await?,
            submission_answer_items: self
                .fetch_since::<submission_answer_items::Entity>(
                    submission_answer_items::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            assignments: self
                .fetch_since::<assignments::Entity>(assignments::Column::UpdatedAt, since_dt)
                .await?,
            assignment_submissions: self
                .fetch_since::<assignment_submissions::Entity>(
                    assignment_submissions::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            learning_materials: self
                .fetch_since::<learning_materials::Entity>(learning_materials::Column::UpdatedAt, since_dt)
                .await?,
            grade_record: self
                .fetch_since::<grade_record::Entity>(grade_record::Column::UpdatedAt, since_dt)
                .await?,
            grade_items: self
                .fetch_since::<grade_items::Entity>(grade_items::Column::UpdatedAt, since_dt)
                .await?,
            grade_scores: self
                .fetch_since::<grade_scores::Entity>(grade_scores::Column::UpdatedAt, since_dt)
                .await?,
            term_grades: self
                .fetch_since::<term_grades::Entity>(term_grades::Column::UpdatedAt, since_dt)
                .await?,
            table_of_specifications: self
                .fetch_since::<table_of_specifications::Entity>(
                    table_of_specifications::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            tos_competencies: self
                .fetch_since::<tos_competencies::Entity>(tos_competencies::Column::UpdatedAt, since_dt)
                .await?,
            activity_logs: self
                .fetch_since::<entity::activity_logs::Entity>(
                    entity::activity_logs::Column::CreatedAt,
                    since_dt,
                )
                .await?,
            school_details: self
                .fetch_since::<school_details::Entity>(school_details::Column::UpdatedAt, since_dt)
                .await?,
            learner_details: self
                .fetch_since::<learner_details::Entity>(learner_details::Column::UpdatedAt, since_dt)
                .await?,
            attendance_records: self
                .fetch_since::<attendance_records::Entity>(attendance_records::Column::UpdatedAt, since_dt)
                .await?,
            core_values: self
                .fetch_since::<core_values::Entity>(core_values::Column::UpdatedAt, since_dt)
                .await?,
            core_values_records: self
                .fetch_since::<core_values_records::Entity>(core_values_records::Column::UpdatedAt, since_dt)
                .await?,
            student_school_history: self
                .fetch_since::<student_school_history::Entity>(
                    student_school_history::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            previous_school_subjects: self
                .fetch_since::<previous_school_subjects::Entity>(
                    previous_school_subjects::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            previous_school_term_grades: self
                .fetch_since::<previous_school_term_grades::Entity>(
                    previous_school_term_grades::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            previous_school_attendance: self
                .fetch_since::<previous_school_attendance::Entity>(
                    previous_school_attendance::Column::UpdatedAt,
                    since_dt,
                )
                .await?,
            teacher_details: self
                .fetch_since::<teacher_details::Entity>(teacher_details::Column::UpdatedAt, since_dt)
                .await?,
        };

        Ok(ReplicationDeltaResponse {
            server_time: Utc::now().to_rfc3339(),
            node_id: self.node_id.clone(),
            deltas,
        })
    }

    pub async fn apply_deltas(&self, request: ReplicationApplyRequest) -> AppResult<ReplicationApplyResponse> {
        let mut applied = 0usize;
        let mut skipped = 0usize;
        let mut errors = Vec::new();

        let table_batches = build_batches(&request.deltas);

        for batch in table_batches {
            for row in batch.rows {
                match self
                    .apply_row(batch.table, batch.timestamp_column, row)
                    .await
                {
                    Ok(RowOutcome::Applied) => applied += 1,
                    Ok(RowOutcome::Skipped) => skipped += 1,
                    Err(err) => {
                        errors.push(format!("{}: {}", batch.table, err));
                        tracing::warn!(target: "replication", table = batch.table, "Failed to apply row: {}", err);
                    }
                }
            }
        }

        tracing::info!(
            target: "replication",
            source = %request.source_node_id,
            applied,
            skipped,
            errors = errors.len(),
            "Replication batch applied",
        );

        Ok(ReplicationApplyResponse { applied, skipped, errors })
    }

    pub async fn get_last_sync(&self, peer_node_id: &str) -> AppResult<Option<DateTime<Utc>>> {
        let state = entity::replication_state::Entity::find()
            .filter(entity::replication_state::Column::PeerNodeId.eq(peer_node_id))
            .one(&self.db)
            .await?
            .map(|model| DateTime::<Utc>::from_naive_utc_and_offset(model.last_sync_at, Utc));
        Ok(state)
    }

    pub async fn set_last_sync(&self, peer_node_id: &str, sync_at: DateTime<Utc>) -> AppResult<()> {
        use entity::replication_state::{ActiveModel as ReplicationStateActive, Entity as ReplicationState};

        if let Some(existing) = ReplicationState::find()
            .filter(entity::replication_state::Column::PeerNodeId.eq(peer_node_id))
            .one(&self.db)
            .await?
        {
            let mut active: entity::replication_state::ActiveModel = existing.into();
            active.last_sync_at = Set(sync_at.naive_utc());
            active.updated_at = Set(Utc::now().naive_utc());
            active.update(&self.db).await?;
        } else {
            let active = ReplicationStateActive {
                id: Set(Uuid::new_v4().to_string()),
                peer_node_id: Set(peer_node_id.to_string()),
                last_sync_at: Set(sync_at.naive_utc()),
                last_sync_sequence: Set(0),
                created_at: Set(Utc::now().naive_utc()),
                updated_at: Set(Utc::now().naive_utc()),
            };
            active.insert(&self.db).await?;
        }

        Ok(())
    }

    async fn fetch_since<E>(&self, column: <E as EntityTrait>::Column, since: NaiveDateTime) -> AppResult<Vec<Value>>
    where
        E: EntityTrait,
        E::Model: Serialize,
        <E as EntityTrait>::Column: Copy + ColumnTrait,
    {
        let models = E::find()
            .filter(column.gt(since))
            .order_by(column, Order::Asc)
            .all(&self.db)
            .await?;

        Ok(models
            .into_iter()
            .filter_map(|model| serde_json::to_value(model).ok())
            .collect())
    }

    async fn fetch_answer_keys_since(
        &self,
        since: NaiveDateTime,
    ) -> AppResult<(Vec<Value>, Vec<Uuid>)> {
        let updated_question_ids: Vec<Uuid> = assessment_questions::Entity::find()
            .filter(assessment_questions::Column::UpdatedAt.gt(since))
            .select_only()
            .column(assessment_questions::Column::Id)
            .into_tuple()
            .all(&self.db)
            .await?;

        let mut condition = Condition::any().add(answer_keys::Column::UpdatedAt.gt(since));
        if !updated_question_ids.is_empty() {
            condition = condition.add(answer_keys::Column::QuestionId.is_in(updated_question_ids.clone()));
        }

        let models = answer_keys::Entity::find()
            .filter(condition)
            .order_by(answer_keys::Column::UpdatedAt, Order::Asc)
            .all(&self.db)
            .await?;

        let ids: Vec<Uuid> = models.iter().map(|m| m.id).collect();
        let values = models
            .into_iter()
            .filter_map(|model| serde_json::to_value(model).ok())
            .collect();

        Ok((values, ids))
    }

    async fn fetch_acceptable_answers_since(
        &self,
        answer_key_ids: &[Uuid],
    ) -> AppResult<Vec<Value>> {
        if answer_key_ids.is_empty() {
            return Ok(Vec::new());
        }

        let models = answer_key_acceptable_answers::Entity::find()
            .filter(answer_key_acceptable_answers::Column::AnswerKeyId.is_in(answer_key_ids.iter().cloned()))
            .all(&self.db)
            .await?;

        Ok(models
            .into_iter()
            .filter_map(|model| serde_json::to_value(model).ok())
            .collect())
    }

    async fn apply_row(
        &self,
        table: &str,
        timestamp_column: Option<&str>,
        row: &Value,
    ) -> AppResult<RowOutcome> {
        let obj = row
            .as_object()
            .ok_or_else(|| AppError::BadRequest("row is not a JSON object".into()))?;

        let id_value = obj
            .get("id")
            .ok_or_else(|| AppError::BadRequest("missing id field".into()))?;

        let incoming_ts = timestamp_column
            .and_then(|col| obj.get(col))
            .and_then(|value| serde_json::from_value::<NaiveDateTime>(value.clone()).ok());

        if let (Some(col), Some(ts)) = (timestamp_column, incoming_ts) {
            if let Some(existing_ts) = self
                .fetch_existing_timestamp(table, col, id_value.clone())
                .await?
            {
                if ts <= existing_ts {
                    return Ok(RowOutcome::Skipped);
                }
            }
        }

        let mut columns: Vec<&String> = obj.keys().collect();
        columns.sort();

        let placeholders = vec!["?"; columns.len()].join(", ");
        let col_list = columns
            .iter()
            .map(|c| c.as_str())
            .collect::<Vec<_>>()
            .join(", ");
        let sql = format!(
            "INSERT OR REPLACE INTO {} ({}) VALUES ({})",
            table, col_list, placeholders
        );

        let values: Vec<sea_orm::Value> = columns
            .iter()
            .map(|key| json_to_sea_value(obj.get(*key).unwrap()))
            .collect();

        let stmt = Statement::from_sql_and_values(DatabaseBackend::Sqlite, &sql, values);
        self.db.execute(stmt).await?;

        Ok(RowOutcome::Applied)
    }

    async fn fetch_existing_timestamp(
        &self,
        table: &str,
        column: &str,
        id_value: Value,
    ) -> AppResult<Option<NaiveDateTime>> {
        let sql = format!("SELECT {} FROM {} WHERE id = ?", column, table);
        let stmt = Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            &sql,
            vec![json_to_sea_value(&id_value)],
        );

        if let Some(row) = self.db.query_one(stmt).await? {
            let ts: Option<NaiveDateTime> = row.try_get("", column).ok();
            return Ok(ts);
        }

        Ok(None)
    }
}

fn parse_since_param(since: Option<String>) -> AppResult<NaiveDateTime> {
    match since {
        Some(raw) => {
            let parsed = DateTime::parse_from_rfc3339(&raw)
                .map_err(|err| AppError::BadRequest(format!("invalid since parameter: {}", err)))?;
            Ok(parsed.naive_utc())
        }
        None => DateTime::<Utc>::from_timestamp(0, 0)
            .map(|dt| dt.naive_utc())
            .ok_or_else(|| AppError::InternalServerError("failed to construct UNIX_EPOCH".into())),
    }
}

#[derive(Clone, Copy)]
struct TableBatch<'a> {
    table: &'static str,
    timestamp_column: Option<&'static str>,
    rows: &'a [Value],
}

fn build_batches(deltas: &ReplicationDeltas) -> Vec<TableBatch<'_>> {
    vec![
        TableBatch {
            table: "users",
            timestamp_column: Some("updated_at"),
            rows: &deltas.users,
        },
        TableBatch {
            table: "classes",
            timestamp_column: Some("updated_at"),
            rows: &deltas.classes,
        },
        TableBatch {
            table: "class_participants",
            timestamp_column: Some("updated_at"),
            rows: &deltas.class_participants,
        },
        TableBatch {
            table: "assessments",
            timestamp_column: Some("updated_at"),
            rows: &deltas.assessments,
        },
        TableBatch {
            table: "assessment_questions",
            timestamp_column: Some("updated_at"),
            rows: &deltas.assessment_questions,
        },
        TableBatch {
            table: "question_choices",
            timestamp_column: Some("updated_at"),
            rows: &deltas.question_choices,
        },
        TableBatch {
            table: "answer_keys",
            timestamp_column: Some("updated_at"),
            rows: &deltas.answer_keys,
        },
        TableBatch {
            table: "answer_key_acceptable_answers",
            timestamp_column: None,
            rows: &deltas.answer_key_acceptable_answers,
        },
        TableBatch {
            table: "assessment_submissions",
            timestamp_column: Some("updated_at"),
            rows: &deltas.assessment_submissions,
        },
        TableBatch {
            table: "submission_answers",
            timestamp_column: Some("updated_at"),
            rows: &deltas.submission_answers,
        },
        TableBatch {
            table: "submission_answer_items",
            timestamp_column: Some("updated_at"),
            rows: &deltas.submission_answer_items,
        },
        TableBatch {
            table: "assignments",
            timestamp_column: Some("updated_at"),
            rows: &deltas.assignments,
        },
        TableBatch {
            table: "assignment_submissions",
            timestamp_column: Some("updated_at"),
            rows: &deltas.assignment_submissions,
        },
        TableBatch {
            table: "learning_materials",
            timestamp_column: Some("updated_at"),
            rows: &deltas.learning_materials,
        },
        TableBatch {
            table: "grade_record",
            timestamp_column: Some("updated_at"),
            rows: &deltas.grade_record,
        },
        TableBatch {
            table: "grade_items",
            timestamp_column: Some("updated_at"),
            rows: &deltas.grade_items,
        },
        TableBatch {
            table: "grade_scores",
            timestamp_column: Some("updated_at"),
            rows: &deltas.grade_scores,
        },
        TableBatch {
            table: "term_grades",
            timestamp_column: Some("updated_at"),
            rows: &deltas.term_grades,
        },
        TableBatch {
            table: "table_of_specifications",
            timestamp_column: Some("updated_at"),
            rows: &deltas.table_of_specifications,
        },
        TableBatch {
            table: "tos_competencies",
            timestamp_column: Some("updated_at"),
            rows: &deltas.tos_competencies,
        },
        TableBatch {
            table: "activity_logs",
            timestamp_column: Some("created_at"),
            rows: &deltas.activity_logs,
        },
        TableBatch {
            table: "school_details",
            timestamp_column: Some("updated_at"),
            rows: &deltas.school_details,
        },
        TableBatch {
            table: "learner_details",
            timestamp_column: Some("updated_at"),
            rows: &deltas.learner_details,
        },
        TableBatch {
            table: "attendance_records",
            timestamp_column: Some("updated_at"),
            rows: &deltas.attendance_records,
        },
        TableBatch {
            table: "core_values",
            timestamp_column: Some("updated_at"),
            rows: &deltas.core_values,
        },
        TableBatch {
            table: "core_values_records",
            timestamp_column: Some("updated_at"),
            rows: &deltas.core_values_records,
        },
        TableBatch {
            table: "student_school_history",
            timestamp_column: Some("updated_at"),
            rows: &deltas.student_school_history,
        },
        TableBatch {
            table: "previous_school_subjects",
            timestamp_column: Some("updated_at"),
            rows: &deltas.previous_school_subjects,
        },
        TableBatch {
            table: "previous_school_term_grades",
            timestamp_column: Some("updated_at"),
            rows: &deltas.previous_school_term_grades,
        },
        TableBatch {
            table: "previous_school_attendance",
            timestamp_column: Some("updated_at"),
            rows: &deltas.previous_school_attendance,
        },
        TableBatch {
            table: "teacher_details",
            timestamp_column: Some("updated_at"),
            rows: &deltas.teacher_details,
        },
    ]
}

#[derive(Debug)]
enum RowOutcome {
    Applied,
    Skipped,
}

fn json_to_sea_value(value: &Value) -> sea_orm::Value {
    match value {
        Value::Null => sea_orm::Value::String(None),
        Value::Bool(b) => sea_orm::Value::Bool(Some(*b)),
        Value::Number(num) => {
            if let Some(i) = num.as_i64() {
                sea_orm::Value::BigInt(Some(i))
            } else if let Some(u) = num.as_u64() {
                sea_orm::Value::BigUnsigned(Some(u))
            } else if let Some(f) = num.as_f64() {
                sea_orm::Value::Double(Some(f))
            } else {
                sea_orm::Value::Double(None)
            }
        }
        Value::String(s) => sea_orm::Value::String(Some(Box::new(s.clone()))),
        Value::Array(_) | Value::Object(_) => {
            sea_orm::Value::String(Some(Box::new(value.to_string())))
        }
    }
}
