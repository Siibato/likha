use sea_orm::DatabaseConnection;
use uuid::Uuid;
use md5;

use crate::db::repositories::activity_log_repository::ActivityLogRepository;
use crate::db::repositories::class_repository::ClassRepository;
use crate::db::repositories::learning_material_repository::LearningMaterialRepository;
use crate::schema::learning_material_schema::*;
use crate::utils::error::{AppError, AppResult};

const MAX_FILE_SIZE_MB: i64 = 50;
const MAX_FILES_PER_MATERIAL: usize = 10;

pub struct LearningMaterialService {
    material_repo: LearningMaterialRepository,
    class_repo: ClassRepository,
    activity_log_repo: ActivityLogRepository,
}

impl LearningMaterialService {
    pub fn new(db: DatabaseConnection) -> Self {
        Self {
            material_repo: LearningMaterialRepository::new(db.clone()),
            class_repo: ClassRepository::new(db.clone()),
            activity_log_repo: ActivityLogRepository::new(db),
        }
    }

    // ===== AUTHORIZATION HELPERS =====

    async fn verify_teacher_owns_class(&self, class_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if class.teacher_id != teacher_id {
            return Err(AppError::Forbidden(
                "You can only manage materials in your own classes".to_string(),
            ));
        }

        Ok(())
    }

    async fn verify_student_enrolled(&self, class_id: Uuid, student_id: Uuid) -> AppResult<()> {
        let is_enrolled = self
            .class_repo
            .is_student_enrolled(class_id, student_id)
            .await?;

        if !is_enrolled {
            return Err(AppError::Forbidden(
                "You must be enrolled in this class to view materials".to_string(),
            ));
        }

        Ok(())
    }

    // ===== VALIDATION HELPERS =====

    fn validate_title(title: &str) -> AppResult<String> {
        let title = title.trim().to_string();
        if title.is_empty() {
            return Err(AppError::BadRequest("Title is required".to_string()));
        }
        if title.len() > 200 {
            return Err(AppError::BadRequest(
                "Title must be at most 200 characters".to_string(),
            ));
        }
        Ok(title)
    }

    fn validate_description(desc: &Option<String>) -> AppResult<Option<String>> {
        if let Some(d) = desc {
            let trimmed = d.trim();
            if trimmed.is_empty() {
                return Ok(None);
            }
            if trimmed.len() > 500 {
                return Err(AppError::BadRequest(
                    "Description must be at most 500 characters".to_string(),
                ));
            }
            Ok(Some(trimmed.to_string()))
        } else {
            Ok(None)
        }
    }

    fn validate_content_text(content: &Option<String>) -> AppResult<Option<String>> {
        if let Some(c) = content {
            let trimmed = c.trim();
            if trimmed.is_empty() {
                return Ok(None);
            }
            if trimmed.len() > 50000 {
                return Err(AppError::BadRequest(
                    "Content text must be at most 50000 characters".to_string(),
                ));
            }
            Ok(Some(trimmed.to_string()))
        } else {
            Ok(None)
        }
    }

    // ===== MATERIAL CRUD =====

    pub async fn create_material(
        &self,
        class_id: Uuid,
        request: CreateMaterialRequest,
        teacher_id: Uuid,
    ) -> AppResult<MaterialResponse> {
        self.verify_teacher_owns_class(class_id, teacher_id).await?;

        let title = Self::validate_title(&request.title)?;
        let description = Self::validate_description(&request.description)?;
        let content_text = Self::validate_content_text(&request.content_text)?;

        let max_order = self.material_repo.get_max_order_index(class_id).await?;
        let order_index = max_order + 1;

        let material = self
            .material_repo
            .create_material(class_id, title, description, content_text, order_index)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_created",
                Some(teacher_id),
                Some(format!("Learning material '{}' created", material.title)),
            )
            .await;

        Ok(MaterialResponse {
            id: material.id,
            class_id: material.class_id,
            title: material.title,
            description: material.description,
            content_text: material.content_text,
            order_index: material.order_index,
            file_count: 0,
            created_at: material.created_at.to_string(),
            updated_at: material.updated_at.to_string(),
        })
    }

    pub async fn get_materials(
        &self,
        class_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<MaterialListResponse> {
        if role == "teacher" {
            self.verify_teacher_owns_class(class_id, user_id).await?;
        } else {
            self.verify_student_enrolled(class_id, user_id).await?;
        }

        let materials = self.material_repo.find_by_class_id(class_id).await?;

        let mut material_responses = Vec::new();
        for material in materials {
            let file_count = self
                .material_repo
                .count_files_by_material(material.id)
                .await?;

            material_responses.push(MaterialResponse {
                id: material.id,
                class_id: material.class_id,
                title: material.title,
                description: material.description,
                content_text: material.content_text,
                order_index: material.order_index,
                file_count,
                created_at: material.created_at.to_string(),
                updated_at: material.updated_at.to_string(),
            });
        }

        Ok(MaterialListResponse {
            materials: material_responses,
        })
    }

    pub async fn get_material_detail(
        &self,
        material_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<MaterialDetailResponse> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        if role == "teacher" {
            self.verify_teacher_owns_class(material.class_id, user_id)
                .await?;
        } else {
            self.verify_student_enrolled(material.class_id, user_id)
                .await?;
        }

        let files = self
            .material_repo
            .find_files_by_material(material_id)
            .await?;

        let file_responses: Vec<FileMetadataResponse> = files
            .into_iter()
            .map(|f| FileMetadataResponse {
                id: f.id,
                file_name: f.file_name,
                file_type: f.file_type,
                file_size: f.file_size,
                uploaded_at: f.uploaded_at.to_string(),
            })
            .collect();

        Ok(MaterialDetailResponse {
            id: material.id,
            class_id: material.class_id,
            title: material.title,
            description: material.description,
            content_text: material.content_text,
            order_index: material.order_index,
            files: file_responses,
            created_at: material.created_at.to_string(),
            updated_at: material.updated_at.to_string(),
        })
    }

    pub async fn update_material(
        &self,
        material_id: Uuid,
        request: UpdateMaterialRequest,
        teacher_id: Uuid,
    ) -> AppResult<MaterialResponse> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        let title = if let Some(t) = &request.title {
            Some(Self::validate_title(t)?)
        } else {
            None
        };

        let description = if let Some(d) = &request.description {
            Some(Self::validate_description(&Some(d.clone()))?)
        } else {
            None
        };

        let content_text = if let Some(c) = &request.content_text {
            Some(Self::validate_content_text(&Some(c.clone()))?)
        } else {
            None
        };

        let updated = self
            .material_repo
            .update_material(material_id, title, description, content_text)
            .await?;

        let file_count = self
            .material_repo
            .count_files_by_material(material_id)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_updated",
                Some(teacher_id),
                Some(format!("Learning material '{}' updated", updated.title)),
            )
            .await;

        Ok(MaterialResponse {
            id: updated.id,
            class_id: updated.class_id,
            title: updated.title,
            description: updated.description,
            content_text: updated.content_text,
            order_index: updated.order_index,
            file_count,
            created_at: updated.created_at.to_string(),
            updated_at: updated.updated_at.to_string(),
        })
    }

    pub async fn delete_material(&self, material_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        self.material_repo.delete_material(material_id).await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_deleted",
                Some(teacher_id),
                Some(format!("Learning material '{}' deleted", material.title)),
            )
            .await;

        Ok(())
    }

    pub async fn reorder_material(
        &self,
        material_id: Uuid,
        request: ReorderMaterialRequest,
        teacher_id: Uuid,
    ) -> AppResult<MaterialResponse> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        if request.new_order_index < 0 {
            return Err(AppError::BadRequest(
                "Order index must be non-negative".to_string(),
            ));
        }

        let updated = self
            .material_repo
            .update_order_index(material_id, request.new_order_index)
            .await?;

        let file_count = self
            .material_repo
            .count_files_by_material(material_id)
            .await?;

        Ok(MaterialResponse {
            id: updated.id,
            class_id: updated.class_id,
            title: updated.title,
            description: updated.description,
            content_text: updated.content_text,
            order_index: updated.order_index,
            file_count,
            created_at: updated.created_at.to_string(),
            updated_at: updated.updated_at.to_string(),
        })
    }

    // ===== FILE MANAGEMENT =====

    pub async fn upload_file(
        &self,
        material_id: Uuid,
        file_name: String,
        file_type: String,
        file_data: Vec<u8>,
        teacher_id: Uuid,
    ) -> AppResult<FileMetadataResponse> {
        let material = self
            .material_repo
            .find_by_id(material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        let file_size = file_data.len() as i64;
        let file_size_mb = file_size / (1024 * 1024);

        if file_size_mb > MAX_FILE_SIZE_MB {
            return Err(AppError::BadRequest(format!(
                "File size exceeds maximum of {} MB",
                MAX_FILE_SIZE_MB
            )));
        }

        let current_file_count = self
            .material_repo
            .count_files_by_material(material_id)
            .await?;

        if current_file_count >= MAX_FILES_PER_MATERIAL {
            return Err(AppError::BadRequest(format!(
                "Maximum of {} files per material exceeded",
                MAX_FILES_PER_MATERIAL
            )));
        }

        let file = self
            .material_repo
            .save_file(material_id, file_name, file_type, file_size, file_data)
            .await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_file_uploaded",
                Some(teacher_id),
                Some(format!(
                    "File '{}' uploaded to material '{}'",
                    file.file_name, material.title
                )),
            )
            .await;

        Ok(FileMetadataResponse {
            id: file.id,
            file_name: file.file_name,
            file_type: file.file_type,
            file_size: file.file_size,
            uploaded_at: file.uploaded_at.to_string(),
        })
    }

    pub async fn delete_file(&self, file_id: Uuid, teacher_id: Uuid) -> AppResult<()> {
        let file = self
            .material_repo
            .find_file_by_id(file_id)
            .await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        let material = self
            .material_repo
            .find_by_id(file.material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        self.verify_teacher_owns_class(material.class_id, teacher_id)
            .await?;

        self.material_repo.delete_file(file_id).await?;

        let _ = self
            .activity_log_repo
            .create_log(
                teacher_id,
                "material_file_deleted",
                Some(teacher_id),
                Some(format!("File '{}' deleted", file.file_name)),
            )
            .await;

        Ok(())
    }

    pub async fn download_file(
        &self,
        file_id: Uuid,
        user_id: Uuid,
        role: &str,
    ) -> AppResult<(String, String, Vec<u8>)> {
        let file = self
            .material_repo
            .find_file_by_id(file_id)
            .await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        let material = self
            .material_repo
            .find_by_id(file.material_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Material not found".to_string()))?;

        if role == "teacher" {
            self.verify_teacher_owns_class(material.class_id, user_id)
                .await?;
        } else {
            self.verify_student_enrolled(material.class_id, user_id)
                .await?;
        }

        Ok((file.file_name, file.file_type, file.file_data))
    }

    pub async fn get_materials_metadata(&self) -> AppResult<LearningMaterialMetadataResponse> {
        let materials = self.material_repo.find_all().await?;
        let count = materials.len();

        let last_modified = if count > 0 {
            materials
                .iter()
                .map(|m| m.updated_at)
                .max()
                .unwrap_or_else(|| chrono::Utc::now().naive_utc())
        } else {
            chrono::Utc::now().naive_utc()
        };

        let etag_data = format!("{}-{}", count, last_modified);
        let etag = format!("{:x}", md5::compute(etag_data.as_bytes()));

        Ok(LearningMaterialMetadataResponse {
            last_modified: last_modified.to_string(),
            record_count: count,
            etag,
        })
    }
}
