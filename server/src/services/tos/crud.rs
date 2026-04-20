use sea_orm::DatabaseConnection;
use uuid::Uuid;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::tos_repository::TosRepository;
use crate::schema::tos_schema::*;
use crate::utils::{AppError, AppResult};

pub async fn create_tos(
    _db: &DatabaseConnection,
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    class_id: Uuid,
    teacher_id: Uuid,
    request: CreateTosRequest,
    client_id: Option<Uuid>,
) -> AppResult<TosResponse> {
    // Verify teacher owns class
    if !class_repo.is_teacher_of_class(teacher_id, class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    // Validate classification mode
    if request.classification_mode != "blooms" && request.classification_mode != "difficulty" {
        return Err(AppError::BadRequest(
            "classification_mode must be 'blooms' or 'difficulty'".to_string(),
        ));
    }

    // Validate grading period range
    if !(1..=4).contains(&request.grading_period_number) {
        return Err(AppError::BadRequest("grading_period_number must be between 1 and 4".to_string()));
    }

    
    let time_unit = request.time_unit.as_deref().unwrap_or("days");
    if time_unit != "days" && time_unit != "hours" {
        return Err(AppError::BadRequest(
            "time_unit must be 'days' or 'hours'".to_string(),
        ));
    }
    let easy_pct = request.easy_percentage.unwrap_or(50.0);
    let medium_pct = request.medium_percentage.unwrap_or(30.0);
    let hard_pct = request.hard_percentage.unwrap_or(20.0);
    let remembering_pct = request.remembering_percentage.unwrap_or(16.67);
    let understanding_pct = request.understanding_percentage.unwrap_or(16.67);
    let applying_pct = request.applying_percentage.unwrap_or(16.67);
    let analyzing_pct = request.analyzing_percentage.unwrap_or(16.67);
    let evaluating_pct = request.evaluating_percentage.unwrap_or(16.67);
    let creating_pct = request.creating_percentage.unwrap_or(16.67);

    let id = client_id.unwrap_or_else(Uuid::new_v4);
    let tos = tos_repo
        .create_tos(
            id,
            class_id,
            request.grading_period_number,
            &request.title,
            &request.classification_mode,
            request.total_items,
            time_unit,
            easy_pct,
            medium_pct,
            hard_pct,
            remembering_pct,
            understanding_pct,
            applying_pct,
            analyzing_pct,
            evaluating_pct,
            creating_pct,
        )
        .await?;

    Ok(TosResponse {
        id: tos.id.to_string(),
        class_id: tos.class_id.to_string(),
        grading_period_number: tos.grading_period_number,
        title: tos.title,
        classification_mode: tos.classification_mode,
        total_items: tos.total_items,
        time_unit: tos.time_unit,
        easy_percentage: tos.easy_percentage,
        medium_percentage: tos.medium_percentage,
        hard_percentage: tos.hard_percentage,
        remembering_percentage: tos.remembering_percentage,
        understanding_percentage: tos.understanding_percentage,
        applying_percentage: tos.applying_percentage,
        analyzing_percentage: tos.analyzing_percentage,
        evaluating_percentage: tos.evaluating_percentage,
        creating_percentage: tos.creating_percentage,
        competencies: vec![],
        created_at: tos.created_at.to_string(),
        updated_at: tos.updated_at.to_string(),
    })
}

pub async fn get_tos(
    tos_repo: &TosRepository,
    tos_id: Uuid,
) -> AppResult<TosResponse> {
    let tos = tos_repo
        .find_tos_by_id(tos_id)
        .await?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    let competencies = tos_repo.find_competencies_by_tos(tos_id).await?;

    Ok(TosResponse {
        id: tos.id.to_string(),
        class_id: tos.class_id.to_string(),
        grading_period_number: tos.grading_period_number,
        title: tos.title,
        classification_mode: tos.classification_mode,
        total_items: tos.total_items,
        time_unit: tos.time_unit,
        easy_percentage: tos.easy_percentage,
        medium_percentage: tos.medium_percentage,
        hard_percentage: tos.hard_percentage,
        remembering_percentage: tos.remembering_percentage,
        understanding_percentage: tos.understanding_percentage,
        applying_percentage: tos.applying_percentage,
        analyzing_percentage: tos.analyzing_percentage,
        evaluating_percentage: tos.evaluating_percentage,
        creating_percentage: tos.creating_percentage,
        competencies: competencies
            .into_iter()
            .map(|c| CompetencyResponse {
                id: c.id.to_string(),
                competency_code: c.competency_code,
                competency_text: c.competency_text,
                time_units_taught: c.time_units_taught,
                order_index: c.order_index,
                easy_count: c.easy_count,
                medium_count: c.medium_count,
                hard_count: c.hard_count,
                remembering_count: c.remembering_count,
                understanding_count: c.understanding_count,
                applying_count: c.applying_count,
                analyzing_count: c.analyzing_count,
                evaluating_count: c.evaluating_count,
                creating_count: c.creating_count,
            })
            .collect(),
        created_at: tos.created_at.to_string(),
        updated_at: tos.updated_at.to_string(),
    })
}

pub async fn list_tos_for_class(
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    class_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<TosListResponse> {
    if !class_repo.is_teacher_of_class(teacher_id, class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let tos_list = tos_repo.find_tos_by_class(class_id).await?;
    let mut items = Vec::new();

    for tos in tos_list {
        let competencies = tos_repo.find_competencies_by_tos(tos.id).await?;
        items.push(TosResponse {
            id: tos.id.to_string(),
            class_id: tos.class_id.to_string(),
            grading_period_number: tos.grading_period_number,
            title: tos.title,
            classification_mode: tos.classification_mode,
            total_items: tos.total_items,
            time_unit: tos.time_unit,
            easy_percentage: tos.easy_percentage,
            medium_percentage: tos.medium_percentage,
            hard_percentage: tos.hard_percentage,
            remembering_percentage: tos.remembering_percentage,
            understanding_percentage: tos.understanding_percentage,
            applying_percentage: tos.applying_percentage,
            analyzing_percentage: tos.analyzing_percentage,
            evaluating_percentage: tos.evaluating_percentage,
            creating_percentage: tos.creating_percentage,
            competencies: competencies
                .into_iter()
                .map(|c| CompetencyResponse {
                    id: c.id.to_string(),
                    competency_code: c.competency_code,
                    competency_text: c.competency_text,
                    time_units_taught: c.time_units_taught,
                    order_index: c.order_index,
                    easy_count: c.easy_count,
                    medium_count: c.medium_count,
                    hard_count: c.hard_count,
                    remembering_count: c.remembering_count,
                    understanding_count: c.understanding_count,
                    applying_count: c.applying_count,
                    analyzing_count: c.analyzing_count,
                    evaluating_count: c.evaluating_count,
                    creating_count: c.creating_count,
                })
                .collect(),
            created_at: tos.created_at.to_string(),
            updated_at: tos.updated_at.to_string(),
        });
    }

    Ok(TosListResponse { items })
}

pub async fn update_tos(
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    tos_id: Uuid,
    teacher_id: Uuid,
    request: UpdateTosRequest,
) -> AppResult<TosResponse> {
    let tos = tos_repo
        .find_tos_by_id(tos_id)
        .await?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    // Validate classification_mode if provided
    if let Some(ref mode) = request.classification_mode {
        if mode != "blooms" && mode != "difficulty" {
            return Err(AppError::BadRequest(
                "classification_mode must be 'blooms' or 'difficulty'".to_string(),
            ));
        }
    }

    if let Some(ref unit) = request.time_unit {
        if unit != "days" && unit != "hours" {
            return Err(AppError::BadRequest(
                "time_unit must be 'days' or 'hours'".to_string(),
            ));
        }
    }

    tos_repo
        .update_tos(
            tos_id,
            request.title.as_deref(),
            request.classification_mode.as_deref(),
            request.total_items,
            request.time_unit.as_deref(),
            request.easy_percentage,
            request.medium_percentage,
            request.hard_percentage,
            request.remembering_percentage,
            request.understanding_percentage,
            request.applying_percentage,
            request.analyzing_percentage,
            request.evaluating_percentage,
            request.creating_percentage,
        )
        .await?;

    get_tos(tos_repo, tos_id).await
}

pub async fn delete_tos(
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    tos_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<()> {
    let tos = tos_repo
        .find_tos_by_id(tos_id)
        .await?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    tos_repo.soft_delete_tos(tos_id).await
}
