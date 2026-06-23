use crate::modules::auth::UserRepository;
use crate::modules::class::repository::ClassRepository;
use crate::modules::class::schema::{ClassResponse, UpdateClassRequest};
use crate::utils::error::{AppError, AppResult};
use crate::utils::validators::Validator;
use uuid::Uuid;

pub async fn update_class(
    class_repo: &ClassRepository,
    user_repo: &UserRepository,
    class_id: Uuid,
    request: UpdateClassRequest,
    teacher_id: Uuid,
    caller_role: &str,
) -> AppResult<ClassResponse> {
    let _class = class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

    if caller_role != "admin" && !class_repo.is_teacher_of_class(teacher_id, class_id).await? {
        return Err(AppError::Forbidden(
            "You can only update your own classes".to_string(),
        ));
    }

    let title = Validator::validate_optional_title(request.title)?;

    let description = request.description.map(|d| {
        let trimmed = d.trim();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed.to_string())
        }
    });

    let updated_class = class_repo
        .update_class(class_id, title, description, request.is_advisory)
        .await?;

    if let Some(new_teacher_id) = request.teacher_id {
        let new_teacher = user_repo
            .find_by_id(new_teacher_id)
            .await?
            .ok_or_else(|| AppError::NotFound("New teacher not found".to_string()))?;

        if new_teacher.role != "teacher" {
            return Err(AppError::BadRequest(
                "User must have teacher role".to_string(),
            ));
        }

        if class_repo
            .is_teacher_of_class(new_teacher_id, class_id)
            .await?
        {
            return Err(AppError::BadRequest(
                "Teacher is already assigned to this class".to_string(),
            ));
        }

        class_repo
            .reassign_teacher(class_id, new_teacher_id)
            .await?;
    }

    let teacher_model = class_repo
        .find_teacher_of_class(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

    let student_count = class_repo.count_students_in_class(class_id).await?;

    Ok(ClassResponse {
        id: updated_class.id,
        title: updated_class.title,
        description: updated_class.description,
        teacher_id: teacher_model.id,
        teacher_username: teacher_model.username,
        teacher_first_name: teacher_model.first_name,
        teacher_last_name: teacher_model.last_name,
        is_archived: updated_class.is_archived,
        is_advisory: updated_class.is_advisory,
        student_count,
        created_at: updated_class.created_at.to_string(),
        updated_at: updated_class.updated_at.to_string(),
    })
}
