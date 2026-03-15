use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // === DROP OBSOLETE TABLES (FK dependency order) ===
        // These tables are no longer part of ERD v3

        // 1. Drop submission_enumeration_answers (refs enumeration_items, submission_answers)
        db.execute_unprepared("DROP TABLE IF EXISTS submission_enumeration_answers;")
            .await?;

        // 2. Drop submission_answer_choices (refs question_choices, submission_answers)
        db.execute_unprepared("DROP TABLE IF EXISTS submission_answer_choices;")
            .await?;

        // 3. Drop enumeration_item_answers (refs enumeration_items)
        db.execute_unprepared("DROP TABLE IF EXISTS enumeration_item_answers;")
            .await?;

        // 4. Drop enumeration_items (refs assessment_questions)
        db.execute_unprepared("DROP TABLE IF EXISTS enumeration_items;")
            .await?;

        // 5. Drop question_correct_answers (refs assessment_questions)
        db.execute_unprepared("DROP TABLE IF EXISTS question_correct_answers;")
            .await?;

        // 6. Drop sync infrastructure (not in ERD v3)
        db.execute_unprepared("DROP TABLE IF EXISTS sync_conflicts;")
            .await?;
        db.execute_unprepared("DROP TABLE IF EXISTS sync_cursors;")
            .await?;
        db.execute_unprepared("DROP TABLE IF EXISTS change_log;")
            .await?;

        // 7. Drop database_metadata (not in ERD v3)
        db.execute_unprepared("DROP TABLE IF EXISTS database_metadata;")
            .await?;

        // === RECREATE/MODIFY EXISTING TABLES ===

        // === login_attempts: Complete rebuild ===
        // Old schema no longer applies; rebuild from scratch
        db.execute_unprepared("DROP TABLE IF EXISTS login_attempts;")
            .await?;
        db.execute_unprepared(
            r#"
            CREATE TABLE login_attempts (
                id TEXT PRIMARY KEY,
                user_id TEXT,
                attempted_at TIMESTAMP NOT NULL,
                success BOOLEAN NOT NULL,
                device_id TEXT,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;

        // === activity_logs: Remove performed_by column ===
        db.execute_unprepared(
            r#"
            CREATE TABLE activity_logs_new (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                action VARCHAR(50) NOT NULL,
                details TEXT,
                created_at TIMESTAMP NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO activity_logs_new (id, user_id, action, details, created_at)
            SELECT id, user_id, action, details, created_at FROM activity_logs;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE activity_logs;")
            .await?;
        db.execute_unprepared("ALTER TABLE activity_logs_new RENAME TO activity_logs;")
            .await?;

        // === refresh_tokens: Add UNIQUE constraint on token_hash ===
        db.execute_unprepared(
            r#"
            CREATE TABLE refresh_tokens_new (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                token_hash TEXT NOT NULL UNIQUE,
                device_id TEXT,
                expires_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP NOT NULL,
                revoked_at TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO refresh_tokens_new (id, user_id, token_hash, device_id, expires_at, created_at, revoked_at)
            SELECT id, user_id, token_hash, device_id, expires_at, created_at, revoked_at FROM refresh_tokens;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE refresh_tokens;")
            .await?;
        db.execute_unprepared("ALTER TABLE refresh_tokens_new RENAME TO refresh_tokens;")
            .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);",
        )
        .await?;

        // === class_participants: Remove role, add UNIQUE(class_id, user_id) ===
        db.execute_unprepared(
            r#"
            CREATE TABLE class_participants_new (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                joined_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                removed_at TIMESTAMP,
                UNIQUE(class_id, user_id),
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO class_participants_new (id, class_id, user_id, joined_at, updated_at, removed_at)
            SELECT id, class_id, user_id, joined_at, updated_at, removed_at FROM class_participants;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE class_participants;")
            .await?;
        db.execute_unprepared("ALTER TABLE class_participants_new RENAME TO class_participants;")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_class_participants_class_id ON class_participants(class_id);")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_class_participants_user_id ON class_participants(user_id);")
            .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_class_participants_removed_at ON class_participants(removed_at);",
        )
        .await?;

        // === assessments: Drop last_modified_at ===
        db.execute_unprepared("DROP INDEX IF EXISTS idx_assessments_last_modified_at;")
            .await?;
        db.execute_unprepared(
            r#"
            CREATE TABLE assessments_new (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                title VARCHAR(255) NOT NULL,
                description TEXT,
                time_limit_minutes INTEGER NOT NULL,
                open_at TIMESTAMP NOT NULL,
                close_at TIMESTAMP NOT NULL,
                show_results_immediately BOOLEAN NOT NULL,
                results_released BOOLEAN NOT NULL,
                is_published BOOLEAN NOT NULL,
                total_points INTEGER NOT NULL DEFAULT 0,
                order_index INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (class_id) REFERENCES classes(id)
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO assessments_new (id, class_id, title, description, time_limit_minutes, open_at, close_at,
                                         show_results_immediately, results_released, is_published, total_points,
                                         order_index, created_at, updated_at, deleted_at)
            SELECT id, class_id, title, description, time_limit_minutes, open_at, close_at,
                   show_results_immediately, results_released, is_published, total_points,
                   order_index, created_at, updated_at, deleted_at FROM assessments;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE assessments;")
            .await?;
        db.execute_unprepared("ALTER TABLE assessments_new RENAME TO assessments;")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_assessments_class_id ON assessments(class_id);")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_assessments_deleted_at ON assessments(deleted_at);")
            .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assessments_class_order ON assessments(class_id, order_index);",
        )
        .await?;

        // === assessment_submissions: Rename student_id->user_id, drop auto/final scores, add total_points, add UNIQUE ===
        db.execute_unprepared(
            r#"
            CREATE TABLE assessment_submissions_new (
                id TEXT PRIMARY KEY,
                assessment_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                started_at TIMESTAMP NOT NULL,
                submitted_at TIMESTAMP,
                total_points INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                UNIQUE(assessment_id, user_id),
                FOREIGN KEY (assessment_id) REFERENCES assessments(id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO assessment_submissions_new (id, assessment_id, user_id, started_at, submitted_at,
                                                    total_points, created_at, updated_at, deleted_at)
            SELECT id, assessment_id, student_id, started_at, submitted_at, 0, created_at, updated_at, deleted_at
            FROM assessment_submissions;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE assessment_submissions;")
            .await?;
        db.execute_unprepared("ALTER TABLE assessment_submissions_new RENAME TO assessment_submissions;")
            .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assessment_submissions_assessment_id ON assessment_submissions(assessment_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assessment_submissions_user_id ON assessment_submissions(user_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assessment_submissions_updated_at ON assessment_submissions(updated_at);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assessment_submissions_deleted_at ON assessment_submissions(deleted_at);",
        )
        .await?;

        // === submission_answers: Redesign (drop old answer columns, add points & override tracking) ===
        db.execute_unprepared(
            r#"
            CREATE TABLE submission_answers_new (
                id TEXT PRIMARY KEY,
                submission_id TEXT NOT NULL,
                question_id TEXT NOT NULL,
                points REAL NOT NULL DEFAULT 0.0,
                overridden_by TEXT,
                overridden_at TIMESTAMP,
                FOREIGN KEY (submission_id) REFERENCES assessment_submissions(id),
                FOREIGN KEY (question_id) REFERENCES assessment_questions(id),
                FOREIGN KEY (overridden_by) REFERENCES users(id)
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO submission_answers_new (id, submission_id, question_id, points, overridden_by, overridden_at)
            SELECT id, submission_id, question_id, points_awarded, NULL, NULL FROM submission_answers;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE submission_answers;")
            .await?;
        db.execute_unprepared("ALTER TABLE submission_answers_new RENAME TO submission_answers;")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_submission_answers_submission_id ON submission_answers(submission_id);")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_submission_answers_question_id ON submission_answers(question_id);")
            .await?;

        // === assignments: Drop last_modified_at ===
        db.execute_unprepared("DROP INDEX IF EXISTS idx_assignments_last_modified_at;")
            .await?;
        db.execute_unprepared(
            r#"
            CREATE TABLE assignments_new (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                title VARCHAR(200) NOT NULL,
                instructions TEXT NOT NULL,
                total_points INTEGER NOT NULL,
                submission_type VARCHAR(50) NOT NULL,
                allowed_file_types TEXT,
                max_file_size_mb INTEGER,
                due_at TIMESTAMP NOT NULL,
                is_published BOOLEAN NOT NULL,
                order_index INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (class_id) REFERENCES classes(id)
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO assignments_new (id, class_id, title, instructions, total_points, submission_type,
                                         allowed_file_types, max_file_size_mb, due_at, is_published,
                                         order_index, created_at, updated_at, deleted_at)
            SELECT id, class_id, title, instructions, total_points, submission_type,
                   allowed_file_types, max_file_size_mb, due_at, is_published,
                   order_index, created_at, updated_at, deleted_at FROM assignments;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE assignments;")
            .await?;
        db.execute_unprepared("ALTER TABLE assignments_new RENAME TO assignments;")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_assignments_class_id ON assignments(class_id);")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_assignments_deleted_at ON assignments(deleted_at);")
            .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assignments_class_order ON assignments(class_id, order_index);",
        )
        .await?;

        // === assignment_submissions: Rename score->points, add graded_by ===
        db.execute_unprepared(
            r#"
            CREATE TABLE assignment_submissions_new (
                id TEXT PRIMARY KEY,
                assignment_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                status VARCHAR(20) NOT NULL,
                text_content TEXT,
                submitted_at TIMESTAMP,
                is_late BOOLEAN NOT NULL,
                points INTEGER,
                feedback TEXT,
                graded_at TIMESTAMP,
                graded_by TEXT,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                UNIQUE(assignment_id, student_id),
                FOREIGN KEY (assignment_id) REFERENCES assignments(id),
                FOREIGN KEY (student_id) REFERENCES users(id),
                FOREIGN KEY (graded_by) REFERENCES users(id)
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO assignment_submissions_new (id, assignment_id, student_id, status, text_content,
                                                    submitted_at, is_late, points, feedback, graded_at,
                                                    graded_by, created_at, updated_at, deleted_at)
            SELECT id, assignment_id, student_id, status, text_content,
                   submitted_at, is_late, score, feedback, graded_at,
                   NULL, created_at, updated_at, deleted_at FROM assignment_submissions;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE assignment_submissions;")
            .await?;
        db.execute_unprepared("ALTER TABLE assignment_submissions_new RENAME TO assignment_submissions;")
            .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assignment_submissions_assignment_id ON assignment_submissions(assignment_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assignment_submissions_student_id ON assignment_submissions(student_id);",
        )
        .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_assignment_submissions_deleted_at ON assignment_submissions(deleted_at);",
        )
        .await?;

        // === learning_materials: Drop last_modified_at ===
        db.execute_unprepared("DROP INDEX IF EXISTS idx_learning_materials_last_modified_at;")
            .await?;
        db.execute_unprepared(
            r#"
            CREATE TABLE learning_materials_new (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                title VARCHAR(200) NOT NULL,
                description TEXT,
                content_text TEXT,
                order_index INTEGER NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                deleted_at TIMESTAMP,
                FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
            );
            "#,
        )
        .await?;
        db.execute_unprepared(
            r#"
            INSERT INTO learning_materials_new (id, class_id, title, description, content_text,
                                                order_index, created_at, updated_at, deleted_at)
            SELECT id, class_id, title, description, content_text,
                   order_index, created_at, updated_at, deleted_at FROM learning_materials;
            "#,
        )
        .await?;
        db.execute_unprepared("DROP TABLE learning_materials;")
            .await?;
        db.execute_unprepared("ALTER TABLE learning_materials_new RENAME TO learning_materials;")
            .await?;
        db.execute_unprepared("CREATE INDEX idx_learning_materials_class_id ON learning_materials(class_id);")
            .await?;
        db.execute_unprepared(
            "CREATE INDEX idx_learning_materials_class_order ON learning_materials(class_id, order_index);",
        )
        .await?;
        db.execute_unprepared("CREATE INDEX idx_learning_materials_deleted_at ON learning_materials(deleted_at);")
            .await?;

        // === CREATE NEW TABLES ===

        // === answer_keys ===
        manager
            .create_table(
                Table::create()
                    .table(AnswerKeys::Table)
                    .col(ColumnDef::new(AnswerKeys::Id).string_len(36).primary_key())
                    .col(ColumnDef::new(AnswerKeys::QuestionId).string_len(36).not_null())
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_answer_keys_question_id")
                            .from(AnswerKeys::Table, AnswerKeys::QuestionId)
                            .to(AssessmentQuestions::Table, AssessmentQuestions::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;
        manager
            .create_index(
                Index::create()
                    .name("idx_answer_keys_question_id")
                    .table(AnswerKeys::Table)
                    .col(AnswerKeys::QuestionId)
                    .to_owned(),
            )
            .await?;

        // === answer_key_acceptable_answers ===
        manager
            .create_table(
                Table::create()
                    .table(AnswerKeyAcceptableAnswers::Table)
                    .col(
                        ColumnDef::new(AnswerKeyAcceptableAnswers::Id)
                            .string_len(36)
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(AnswerKeyAcceptableAnswers::AnswerKeyId)
                            .string_len(36)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(AnswerKeyAcceptableAnswers::AnswerText)
                            .text()
                            .not_null(),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_answer_key_acceptable_answers_answer_key_id")
                            .from(AnswerKeyAcceptableAnswers::Table, AnswerKeyAcceptableAnswers::AnswerKeyId)
                            .to(AnswerKeys::Table, AnswerKeys::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .to_owned(),
            )
            .await?;
        manager
            .create_index(
                Index::create()
                    .name("idx_answer_key_acceptable_answers_answer_key_id")
                    .table(AnswerKeyAcceptableAnswers::Table)
                    .col(AnswerKeyAcceptableAnswers::AnswerKeyId)
                    .to_owned(),
            )
            .await?;

        // === submission_answer_items ===
        manager
            .create_table(
                Table::create()
                    .table(SubmissionAnswerItems::Table)
                    .col(
                        ColumnDef::new(SubmissionAnswerItems::Id)
                            .string_len(36)
                            .primary_key(),
                    )
                    .col(
                        ColumnDef::new(SubmissionAnswerItems::SubmissionAnswerId)
                            .string_len(36)
                            .not_null(),
                    )
                    .col(
                        ColumnDef::new(SubmissionAnswerItems::AnswerKeyId)
                            .string_len(36)
                            .null(),
                    )
                    .col(
                        ColumnDef::new(SubmissionAnswerItems::ChoiceId)
                            .string_len(36)
                            .null(),
                    )
                    .col(
                        ColumnDef::new(SubmissionAnswerItems::AnswerText)
                            .text()
                            .null(),
                    )
                    .col(
                        ColumnDef::new(SubmissionAnswerItems::IsCorrect)
                            .boolean()
                            .not_null(),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_submission_answer_items_submission_answer_id")
                            .from(SubmissionAnswerItems::Table, SubmissionAnswerItems::SubmissionAnswerId)
                            .to(SubmissionAnswers::Table, SubmissionAnswers::Id)
                            .on_delete(ForeignKeyAction::Cascade),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_submission_answer_items_answer_key_id")
                            .from(SubmissionAnswerItems::Table, SubmissionAnswerItems::AnswerKeyId)
                            .to(AnswerKeys::Table, AnswerKeys::Id)
                            .on_delete(ForeignKeyAction::SetNull),
                    )
                    .foreign_key(
                        ForeignKey::create()
                            .name("fk_submission_answer_items_choice_id")
                            .from(SubmissionAnswerItems::Table, SubmissionAnswerItems::ChoiceId)
                            .to(QuestionChoices::Table, QuestionChoices::Id)
                            .on_delete(ForeignKeyAction::SetNull),
                    )
                    .to_owned(),
            )
            .await?;
        manager
            .create_index(
                Index::create()
                    .name("idx_submission_answer_items_submission_answer_id")
                    .table(SubmissionAnswerItems::Table)
                    .col(SubmissionAnswerItems::SubmissionAnswerId)
                    .to_owned(),
            )
            .await?;
        manager
            .create_index(
                Index::create()
                    .name("idx_submission_answer_items_answer_key_id")
                    .table(SubmissionAnswerItems::Table)
                    .col(SubmissionAnswerItems::AnswerKeyId)
                    .to_owned(),
            )
            .await?;
        manager
            .create_index(
                Index::create()
                    .name("idx_submission_answer_items_choice_id")
                    .table(SubmissionAnswerItems::Table)
                    .col(SubmissionAnswerItems::ChoiceId)
                    .to_owned(),
            )
            .await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // Schema v3 migration is irreversible due to data transformations and table drops
        Err(DbErr::Migration(
            "Schema v3 migration is irreversible; restore from backup if needed".to_string(),
        ))
    }
}

#[derive(DeriveIden)]
enum AnswerKeys {
    Table,
    Id,
    QuestionId,
}

#[derive(DeriveIden)]
enum AnswerKeyAcceptableAnswers {
    Table,
    Id,
    AnswerKeyId,
    AnswerText,
}

#[derive(DeriveIden)]
enum SubmissionAnswerItems {
    Table,
    Id,
    SubmissionAnswerId,
    AnswerKeyId,
    ChoiceId,
    AnswerText,
    IsCorrect,
}

#[derive(DeriveIden)]
enum AssessmentQuestions {
    Table,
    Id,
}

#[derive(DeriveIden)]
enum QuestionChoices {
    Table,
    Id,
}

#[derive(DeriveIden)]
enum SubmissionAnswers {
    Table,
    Id,
}
