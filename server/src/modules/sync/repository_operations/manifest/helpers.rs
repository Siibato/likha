use sea_orm::*;
use serde_json::Value;
use uuid::Uuid;

use ::entity::{
    class_participants, users,
    grade_record, grade_items, grade_scores, term_grades,
    table_of_specifications, tos_competencies,
    learner_details, attendance_records, core_values_records,
    student_school_history, previous_school_subjects, previous_school_attendance,
};
use crate::utils::{AppError, AppResult};
use super::{ManifestEntry, PaginatedRecords};

/// Build a map of class_id -> (teacher_id, teacher_username, teacher_full_name)
pub async fn build_teacher_map(
    db: &DatabaseConnection,
    class_ids: &[Uuid],
) -> AppResult<std::collections::HashMap<Uuid, (Uuid, String, String)>> {
    let participants = class_participants::Entity::find()
        .filter(class_participants::Column::ClassId.is_in(class_ids.to_vec()))
        .filter(class_participants::Column::RemovedAt.is_null())
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

    let mut map = std::collections::HashMap::new();

    for participant in participants {
        if let Ok(Some(user)) = users::Entity::find_by_id(participant.user_id)
            .one(db)
            .await
        {
            if user.role == "teacher" {
                map.insert(
                    participant.class_id,
                    (user.id, user.username.clone(), user.full_name.clone()),
                );
            }
        }
    }

    Ok(map)
}

/// Sync data fetch helper — returns all requested records up to the
/// caller-supplied limit. Callers are responsible for setting appropriate
/// bounds. This does NOT silently truncate.
pub async fn paginate_query<E, F>(
    db: &DatabaseConnection,
    query: Select<E>,
    limit: i64,
    mapper: F,
) -> AppResult<PaginatedRecords>
where
    E: EntityTrait,
    E::Model: Send + Sync,
    F: Fn(E::Model) -> Value,
{
    let effective_limit = limit as u64;
    let records = query
        .limit(effective_limit)
        .all(db)
        .await
        .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
    let records: Vec<Value> = records
        .into_iter()
        .map(mapper)
        .collect();
    Ok(PaginatedRecords { records })
}

pub fn grade_config_to_json(r: grade_record::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "class_id": r.class_id.to_string(),
        "term_number": r.term_number,
        "ww_weight": r.ww_weight,
        "pt_weight": r.pt_weight,
        "qa_weight": r.qa_weight,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
        "deleted_at": r.deleted_at.map(|d| d.to_string()),
    })
}

pub fn tos_to_json(r: table_of_specifications::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "class_id": r.class_id.to_string(),
        "term_number": r.term_number,
        "title": r.title,
        "classification_mode": r.classification_mode,
        "total_items": r.total_items,
        "time_unit": r.time_unit,
        "easy_percentage": r.easy_percentage,
        "medium_percentage": r.medium_percentage,
        "hard_percentage": r.hard_percentage,
        "remembering_percentage": r.remembering_percentage,
        "understanding_percentage": r.understanding_percentage,
        "applying_percentage": r.applying_percentage,
        "analyzing_percentage": r.analyzing_percentage,
        "evaluating_percentage": r.evaluating_percentage,
        "creating_percentage": r.creating_percentage,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
        "deleted_at": r.deleted_at.map(|d| d.to_string()),
    })
}

pub fn tos_competency_to_json(r: tos_competencies::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "tos_id": r.tos_id.to_string(),
        "competency_code": r.competency_code,
        "competency_text": r.competency_text,
        "time_units_taught": r.time_units_taught,
        "order_index": r.order_index,
        "easy_count": r.easy_count,
        "medium_count": r.medium_count,
        "hard_count": r.hard_count,
        "remembering_count": r.remembering_count,
        "understanding_count": r.understanding_count,
        "applying_count": r.applying_count,
        "analyzing_count": r.analyzing_count,
        "evaluating_count": r.evaluating_count,
        "creating_count": r.creating_count,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
        "deleted_at": r.deleted_at.map(|d| d.to_string()),
    })
}

pub fn grade_item_to_json(r: grade_items::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "class_id": r.class_id.to_string(),
        "title": r.title,
        "component": r.component,
        "term_number": r.term_number,
        "total_points": r.total_points,
        "source_type": r.source_type,
        "source_id": r.source_id,
        "order_index": r.order_index,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
        "deleted_at": r.deleted_at.map(|d| d.to_string()),
    })
}

pub fn grade_score_to_json(r: grade_scores::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "grade_item_id": r.grade_item_id.to_string(),
        "student_id": r.student_id.to_string(),
        "score": r.score,
        "is_auto_populated": r.is_auto_populated,
        "override_score": r.override_score,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
        "deleted_at": r.deleted_at.map(|d| d.to_string()),
    })
}

pub fn period_grade_to_json(r: term_grades::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "class_id": r.class_id.to_string(),
        "student_id": r.student_id.to_string(),
        "term_number": r.term_number,
        "initial_grade": r.initial_grade,
        "transmuted_grade": r.transmuted_grade,
        "is_locked": r.is_locked,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
        "deleted_at": r.deleted_at.map(|d| d.to_string()),
    })
}

pub fn learner_details_to_json(r: learner_details::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "user_id": r.user_id.to_string(),
        "lrn": r.lrn,
        "age": r.age,
        "sex": r.sex,
        "track_strand": r.track_strand,
        "curriculum": r.curriculum,
        "birthdate": r.birthdate.map(|d| d.to_string()),
        "birthplace": r.birthplace,
        "home_address": r.home_address,
        "father_name": r.father_name,
        "father_contact": r.father_contact,
        "mother_name": r.mother_name,
        "mother_contact": r.mother_contact,
        "guardian_name": r.guardian_name,
        "guardian_contact": r.guardian_contact,
        "date_admitted": r.date_admitted.map(|d| d.to_string()),
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
        "deleted_at": r.deleted_at.map(|d| d.to_string()),
    })
}

pub fn attendance_record_to_json(r: attendance_records::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "student_id": r.student_id.to_string(),
        "class_id": r.class_id.to_string(),
        "school_year": r.school_year,
        "month": r.month,
        "school_days": r.school_days,
        "days_present": r.days_present,
        "days_absent": r.days_absent,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
    })
}

pub fn core_values_record_to_json(r: core_values_records::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "student_id": r.student_id.to_string(),
        "class_id": r.class_id.to_string(),
        "school_year": r.school_year,
        "term_number": r.term_number,
        "core_value": r.core_value,
        "behavior_statement": r.behavior_statement,
        "marking": r.marking,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
    })
}

pub fn school_history_to_json(r: student_school_history::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "student_id": r.student_id.to_string(),
        "school_name": r.school_name,
        "school_id": r.school_id,
        "grade_level": r.grade_level,
        "school_year": r.school_year,
        "section": r.section,
        "date_from": r.date_from.map(|d| d.to_string()),
        "date_to": r.date_to.map(|d| d.to_string()),
        "record_type": r.record_type,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
    })
}

pub fn previous_school_subject_to_json(r: previous_school_subjects::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "student_id": r.student_id.to_string(),
        "school_history_id": r.school_history_id.to_string(),
        "subject_name": r.subject_name,
        "subject_group": r.subject_group,
        "q1_grade": r.q1_grade,
        "q2_grade": r.q2_grade,
        "q3_grade": r.q3_grade,
        "q4_grade": r.q4_grade,
        "final_grade": r.final_grade,
        "descriptor": r.descriptor,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
    })
}

pub fn previous_school_attendance_to_json(r: previous_school_attendance::Model) -> Value {
    serde_json::json!({
        "id": r.id.to_string(),
        "student_id": r.student_id.to_string(),
        "school_history_id": r.school_history_id.to_string(),
        "school_year": r.school_year,
        "month": r.month,
        "school_days": r.school_days,
        "days_present": r.days_present,
        "days_absent": r.days_absent,
        "created_at": r.created_at.to_string(),
        "updated_at": r.updated_at.to_string(),
    })
}

/// Helper to collect manifest entries from a model vec using field accessors
pub fn make_manifest_entry(id: Uuid, updated_at: chrono::NaiveDateTime, deleted: bool) -> ManifestEntry {
    ManifestEntry { id, updated_at, deleted }
}
