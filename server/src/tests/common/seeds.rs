use chrono::Utc;
use sea_orm::{ActiveModelTrait, DatabaseConnection, EntityTrait, Set};
use uuid::Uuid;

use crate::db::repositories::{
    class_repository::ClassRepository,
    user_repository::UserRepository,
};

use super::jwt_helper::{make_admin_token, make_student_token, make_teacher_token};

pub struct SeedUser {
    pub id: Uuid,
    pub username: String,
    pub token: String,
}

pub async fn seed_teacher(db: &DatabaseConnection) -> SeedUser {
    seed_user(db, "teacher").await
}

pub async fn seed_admin(db: &DatabaseConnection) -> SeedUser {
    seed_user(db, "admin").await
}

pub async fn seed_student(db: &DatabaseConnection) -> SeedUser {
    seed_user(db, "student").await
}

/// Seeds a class and adds the given teacher as a participant. Returns class_id.
pub async fn seed_class(db: &DatabaseConnection, teacher_id: Uuid) -> Uuid {
    let class = ClassRepository::new(db.clone())
        .create_class(
            "Test Class".to_string(),
            Some("Integration test class".to_string()),
            None,
            false,
        )
        .await
        .expect("seed_class: create_class failed");

    ClassRepository::new(db.clone())
        .add_participant(class.id, teacher_id)
        .await
        .expect("seed_class: add_participant failed");

    class.id
}

/// Seeds a class, adds teacher AND student as participants.
pub async fn seed_class_with_student(
    db: &DatabaseConnection,
    teacher_id: Uuid,
    student_id: Uuid,
) -> Uuid {
    let class_id = seed_class(db, teacher_id).await;
    ClassRepository::new(db.clone())
        .add_participant(class_id, student_id)
        .await
        .expect("seed_class_with_student: add_participant failed");
    class_id
}

/// Creates a user with a hashed password so login tests work.
pub async fn seed_teacher_with_password(db: &DatabaseConnection, password: &str) -> SeedUser {
    let user = seed_teacher(db).await;
    set_password(db, user.id, password).await;
    user
}

#[allow(dead_code)]
pub async fn seed_student_with_password(db: &DatabaseConnection, password: &str) -> SeedUser {
    let user = seed_student(db).await;
    set_password(db, user.id, password).await;
    user
}

// ── Private helpers ───────────────────────────────────────────────────────────

async fn seed_user(db: &DatabaseConnection, role: &str) -> SeedUser {
    let suffix = &Uuid::new_v4().to_string()[..8];
    let username = format!("{}_{}", role, suffix);
    let full_name = format!("Test {}", role);

    let user = UserRepository::new(db.clone())
        .create_account(
            username.clone(),
            full_name,
            role.to_string(),
            None,
        )
        .await
        .unwrap_or_else(|e| panic!("seed_user({role}): create_account failed: {e:?}"));

    activate_user(db, user.id).await;

    let token = match role {
        "teacher" => make_teacher_token(user.id, &username),
        "admin" => make_admin_token(user.id, &username),
        "student" => make_student_token(user.id, &username),
        _ => panic!("seed_user: unknown role {role}"),
    };

    SeedUser {
        id: user.id,
        username,
        token,
    }
}

async fn activate_user(db: &DatabaseConnection, user_id: Uuid) {
    use entity::users;

    let user = users::Entity::find_by_id(user_id)
        .one(db)
        .await
        .unwrap()
        .unwrap_or_else(|| panic!("activate_user: user {user_id} not found"));

    let mut active: users::ActiveModel = user.into();
    active.account_status = Set("active".to_string());
    active.activated_at = Set(Some(Utc::now().naive_utc()));
    active.update(db).await.expect("activate_user: update failed");
}

async fn set_password(db: &DatabaseConnection, user_id: Uuid, password: &str) {
    let hash = bcrypt::hash(password, 4).expect("set_password: bcrypt::hash failed");
    UserRepository::new(db.clone())
        .set_password(user_id, hash)
        .await
        .expect("set_password: set_password failed");
}
