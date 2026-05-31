use sea_orm::DatabaseConnection;
use uuid::Uuid;

use crate::modules::class::repository::ClassRepository;
use crate::db::repositories::user_repository::UserRepository;
use crate::modules::class::schema::{
    ClassResponse, ClassListResponse, ClassDetailResponse, EnrollmentResponse,
    ClassMetadataResponse, CreateClassRequest, UpdateClassRequest,
};
use crate::modules::class::service_operations as ops;
use crate::utils::AppResult;

pub struct ClassService {
    pub class_repo: ClassRepository,
    pub user_repo: UserRepository,
}

impl ClassService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            class_repo: ClassRepository::new(db.clone()),
            user_repo: UserRepository::new(db),
        }
    }

    pub async fn create_class(
        &self,
        request: CreateClassRequest,
        teacher_id: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<ClassResponse> {
        ops::create_class(&self.class_repo, &self.user_repo, request, teacher_id, client_id).await
    }

    pub async fn update_class(
        &self,
        class_id: Uuid,
        request: UpdateClassRequest,
        teacher_id: Uuid,
        caller_role: &str,
    ) -> AppResult<ClassResponse> {
        ops::update_class(&self.class_repo, &self.user_repo, class_id, request, teacher_id, caller_role).await
    }

    pub async fn get_teacher_classes(&self, teacher_id: Uuid) -> AppResult<ClassListResponse> {
        ops::get_teacher_classes(&self.class_repo, &self.user_repo, teacher_id).await
    }

    pub async fn get_student_classes(&self, student_id: Uuid) -> AppResult<ClassListResponse> {
        ops::get_student_classes(&self.class_repo, student_id).await
    }

    pub async fn get_all_classes(&self) -> AppResult<ClassListResponse> {
        ops::get_all_classes(&self.class_repo).await
    }

    pub async fn soft_delete(&self, class_id: Uuid, user_id: Uuid, role: &str) -> AppResult<()> {
        ops::soft_delete(&self.class_repo, class_id, user_id, role).await
    }

    pub async fn get_class_detail(&self, class_id: Uuid) -> AppResult<ClassDetailResponse> {
        ops::get_class_detail(&self.class_repo, &self.user_repo, class_id).await
    }

    pub async fn add_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
        role: &str,
    ) -> AppResult<EnrollmentResponse> {
        ops::add_student(&self.class_repo, &self.user_repo, class_id, student_id, teacher_id, role).await
    }

    pub async fn remove_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
        role: &str,
    ) -> AppResult<()> {
        ops::remove_student(&self.class_repo, class_id, student_id, teacher_id, role).await
    }

    pub async fn is_student_enrolled(&self, class_id: Uuid, student_id: Uuid) -> AppResult<bool> {
        ops::is_student_enrolled(&self.class_repo, class_id, student_id).await
    }

    pub async fn get_classes_metadata(&self, user_id: Uuid, role: &str) -> AppResult<ClassMetadataResponse> {
        ops::get_classes_metadata(&self.class_repo, user_id, role).await
    }
}
