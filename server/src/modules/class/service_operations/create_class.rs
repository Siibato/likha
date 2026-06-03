use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::utils::validators::Validator;
use crate::modules::class::schema::{ClassResponse, CreateClassRequest};
use crate::modules::class::repository::ClassRepository;
use crate::modules::auth::UserRepository;

pub async fn create_class(
    class_repo: &ClassRepository,
    user_repo: &UserRepository,
    request: CreateClassRequest,
    teacher_id: Uuid,
    client_id: Option<Uuid>,
) -> AppResult<ClassResponse> {
    let title = Validator::validate_title(&request.title)?;

    let actual_teacher_id = request.teacher_id.unwrap_or(teacher_id);

    let teacher = user_repo
        .find_by_id(actual_teacher_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Teacher not found".to_string()))?;

    let existing_classes = class_repo.find_by_teacher_id(actual_teacher_id).await?;
    let normalized_title = title.to_lowercase();

    if existing_classes
        .iter()
        .any(|c| c.title.to_lowercase() == normalized_title)
    {
        return Err(AppError::BadRequest(
            format!("A class named '{}' already exists for this teacher", title)
        ));
    }

    let class = class_repo
        .create_class(title, request.description, client_id, request.is_advisory.unwrap_or(false))
        .await?;

    class_repo.add_participant(class.id, actual_teacher_id).await?;

    Ok(ClassResponse {
        id: class.id,
        title: class.title,
        description: class.description,
        teacher_id: actual_teacher_id,
        teacher_username: teacher.username,
        teacher_full_name: teacher.full_name,
        is_archived: class.is_archived,
        is_advisory: class.is_advisory,
        student_count: 0,
        created_at: class.created_at.to_string(),
        updated_at: class.updated_at.to_string(),
    })
}
