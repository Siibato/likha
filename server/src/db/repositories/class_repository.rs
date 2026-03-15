use chrono::{Utc, NaiveDateTime};
use sea_orm::*;
use uuid::Uuid;
use md5;

use ::entity::{class_participants, classes, users};
use crate::utils::{AppError, AppResult};

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
        teacher_id: Uuid,
        client_id: Option<Uuid>,
    ) -> AppResult<classes::Model> {
        // Start a transaction for atomic class + teacher participant creation
        let txn = self.db.begin().await
            .map_err(|e| AppError::InternalServerError(format!("Transaction error: {}", e)))?;

        // Insert the class
        let class_id = client_id.unwrap_or_else(Uuid::new_v4);
        let now = Utc::now().naive_utc();
        let class = classes::ActiveModel {
            id: Set(class_id),
            title: Set(title),
            description: Set(description),
            is_archived: Set(false),
            created_at: Set(now),
            updated_at: Set(now),
            deleted_at: Set(None),
        };

        let created_class = class
            .insert(&txn)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to create class: {}", e)))?;

        // Insert the teacher as a participant
        let participant = class_participants::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(class_id),
            user_id: Set(teacher_id),
            joined_at: Set(now),
            updated_at: Set(now),
            removed_at: Set(None),
        };

        participant
            .insert(&txn)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add teacher participant: {}", e)))?;

        // Commit the transaction
        txn.commit().await
            .map_err(|e| AppError::InternalServerError(format!("Transaction commit error: {}", e)))?;

        Ok(created_class)
    }

    pub async fn find_by_user_id(&self, user_id: Uuid, role: &str) -> AppResult<Vec<classes::Model>> {
        let user = users::Entity::find_by_id(user_id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        // Check if user's role matches the requested role
        if user.is_none() || user.as_ref().unwrap().role != role {
            return Ok(vec![]);
        }

        let class_ids: Vec<Uuid> = class_participants::Entity::find()
            .filter(class_participants::Column::UserId.eq(user_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .into_iter()
            .map(|p| p.class_id)
            .collect();

        if class_ids.is_empty() {
            return Ok(vec![]);
        }

        classes::Entity::find()
            .filter(classes::Column::Id.is_in(class_ids))
            .filter(classes::Column::IsArchived.eq(false))
            .order_by_desc(classes::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_teacher_id(&self, teacher_id: Uuid) -> AppResult<Vec<classes::Model>> {
        self.find_by_user_id(teacher_id, "teacher").await
    }

    pub async fn find_all(&self) -> AppResult<Vec<classes::Model>> {
        classes::Entity::find()
            .filter(classes::Column::IsArchived.eq(false))
            .order_by_desc(classes::Column::CreatedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<classes::Model>> {
        classes::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))
    }

    pub async fn update_class(
        &self,
        id: Uuid,
        title: Option<String>,
        description: Option<Option<String>>,
    ) -> AppResult<classes::Model> {
        let class = classes::Entity::find_by_id(id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let mut active_class: classes::ActiveModel = class.into();
        active_class.updated_at = Set(Utc::now().naive_utc());

        if let Some(title) = title {
            active_class.title = Set(title);
        }

        if let Some(description) = description {
            active_class.description = Set(description);
        }

        active_class
            .update(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to update class: {}", e)))
    }

    pub async fn add_participant(
        &self,
        class_id: Uuid,
        user_id: Uuid,
    ) -> AppResult<class_participants::Model> {
        // Check if participant already exists (possibly removed)
        let existing = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::UserId.eq(user_id))
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(existing_participant) = existing {
            // If removed_at is set, resurrect the participant
            if existing_participant.removed_at.is_some() {
                let update = class_participants::ActiveModel {
                    id: Set(existing_participant.id),
                    removed_at: Set(None),
                    updated_at: Set(Utc::now().naive_utc()),
                    ..Default::default()
                };

                return update
                    .update(&self.db)
                    .await
                    .map_err(|e| {
                        AppError::InternalServerError(format!("Failed to add participant: {}", e))
                    });
            }
            // If participant is already active, return existing record
            return Ok(existing_participant);
        }

        // Create new participant record
        let participant = class_participants::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(class_id),
            user_id: Set(user_id),
            joined_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            removed_at: Set(None),
        };

        participant
            .insert(&self.db)
            .await
            .map_err(|e| {
                AppError::InternalServerError(format!("Failed to add participant: {}", e))
            })
    }

    pub async fn add_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<class_participants::Model> {
        self.add_participant(class_id, student_id).await
    }

    pub async fn remove_participant(
        &self,
        class_id: Uuid,
        user_id: Uuid,
    ) -> AppResult<()> {
        let participant = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::UserId.eq(user_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(participant) = participant {
            let update = class_participants::ActiveModel {
                id: Set(participant.id),
                removed_at: Set(Some(Utc::now().naive_utc())),
                ..Default::default()
            };

            update
                .update(&self.db)
                .await
                .map_err(|e| {
                    AppError::InternalServerError(format!("Failed to remove participant: {}", e))
                })?;
        }

        Ok(())
    }

    pub async fn remove_student(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<()> {
        self.remove_participant(class_id, student_id).await
    }

    pub async fn find_participants_by_class_id(
        &self,
        class_id: Uuid,
        role: Option<&str>,
    ) -> AppResult<Vec<class_participants::Model>> {
        let mut participants = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .order_by_asc(class_participants::Column::JoinedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        // Filter by user role if specified
        if let Some(role_filter) = role {
            let mut filtered = Vec::new();
            for participant in participants {
                if let Some(user) = users::Entity::find_by_id(participant.user_id)
                    .one(&self.db)
                    .await
                    .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))? {
                    if user.role == role_filter {
                        filtered.push(participant);
                    }
                }
            }
            participants = filtered;
        }

        Ok(participants)
    }

    pub async fn find_enrollments_by_class_id(
        &self,
        class_id: Uuid,
    ) -> AppResult<Vec<class_participants::Model>> {
        self.find_participants_by_class_id(class_id, Some("student")).await
    }

    pub async fn find_participants_by_user_id(
        &self,
        user_id: Uuid,
        role: Option<&str>,
    ) -> AppResult<Vec<class_participants::Model>> {
        let mut participants = class_participants::Entity::find()
            .filter(class_participants::Column::UserId.eq(user_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .order_by_asc(class_participants::Column::JoinedAt)
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        // Filter by user role if specified
        if let Some(role_filter) = role {
            let user = users::Entity::find_by_id(user_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

            if let Some(user) = user {
                if user.role != role_filter {
                    participants.clear();
                }
            } else {
                participants.clear();
            }
        }

        Ok(participants)
    }

    pub async fn find_classes_by_student_id(
        &self,
        student_id: Uuid,
    ) -> AppResult<Vec<classes::Model>> {
        self.find_by_user_id(student_id, "student").await
    }

    pub async fn count_students_in_class(&self, class_id: Uuid) -> AppResult<usize> {
        let students = self.find_participants_by_class_id(class_id, Some("student")).await?;
        Ok(students.len())
    }

    pub async fn is_student_enrolled(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<bool> {
        let participant = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::UserId.eq(student_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(p) = participant {
            let user = users::Entity::find_by_id(student_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
            Ok(user.is_some() && user.unwrap().role == "student")
        } else {
            Ok(false)
        }
    }

    pub async fn is_user_participating(
        &self,
        class_id: Uuid,
        user_id: Uuid,
    ) -> AppResult<bool> {
        let participant = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::UserId.eq(user_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(participant.is_some())
    }

    pub async fn find_teacher_of_class(&self, class_id: Uuid) -> AppResult<Option<users::Model>> {
        let participants = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .all(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        for participant in participants {
            if let Some(user) = users::Entity::find_by_id(participant.user_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))? {
                if user.role == "teacher" {
                    return Ok(Some(user));
                }
            }
        }
        Ok(None)
    }

    pub async fn is_teacher_of_class(&self, user_id: Uuid, class_id: Uuid) -> AppResult<bool> {
        let participant = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::UserId.eq(user_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        if let Some(p) = participant {
            let user = users::Entity::find_by_id(user_id)
                .one(&self.db)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;
            Ok(user.is_some() && user.unwrap().role == "teacher")
        } else {
            Ok(false)
        }
    }

    pub async fn get_metadata(&self, teacher_id: Uuid) -> AppResult<(NaiveDateTime, usize, String)> {
        let classes = self.find_by_teacher_id(teacher_id).await?;

        let count = classes.len();

        let last_modified = if count > 0 {
            classes
                .iter()
                .map(|c| c.updated_at)
                .max()
                .unwrap_or_else(|| Utc::now().naive_utc())
        } else {
            Utc::now().naive_utc()
        };

        let etag_data = format!("{}-{}", count, last_modified);
        let etag = format!("{:x}", md5::compute(etag_data.as_bytes()));

        Ok((last_modified, count, etag))
    }

    pub async fn find_student_enrollments(&self, student_id: Uuid) -> AppResult<Vec<class_participants::Model>> {
        self.find_participants_by_user_id(student_id, Some("student")).await
    }

    pub async fn soft_delete(&self, id: Uuid) -> AppResult<()> {
        let class = classes::ActiveModel {
            id: Set(id),
            deleted_at: Set(Some(Utc::now().naive_utc())),
            updated_at: Set(Utc::now().naive_utc()),
            ..Default::default()
        };

        classes::Entity::update(class)
            .exec(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to delete class: {}", e)))?;

        Ok(())
    }

    pub async fn reassign_teacher(
        &self,
        class_id: Uuid,
        new_teacher_id: Uuid,
    ) -> AppResult<()> {
        let txn = self.db.begin().await
            .map_err(|e| AppError::InternalServerError(format!("Transaction error: {}", e)))?;

        // Soft-remove current teacher
        let participants = class_participants::Entity::find()
            .filter(class_participants::Column::ClassId.eq(class_id))
            .filter(class_participants::Column::RemovedAt.is_null())
            .all(&txn)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        for participant in participants {
            if let Some(user) = users::Entity::find_by_id(participant.user_id)
                .one(&txn)
                .await
                .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))? {
                if user.role == "teacher" {
                    let old_teacher_participant = participant;
                    let update = class_participants::ActiveModel {
                        id: Set(old_teacher_participant.id),
                        removed_at: Set(Some(Utc::now().naive_utc())),
                        updated_at: Set(Utc::now().naive_utc()),
                        ..Default::default()
                    };

                    update
                        .update(&txn)
                        .await
                        .map_err(|e| AppError::InternalServerError(format!("Failed to remove old teacher: {}", e)))?;
                    break;
                }
            }
        }

        // Add new teacher
        let new_participant = class_participants::ActiveModel {
            id: Set(Uuid::new_v4()),
            class_id: Set(class_id),
            user_id: Set(new_teacher_id),
            joined_at: Set(Utc::now().naive_utc()),
            updated_at: Set(Utc::now().naive_utc()),
            removed_at: Set(None),
        };

        new_participant
            .insert(&txn)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Failed to add new teacher: {}", e)))?;

        txn.commit().await
            .map_err(|e| AppError::InternalServerError(format!("Transaction commit error: {}", e)))?;

        Ok(())
    }
}
