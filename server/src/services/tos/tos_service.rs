use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::tos_repository::TosRepository;
use crate::schema::tos_schema::*;
use crate::utils::AppResult;

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
        super::crud::create_tos(
            &self.db,
            &self.tos_repo,
            &self.class_repo,
            class_id,
            teacher_id,
            request,
            client_id,
        ).await
    }

    pub async fn get_tos(&self, tos_id: Uuid) -> AppResult<TosResponse> {
        super::crud::get_tos(&self.tos_repo, tos_id).await
    }

    pub async fn list_tos_for_class(
        &self,
        class_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<TosListResponse> {
        super::crud::list_tos_for_class(
            &self.tos_repo,
            &self.class_repo,
            class_id,
            teacher_id,
        ).await
    }

    pub async fn update_tos(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: UpdateTosRequest,
    ) -> AppResult<TosResponse> {
        super::crud::update_tos(
            &self.tos_repo,
            &self.class_repo,
            tos_id,
            teacher_id,
            request,
        ).await
    }

    pub async fn delete_tos(&self, tos_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        super::crud::delete_tos(
            &self.tos_repo,
            &self.class_repo,
            tos_id,
            teacher_id,
        ).await
    }

    // ===== COMPETENCIES =====

    pub async fn add_competency(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: CreateCompetencyRequest,
    ) -> AppResult<CompetencyResponse> {
        super::competencies::add_competency(
            &self.tos_repo,
            &self.class_repo,
            tos_id,
            teacher_id,
            request,
        ).await
    }

    pub async fn add_competency_with_id(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: CreateCompetencyRequest,
        competency_id: Uuid,
    ) -> AppResult<CompetencyResponse> {
        super::competencies::add_competency_with_id(
            &self.tos_repo,
            &self.class_repo,
            tos_id,
            teacher_id,
            request,
            competency_id,
        ).await
    }

    pub async fn update_competency(
        &self,
        competency_id: Uuid,
        teacher_id: Uuid,
        request: UpdateCompetencyRequest,
    ) -> AppResult<CompetencyResponse> {
        super::competencies::update_competency(
            &self.tos_repo,
            &self.class_repo,
            competency_id,
            teacher_id,
            request,
        ).await
    }

    pub async fn delete_competency(
        &self,
        competency_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<()> {
        super::competencies::delete_competency(
            &self.tos_repo,
            &self.class_repo,
            competency_id,
            teacher_id,
        ).await
    }

    pub async fn bulk_add_competencies(
        &self,
        tos_id: Uuid,
        teacher_id: Uuid,
        request: BulkAddCompetenciesRequest,
    ) -> AppResult<Vec<CompetencyResponse>> {
        super::competencies::bulk_add_competencies(
            &self.tos_repo,
            &self.class_repo,
            tos_id,
            teacher_id,
            request,
        ).await
    }

    // ===== MELCS SEARCH =====

    pub async fn search_melcs(
        &self,
        subject: Option<&str>,
        grade_level: Option<&str>,
        quarter: Option<i32>,
        query: Option<&str>,
        limit: i64,
        offset: i64,
    ) -> AppResult<MelcSearchResponse> {
        super::melcs_search::search_melcs(
            &self.tos_repo,
            subject,
            grade_level,
            quarter,
            query,
            limit,
            offset,
        ).await
    }
}
