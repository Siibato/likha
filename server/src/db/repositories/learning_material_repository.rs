use sea_orm::DatabaseConnection;
use uuid::Uuid;

use ::entity::{learning_materials, material_files};
use crate::db::repositories::repository_operations::learning_material as ops;
use crate::utils::AppResult;

pub struct LearningMaterialRepository {
    db: DatabaseConnection,
}

impl LearningMaterialRepository {
    pub fn new(db: DatabaseConnection) -> Self {
        Self { db }
    }

    pub async fn create_material(
        &self,
        class_id: Uuid,
        title: String,
        description: Option<String>,
        content_text: Option<String>,
        order_index: i32,
        client_id: Option<Uuid>,
    ) -> AppResult<learning_materials::Model> {
        ops::create_material(&self.db, class_id, title, description, content_text, order_index, client_id).await
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<learning_materials::Model>> {
        ops::find_by_id(&self.db, id).await
    }

    pub async fn find_by_class_id(&self, class_id: Uuid) -> AppResult<Vec<learning_materials::Model>> {
        ops::find_by_class_id(&self.db, class_id).await
    }

    pub async fn update_material(
        &self,
        id: Uuid,
        title: Option<String>,
        description: Option<Option<String>>,
        content_text: Option<Option<String>>,
    ) -> AppResult<learning_materials::Model> {
        ops::update_material(&self.db, id, title, description, content_text).await
    }

    pub async fn update_order_index(&self, id: Uuid, order_index: i32) -> AppResult<learning_materials::Model> {
        ops::update_order_index(&self.db, id, order_index).await
    }

    pub async fn get_max_order_index(&self, class_id: Uuid) -> AppResult<i32> {
        ops::get_max_order_index(&self.db, class_id).await
    }

    pub async fn save_file(
        &self,
        material_id: Uuid,
        file_name: String,
        file_type: String,
        file_size: i64,
        file_path: String,
        file_hash: String,
    ) -> AppResult<material_files::Model> {
        ops::save_file(&self.db, material_id, file_name, file_type, file_size, file_path, file_hash).await
    }

    pub async fn find_active_file_path_by_hash(&self, hash: &str) -> AppResult<Option<String>> {
        ops::find_active_file_path_by_hash(&self.db, hash).await
    }

    pub async fn count_active_by_hash(&self, hash: &str, exclude_id: Uuid) -> AppResult<i64> {
        ops::count_active_by_hash(&self.db, hash, exclude_id).await
    }

    pub async fn soft_delete_file(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete_file(&self.db, id).await
    }

    pub async fn find_file_by_id(&self, id: Uuid) -> AppResult<Option<material_files::Model>> {
        ops::find_file_by_id(&self.db, id).await
    }

    pub async fn find_files_by_material(&self, material_id: Uuid) -> AppResult<Vec<material_files::Model>> {
        ops::find_files_by_material(&self.db, material_id).await
    }

    pub async fn count_files_by_material(&self, material_id: Uuid) -> AppResult<usize> {
        ops::count_files_by_material(&self.db, material_id).await
    }

    pub async fn find_all(&self) -> AppResult<Vec<learning_materials::Model>> {
        ops::find_all(&self.db).await
    }

    pub async fn soft_delete(&self, id: Uuid) -> AppResult<()> {
        ops::soft_delete(&self.db, id).await
    }

    pub async fn reorder_materials(&self, _class_id: Uuid, material_ids: Vec<Uuid>) -> AppResult<()> {
        ops::reorder_materials(&self.db, _class_id, material_ids).await
    }
}
