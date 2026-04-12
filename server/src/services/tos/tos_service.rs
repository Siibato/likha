use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::tos_repository::TosRepository;
use crate::schema::tos_schema::*;
use crate::utils::{AppError, AppResult};

pub struct TosService {
    pub tos_repo: TosRepository,
    pub class_repo: ClassRepository,
    pub db: DatabaseConnection,
}

impl TosService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            tos_repo: TosRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            db,
        }
    }

    // ===== TOS CRUD =====

    pub async fn create_tos(
        &self,
        class_id: Uuid,
        teacher_id: Uuid,
        request: CreateTosRequest,
        client_id: Option<Uuid>,
    ) -> AppResult<TosResponse> {
        // Verify teacher owns class
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
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

        // Check uniqueness (one TOS per class per period)
        let existing = self
            .tos_repo
            .find_tos_by_class_and_period(class_id, request.grading_period_number)
            .await?;
        if existing.is_some() {
            return Err(AppError::Conflict(format!(
                "A TOS already exists for period {} in this class",
                request.grading_period_number
            )));
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
        let tos = self
            .tos_repo
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

    pub async fn get_tos(&self, tos_id: Uuid) -> AppResult<TosResponse> {
        let tos = self
            .tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        let competencies = self.tos_repo.find_competencies_by_tos(tos_id).await?;

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
        &self,
        class_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<TosListResponse> {
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let tos_list = self.tos_repo.find_tos_by_class(class_id).await?;
        let mut items = Vec::new();

        for tos in tos_list {
            let competencies = self.tos_repo.find_competencies_by_tos(tos.id).await?;
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
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: UpdateTosRequest,
    ) -> AppResult<TosResponse> {
        let tos = self
            .tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
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

        self.tos_repo
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

        self.get_tos(tos_id).await
    }

    pub async fn delete_tos(&self, tos_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let tos = self
            .tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.tos_repo.soft_delete_tos(tos_id).await
    }

    // ===== COMPETENCIES =====

    pub async fn add_competency(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: CreateCompetencyRequest,
    ) -> AppResult<CompetencyResponse> {
        self.add_competency_with_id(tos_id, teacher_id, request, Uuid::new_v4()).await
    }

    pub async fn add_competency_with_id(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: CreateCompetencyRequest,
        competency_id: Uuid,
    ) -> AppResult<CompetencyResponse> {
        let tos = self
            .tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let existing = self.tos_repo.find_competencies_by_tos(tos_id).await?;
        let order_index = request.order_index.unwrap_or(existing.len() as i32);

        let comp = self
            .tos_repo
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
        &self,
        competency_id: Uuid,
        teacher_id: Uuid,
        request: UpdateCompetencyRequest,
    ) -> AppResult<CompetencyResponse> {
        let comp = self
            .tos_repo
            .find_competency_by_id(competency_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

        let tos = self
            .tos_repo
            .find_tos_by_id(comp.tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let updated = self
            .tos_repo
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
        &self,
        competency_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        let comp = self
            .tos_repo
            .find_competency_by_id(competency_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Competency not found".to_string()))?;

        let tos = self
            .tos_repo
            .find_tos_by_id(comp.tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        self.tos_repo.soft_delete_competency(competency_id).await
    }

    pub async fn bulk_add_competencies(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: BulkAddCompetenciesRequest,
    ) -> AppResult<Vec<CompetencyResponse>> {
        let tos = self
            .tos_repo
            .find_tos_by_id(tos_id)
            .await?
            .ok_or_else(|| AppError::NotFound("TOS not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, tos.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let existing = self.tos_repo.find_competencies_by_tos(tos_id).await?;
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

        let created = self.tos_repo.bulk_create_competencies(tos_id, competencies).await?;

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

    // ===== MELCS SEARCH =====

    pub async fn search_melcs(
        &self,
        subject: Option<&str>,
        grade_level: Option<&str>,
        quarter: Option<i32>,
        query: Option<&str>,
    ) -> AppResult<MelcSearchResponse> {
        let rows = self
            .tos_repo
            .search_melcs(subject, grade_level, quarter, query)
            .await?;

        Ok(MelcSearchResponse {
            melcs: rows
                .into_iter()
                .map(|r| MelcEntry {
                    id: r.id,
                    subject: r.subject,
                    grade_level: r.grade_level,
                    quarter: r.quarter,
                    competency_code: r.competency_code,
                    competency_text: r.competency_text,
                    domain: r.domain,
                })
                .collect(),
        })
    }
}
