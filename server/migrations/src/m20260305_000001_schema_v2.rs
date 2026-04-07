use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Create class_participants table
        manager
            .create_table(
                Table::create()
                    .table(ClassParticipants::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(ClassParticipants::Id)
                            .uuid()
                            .not_null()
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(ClassParticipants::ClassId)
                            .uuid()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ClassParticipants::UserId)
                            .uuid()
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ClassParticipants::Role)
                            .string_len(20)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(ClassParticipants::JoinedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(ClassParticipants::UpdatedAt)
                            .timestamp()
                            .not_null()
                            .default(Expr::current_timestamp()),
                    )
                    .col(
                        ColumnDef::new(ClassParticipants::RemovedAt)
                            .timestamp()
                            .null(),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_participants_class")
                            .from(ClassParticipants::Table, ClassParticipants::ClassId)
                            .to(Classes::Table, Classes::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_participants_user")
                            .from(ClassParticipants::Table, ClassParticipants::UserId)
                            .to(Users::Table, Users::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;

        // Create indexes on class_participants
        manager
            .create_index(
                Index::create()
                    .name("idx_class_participants_class_id")
                    .table(ClassParticipants::Table)
                    .col(ClassParticipants::ClassId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_class_participants_user_id")
                    .table(ClassParticipants::Table)
                    .col(ClassParticipants::UserId)
                    .to_owned(),
            )
            .await?;

        manager
            .create_index(
                Index::create()
                    .name("idx_class_participants_removed_at")
                    .table(ClassParticipants::Table)
                    .col(ClassParticipants::RemovedAt)
                    .to_owned(),
            )
            .await?;

        // Migrate data from class_enrollments to class_participants (students)
        // Using INSERT ... SELECT for better compatibility
        let db = manager.get_connection();
        db.execute_unprepared(
            "INSERT INTO class_participants (id, class_id, user_id, role, joined_at, updated_at, removed_at)
             SELECT gen_random_uuid(), class_id, student_id, 'student', enrolled_at, enrolled_at, removed_at
             FROM class_enrollments"
        )
        .await
        .ok();

        // Migrate teachers from classes to class_participants
        db.execute_unprepared(
            "INSERT INTO class_participants (id, class_id, user_id, role, joined_at, updated_at, removed_at)
             SELECT gen_random_uuid(), id, teacher_id, 'teacher', created_at, created_at, NULL
             FROM classes"
        )
        .await
        .ok();

        // Drop the class_enrollments table
        manager
            .drop_table(Table::drop().table(ClassEnrollments::Table).to_owned())
            .await?;

        // Drop teacher_id FK index from classes
        manager
            .drop_index(
                Index::drop()
                    .name("idx_classes_teacher_id")
                    .table(Classes::Table)
                    .to_owned(),
            )
            .await
            .ok();

        // For SQLite, we need to recreate the classes table without teacher_id
        // First, we'll use raw SQL to handle this since SQLite doesn't support dropping FK constraints
        let db = manager.get_connection();

        // SQLite: recreate classes table without teacher_id using BEGIN/COMMIT for transaction safety
        db.execute_unprepared("BEGIN").await?;

        db.execute_unprepared(
            "CREATE TABLE classes_new (
                id uuid_text NOT NULL PRIMARY KEY,
                title varchar(255) NOT NULL,
                description text,
                is_archived INTEGER NOT NULL DEFAULT 0,
                deleted_at timestamp_text NULL,
                created_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP
            )"
        )
        .await?;

        db.execute_unprepared(
            "INSERT INTO classes_new (id, title, description, is_archived, deleted_at, created_at, updated_at)
             SELECT id, title, description, COALESCE(is_archived, 0), deleted_at, created_at, updated_at FROM classes"
        )
        .await?;

        db.execute_unprepared("DROP TABLE classes").await?;

        db.execute_unprepared(
            "ALTER TABLE classes_new RENAME TO classes"
        )
        .await?;

        db.execute_unprepared("COMMIT").await?;

        // For SQLite, recreate users table without is_active and created_by, add deleted_at
        db.execute_unprepared("BEGIN").await?;

        db.execute_unprepared(
            "CREATE TABLE users_new (
                id uuid_text NOT NULL PRIMARY KEY,
                username varchar(50) NOT NULL UNIQUE,
                password_hash varchar(255),
                full_name varchar(255) NOT NULL,
                role varchar(20) NOT NULL,
                account_status varchar(30) NOT NULL DEFAULT 'pending_activation',
                activated_at timestamp_text NULL,
                created_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP,
                deleted_at timestamp_text NULL
            )"
        )
        .await?;

        db.execute_unprepared(
            "INSERT INTO users_new (id, username, password_hash, full_name, role, account_status, activated_at, created_at, updated_at, deleted_at)
             SELECT id, username, password_hash, full_name, role, account_status, activated_at, created_at, updated_at, NULL FROM users"
        )
        .await?;

        db.execute_unprepared("DROP TABLE users").await?;

        db.execute_unprepared(
            "ALTER TABLE users_new RENAME TO users"
        )
        .await?;

        db.execute_unprepared("COMMIT").await?;

        // Create index on users.deleted_at
        db.execute_unprepared(
            "CREATE INDEX idx_users_deleted_at ON users (deleted_at)"
        )
        .await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Reverse all changes
        let db = manager.get_connection();

        // Drop indexes
        db.execute_unprepared("DROP INDEX IF EXISTS idx_users_deleted_at").await.ok();
        db.execute_unprepared("DROP INDEX IF EXISTS idx_class_participants_removed_at").await.ok();
        db.execute_unprepared("DROP INDEX IF EXISTS idx_class_participants_user_id").await.ok();
        db.execute_unprepared("DROP INDEX IF EXISTS idx_class_participants_class_id").await.ok();

        // Restore users table with is_active and created_by
        db.execute_unprepared("BEGIN").await?;

        db.execute_unprepared(
            "CREATE TABLE users_old (
                id uuid_text NOT NULL PRIMARY KEY,
                username varchar(50) NOT NULL UNIQUE,
                password_hash varchar(255),
                full_name varchar(255) NOT NULL,
                role varchar(20) NOT NULL,
                account_status varchar(30) NOT NULL DEFAULT 'pending_activation',
                is_active boolean NOT NULL DEFAULT true,
                activated_at timestamp_text NULL,
                created_by uuid_text,
                created_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (created_by) REFERENCES users_old(id)
            )"
        )
        .await?;

        db.execute_unprepared(
            "INSERT INTO users_old (id, username, password_hash, full_name, role, account_status, is_active, activated_at, created_by, created_at, updated_at)
             SELECT id, username, password_hash, full_name, role, account_status, true, activated_at, NULL, created_at, updated_at FROM users"
        )
        .await?;

        db.execute_unprepared("DROP TABLE users").await?;

        db.execute_unprepared("ALTER TABLE users_old RENAME TO users").await?;

        db.execute_unprepared("COMMIT").await?;

        // Restore classes table with teacher_id
        db.execute_unprepared("BEGIN").await?;

        db.execute_unprepared(
            "CREATE TABLE classes_old (
                id uuid_text NOT NULL PRIMARY KEY,
                title varchar(255) NOT NULL,
                description text,
                teacher_id uuid_text NOT NULL,
                deleted_at timestamp_text NULL,
                created_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (teacher_id) REFERENCES users(id)
            )"
        )
        .await?;

        db.execute_unprepared(
            "INSERT INTO classes_old (id, title, description, teacher_id, deleted_at, created_at, updated_at)
             SELECT id, title, description, (SELECT user_id FROM class_participants WHERE class_id = classes.id AND role = 'teacher' LIMIT 1), deleted_at, created_at, updated_at FROM classes"
        )
        .await?;

        db.execute_unprepared("DROP TABLE classes").await?;

        db.execute_unprepared("ALTER TABLE classes_old RENAME TO classes").await?;

        db.execute_unprepared("COMMIT").await?;

        // Restore teacher_id index
        db.execute_unprepared("CREATE INDEX idx_classes_teacher_id ON classes (teacher_id)").await?;

        // Restore class_enrollments table
        db.execute_unprepared(
            "CREATE TABLE class_enrollments (
                id uuid_text NOT NULL PRIMARY KEY,
                class_id uuid_text NOT NULL,
                student_id uuid_text NOT NULL,
                enrolled_at timestamp_text NOT NULL DEFAULT CURRENT_TIMESTAMP,
                removed_at timestamp_text,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
                FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
            )"
        )
        .await?;

        // Migrate data from class_participants back to class_enrollments
        db.execute_unprepared(
            "INSERT INTO class_enrollments (id, class_id, student_id, enrolled_at, removed_at)
             SELECT id, class_id, user_id, joined_at, removed_at FROM class_participants WHERE role = 'student'"
        )
        .await?;

        // Restore class_enrollments indexes
        db.execute_unprepared("CREATE INDEX idx_enrollments_class_id ON class_enrollments (class_id)").await?;
        db.execute_unprepared("CREATE INDEX idx_enrollments_student_id ON class_enrollments (student_id)").await?;

        // Drop class_participants table
        db.execute_unprepared("DROP TABLE class_participants").await?;

        Ok(())
    }
}

#[derive(DeriveIden)]
enum ClassParticipants {
    Table,
    Id,
    ClassId,
    UserId,
    Role,
    JoinedAt,
    UpdatedAt,
    RemovedAt,
}

#[derive(DeriveIden)]
enum ClassEnrollments {
    Table,
}

#[derive(DeriveIden)]
enum Classes {
    Table,
    Id,
}

#[derive(DeriveIden)]
enum Users {
    Table,
    Id,
}
