use crate::modules::class::repository::ClassRepository;
use crate::modules::class::schema::{ClassListResponse, ClassResponse};
use crate::utils::error::{AppError, AppResult};
use ::entity::users;
use std::collections::HashMap;
use uuid::Uuid;

pub async fn get_student_classes(
    class_repo: &ClassRepository,
    student_id: Uuid,
) -> AppResult<ClassListResponse> {
    let classes = class_repo.find_classes_by_student_id(student_id).await?;

    if classes.is_empty() {
        return Ok(ClassListResponse { classes: vec![] });
    }

    let class_ids: Vec<Uuid> = classes.iter().map(|c| c.id).collect();

    // Batch fetch teachers and student counts in 2 queries
    let teachers = class_repo
        .find_teachers_for_classes(class_ids.clone())
        .await?;
    let student_counts = class_repo.count_students_for_classes(class_ids).await?;

    // Build lookup maps
    let teacher_map: HashMap<Uuid, users::Model> = teachers.into_iter().collect();

    let mut class_responses = Vec::new();
    for class in classes {
        let teacher = teacher_map
            .get(&class.id)
            .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

        let student_count = student_counts.get(&class.id).copied().unwrap_or(0);

        class_responses.push(ClassResponse {
            id: class.id,
            title: class.title,
            description: class.description,
            teacher_id: teacher.id,
            teacher_username: teacher.username.clone(),
            teacher_first_name: teacher.first_name.clone(),
            teacher_last_name: teacher.last_name.clone(),
            is_archived: class.is_archived,
            is_advisory: class.is_advisory,
            student_count,
            created_at: class.created_at.to_string(),
            updated_at: class.updated_at.to_string(),
        });
    }

    Ok(ClassListResponse {
        classes: class_responses,
    })
}
