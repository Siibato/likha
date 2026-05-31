use chrono::NaiveDateTime;
use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::{class_participants, classes, users};
use crate::modules::class::repository_operations as ops;
use crate::utils::AppResult;

pub struct ClassRepository {
    db: DatabaseConnection,
}

impl ClassRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_class(
        &self,
        title: String,
        description: Option<String>,
        client_id: Option<Uuid>,
        is_advisory: bool,
    ) -> AppResult<classes::Model> {
        ops::create_class(&self.db, title, description, client_id, is_advisory).await
    }

    pub async fn find_by_user_id(&self, user_id: Uuid, role: &str) -> AppResult<Vec<classes::Model>> {
        ops::find_by_user_id(&self.db, user_id, role).await
    }

    pub async fn find_by_teacher_id(&self, teacher_id: Uuid) -> AppResult<Vec<classes::Model>> {
        ops::find_by_teacher_id(&self.db, teacher_id).await
    }

    pub async fn find_all(&self) -> AppResult<Vec<classes::Model>> {
        ops::find_all(&self.db).await
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<classes::Model>> {
        ops::find_by_id(&self.db, id).await
    }

    pub async fn update_class(
        &self,
        id: Uuid,
        title: Option<String>,
        description: Option<Option<String>>,
        is_advisory: Option<bool>,
    ) -> AppResult<classes::Model> {
        ops::update_class(&self.db, id, title, description, is_advisory).await
    }

    pub async fn add_participant(&self, class_id: Uuid, user_id: Uuid) -> AppResult<class_participants::Model> {
        ops::add_participant(&self.db, class_id, user_id).await
    }

    pub async fn add_student(&self, class_id: Uuid, student_id: Uuid) -> AppResult<class_participants::Model> {
        ops::add_student(&self.db, class_id, student_id).await
    }

    pub async fn remove_participant(&self, class_id: Uuid, user_id: Uuid) -> AppResult<()> {
        ops::remove_participant(&self.db, class_id, user_id).await
    }

    pub async fn remove_student(&self, class_id: Uuid, student_id: Uuid) -> AppResult<()> {
        ops::remove_student(&self.db, class_id, student_id).await
    }

    pub async fn find_participants_by_class_id(
        &self,
        class_id: Uuid,
        role: Option<&str>,
    ) -> AppResult<Vec<class_participants::Model>> {
        ops::find_participants_by_class_id(&self.db, class_id, role).await
    }

    pub async fn find_participants_by_user_id(
        &self,
        user_id: Uuid,
        role: Option<&str>,
    ) -> AppResult<Vec<class_participants::Model>> {
        ops::find_participants_by_user_id(&self.db, user_id, role).await
    }

    pub async fn find_classes_by_student_id(&self, student_id: Uuid) -> AppResult<Vec<classes::Model>> {
        ops::find_classes_by_student_id(&self.db, student_id).await
    }

    pub async fn count_students_in_class(&self, class_id: Uuid) -> AppResult<usize> {
        ops::count_students_in_class(&self.db, class_id).await
    }

    pub async fn is_student_enrolled(&self, class_id: Uuid, student_id: Uuid) -> AppResult<bool> {
        ops::is_student_enrolled(&self.db, class_id, student_id).await
    }

    pub async fn find_teacher_of_class(&self, class_id: Uuid) -> AppResult<Option<users::Model>> {
        ops::find_teacher_of_class(&self.db, class_id).await
    }

    pub async fn is_teacher_of_class(&self, user_id: Uuid, class_id: Uuid) -> AppResult<bool> {
        ops::is_teacher_of_class(&self.db, user_id, class_id).await
    }

    pub async fn get_metadata(&self, teacher_id: Uuid) -> AppResult<(NaiveDateTime, usize, String)> {
        ops::get_metadata(&self.db, teacher_id).await
    }

    pub async fn find_student_enrollments(&self, student_id: Uuid) -> AppResult<Vec<class_participants::Model>> {
        ops::find_student_enrollments(&self.db, student_id).await
    }

    pub async fn remove_all_participants(&self, class_id: Uuid) -> AppResult<()> {
        ops::remove_all_participants(&self.db, class_id).await
    }

    pub async fn soft_delete(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete(&self.db, id).await
    }

    pub async fn reassign_teacher(&self, class_id: Uuid, new_teacher_id: Uuid) -> AppResult<()> {
        ops::reassign_teacher(&self.db, class_id, new_teacher_id).await
    }
}
