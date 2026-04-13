use uuid::Uuid;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::tos_repository::TosRepository;
use crate::schema::tos_schema::*;
use crate::utils::{AppError, AppResult};

pub async fn add_competency(
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    tos_id: Uuid,
    teacher_id: Uuid,
    request: CreateCompetencyRequest,
) -> AppResult<CompetencyResponse> {
    add_competency_with_id(tos_repo, class_repo, tos_id, teacher_id, request, Uuid::new_v4()).await
}

pub async fn add_competency_with_id(
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    tos_id: Uuid,
    teacher_id: Uuid,
    request: CreateCompetencyRequest,
    competency_id: Uuid,
) -> AppResult<CompetencyResponse> {
    let tos = tos_repo
        .find_tos_by_id(tos_id)
        .await?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let existing = tos_repo.find_competencies_by_tos(tos_id).await?;
    let order_index = request.order_index.unwrap_or(existing.len() as i32);

    let comp = tos_repo
        .create_competency(
            competency_id,
            tos_id,
            request.competency_code.as_deref(),
            &request.competency_text,
            request.time_units_taught,
            order_index,
            request.easy_count,
            request.medium_count,
            request.hard_count,
            request.remembering_count,
            request.understanding_count,
            request.applying_count,
            request.analyzing_count,
            request.evaluating_count,
            request.creating_count,
        )
        .await?;

    Ok(CompetencyResponse {
        id: comp.id.to_string(),
        competency_code: comp.competency_code,
        competency_text: comp.competency_text,
        time_units_taught: comp.time_units_taught,
        order_index: comp.order_index,
        easy_count: comp.easy_count,
        medium_count: comp.medium_count,
        hard_count: comp.hard_count,
        remembering_count: comp.remembering_count,
        understanding_count: comp.understanding_count,
        applying_count: comp.applying_count,
        analyzing_count: comp.analyzing_count,
        evaluating_count: comp.evaluating_count,
        creating_count: comp.creating_count,
    })
}

pub async fn update_competency(
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    competency_id: Uuid,
    teacher_id: Uuid,
    request: UpdateCompetencyRequest,
) -> AppResult<CompetencyResponse> {
    let comp = tos_repo
        .find_competency_by_id(competency_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

    let tos = tos_repo
        .find_tos_by_id(comp.tos_id)
        .await?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let updated = tos_repo
        .update_competency(
            competency_id,
            None, // competency_code updates not supported via this simple path
            request.competency_text.as_deref(),
            request.time_units_taught,
            request.order_index,
            request.easy_count,
            request.medium_count,
            request.hard_count,
            request.remembering_count,
            request.understanding_count,
            request.applying_count,
            request.analyzing_count,
            request.evaluating_count,
            request.creating_count,
        )
        .await?;

    Ok(CompetencyResponse {
        id: updated.id.to_string(),
        competency_code: updated.competency_code,
        competency_text: updated.competency_text,
        time_units_taught: updated.time_units_taught,
        order_index: updated.order_index,
        easy_count: updated.easy_count,
        medium_count: updated.medium_count,
        hard_count: updated.hard_count,
        remembering_count: updated.remembering_count,
        understanding_count: updated.understanding_count,
        applying_count: updated.applying_count,
        analyzing_count: updated.analyzing_count,
        evaluating_count: updated.evaluating_count,
        creating_count: updated.creating_count,
    })
}

pub async fn delete_competency(
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    competency_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<()> {
    let comp = tos_repo
        .find_competency_by_id(competency_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

    let tos = tos_repo
        .find_tos_by_id(comp.tos_id)
        .await?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    tos_repo.soft_delete_competency(competency_id).await
}

pub async fn bulk_add_competencies(
    tos_repo: &TosRepository,
    class_repo: &ClassRepository,
    tos_id: Uuid,
    teacher_id: Uuid,
    request: BulkAddCompetenciesRequest,
) -> AppResult<Vec<CompetencyResponse>> {
    let tos = tos_repo
        .find_tos_by_id(tos_id)
        .await?
        .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

    if !class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let existing = tos_repo.find_competencies_by_tos(tos_id).await?;
    let base_order = existing.len() as i32;

    let competencies: Vec<_> = request
        .competencies
        .into_iter()
        .enumerate()
        .map(|(i, c)| {
            (
                c.competency_code,
                c.competency_text,
                c.time_units_taught,
                c.order_index.unwrap_or(base_order + i as i32),
                c.easy_count,
                c.medium_count,
                c.hard_count,
                c.remembering_count,
                c.understanding_count,
                c.applying_count,
                c.analyzing_count,
                c.evaluating_count,
                c.creating_count,
            )
        })
        .collect();

    let created = tos_repo.bulk_create_competencies(tos_id, competencies).await?;

    Ok(created
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
        .collect())
}
