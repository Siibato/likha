use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::class::schema::{ClassResponse, ClassListResponse};
use crate::modules::class::repository::ClassRepository;

pub async fn get_student_classes(
    class_repo: &ClassRepository,
    student_id: Uuid,
) -> AppResult<ClassListResponse> {
    let classes = class_repo.find_classes_by_student_id(student_id).await?;

    let mut class_responses = Vec::new();
    for class in classes {
        let teacher = class_repo
            .find_teacher_of_class(class.id)
            .await?
            .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

        let student_count = class_repo.count_students_in_class(class.id).await?;
        class_responses.push(ClassResponse {
            id: class.id,
            title: class.title,
            description: class.description,
            teacher_id: teacher.id,
            teacher_username: teacher.username,
            teacher_full_name: teacher.full_name,
            is_archived: class.is_archived,
            is_advisory: class.is_advisory,
            student_count,
            created_at: class.created_at.to_string(),
            updated_at: class.updated_at.to_string(),
        });
    }

    Ok(ClassListResponse { classes: class_responses })
}
