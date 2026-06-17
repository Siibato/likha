//! Realistic seeding scenario.

use sea_orm::DatabaseConnection;

use crate::seed::fixtures::realistic as fixtures;
use crate::seed::generators;
use crate::seed::inserters;
use crate::seed::tools::{disable_foreign_keys, enable_foreign_keys, SeedContext};
use crate::utils::AppError;

pub async fn seed_realistic_world(db: &DatabaseConnection) -> Result<(), AppError> {
    let ctx = SeedContext::new();

    let school = fixtures::realistic_school_settings(&ctx);
    let users = fixtures::realistic_users(&ctx);
    let classes = fixtures::realistic_classes(&ctx);
    let enrollments = fixtures::realistic_enrollments();
    let tos_list = fixtures::realistic_tos();
    let competencies = fixtures::realistic_competencies();
    let assessments = fixtures::realistic_assessments(&ctx);
    let assignments = fixtures::realistic_assignments(&ctx);
    let materials = fixtures::realistic_materials(&ctx);

    let teachers: Vec<_> = users.iter().filter(|u| u.role == "teacher").cloned().collect();
    let students: Vec<_> = users.iter().filter(|u| u.role == "student").cloned().collect();

    let assessment_submissions = generators::submissions::generate_assessment_submissions(
        &ctx, &assessments, &students, &enrollments,
    );
    let assignment_submissions = generators::submissions::generate_assignment_submissions(
        &ctx, &assignments, &students, &teachers, &enrollments,
    );

    let grade_records = generate_grade_records(&classes);

    disable_foreign_keys(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

    inserters::school::insert_school_settings(db, &school).await?;
    inserters::users::insert_users(db, &users).await?;
    inserters::classes::insert_classes(db, &classes).await?;
    inserters::classes::insert_enrollments(db, &enrollments).await?;
    inserters::tos::insert_tos(db, &tos_list).await?;
    inserters::tos::insert_competencies(db, &competencies).await?;

    for spec in &assessments {
        inserters::assessments::insert_assessment_with_questions(db, spec).await?;
    }

    for spec in &assignments {
        inserters::assignments::insert_assignment(db, spec).await?;
    }

    inserters::materials::insert_materials(db, &materials).await?;

    inserters::submissions::insert_assessment_submissions(db, &assessment_submissions).await?;
    inserters::submissions::insert_assignment_submissions(db, &assignment_submissions).await?;

    inserters::grading::insert_grade_records(db, &grade_records, ctx.now()).await?;

    let grade_items = generate_grade_items(&assessments, &assignments, &ctx);
    inserters::grading::insert_grade_items(db, &grade_items, ctx.now()).await?;

    let grade_scores = generate_grade_scores(&students, &assessments, &assignments, &enrollments, &ctx);
    inserters::grading::insert_grade_scores(db, &grade_scores, ctx.now()).await?;

    let period_grades = generate_period_grades(&students, &grade_records, &grade_scores, &enrollments, &ctx);
    inserters::grading::insert_period_grades(db, &period_grades, ctx.now()).await?;

    enable_foreign_keys(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

    println!(
        "Realistic seed complete: {} users, {} classes, {} enrollments, {} TOS, {} competencies, {} assessments, {} assignments, {} materials, {} assessment submissions, {} assignment submissions, {} grade records, {} grade items, {} grade scores, {} period grades",
        users.len(), classes.len(), enrollments.len(), tos_list.len(), competencies.len(),
        assessments.len(), assignments.len(), materials.len(), assessment_submissions.len(),
        assignment_submissions.len(), grade_records.len(), grade_items.len(), grade_scores.len(),
        period_grades.len()
    );

    Ok(())
}

fn generate_grade_records(classes: &[crate::seed::specs::ClassSpec]) -> Vec<crate::seed::specs::GradeRecordSpec> {
    let mut records = Vec::new();
    for class in classes {
        if class.deleted_at.is_some() { continue; }
        for period in 1..=2 {
            records.push(crate::seed::specs::GradeRecordSpec {
                class_id: class.id,
                grading_period_number: period,
                ww_weight: 40.0,
                pt_weight: 40.0,
                qa_weight: 20.0,
            });
        }
    }
    records
}

fn generate_grade_items(
    assessments: &[crate::seed::specs::AssessmentSpec],
    assignments: &[crate::seed::specs::AssignmentSpec],
    ctx: &SeedContext,
) -> Vec<crate::seed::specs::GradeItemSpec> {
    use crate::seed::tools::seed_id;
    let mut items = Vec::new();
    let now = ctx.now();

    for a in assessments {
        if !a.is_published || a.deleted_at.is_some() || a.open_at > now { continue; }
        let id = seed_id("grade_items", &format!("assess_{}_{}", a.id, a.grading_period_number));
        items.push(crate::seed::specs::GradeItemSpec {
            id, class_id: a.class_id, title: a.title.clone(), component: a.component.clone(),
            grading_period_number: a.grading_period_number, total_points: a.total_points as f64,
            source_type: "assessment".into(), source_id: Some(a.id.to_string()), order_index: 0,
        });
    }

    for a in assignments {
        if !a.is_published || a.deleted_at.is_some() || a.due_at > now { continue; }
        let id = seed_id("grade_items", &format!("assign_{}_{}", a.id, a.grading_period_number));
        items.push(crate::seed::specs::GradeItemSpec {
            id, class_id: a.class_id, title: a.title.clone(), component: a.component.clone(),
            grading_period_number: a.grading_period_number, total_points: a.total_points as f64,
            source_type: "assignment".into(), source_id: Some(a.id.to_string()), order_index: 0,
        });
    }

    items
}

fn generate_grade_scores(
    students: &[crate::seed::specs::UserSpec],
    assessments: &[crate::seed::specs::AssessmentSpec],
    assignments: &[crate::seed::specs::AssignmentSpec],
    enrollments: &[crate::seed::specs::EnrollmentSpec],
    ctx: &SeedContext,
) -> Vec<crate::seed::specs::GradeScoreSpec> {
    use crate::seed::tools::seed_id;
    use uuid::Uuid;
    let mut scores = Vec::new();
    let now = ctx.now();

    let mut class_students: std::collections::HashMap<Uuid, Vec<usize>> = std::collections::HashMap::new();
    for (idx, student) in students.iter().enumerate() {
        for e in enrollments {
            if e.user_id == student.id {
                class_students.entry(e.class_id).or_default().push(idx);
            }
        }
    }

    let mut item_counter = 0;
    for a in assessments {
        if !a.is_published || a.deleted_at.is_some() || a.open_at > now { continue; }
        let enrolled = class_students.get(&a.class_id).cloned().unwrap_or_default();
        for &student_idx in &enrolled {
            let student = &students[student_idx];
            item_counter += 1;
            let has_override = (student_idx + item_counter) % 20 == 0;
            let base_score = (60.0 + ((student_idx + item_counter) % 40) as f64) / 100.0 * a.total_points as f64;
            let override_score = if has_override { Some(base_score * 1.1) } else { None };
            let grade_item_id = seed_id("grade_items", &format!("assess_{}_{}", a.id, a.grading_period_number));
            scores.push(crate::seed::specs::GradeScoreSpec {
                grade_item_id, student_id: student.id, score: Some(base_score),
                is_auto_populated: true, override_score,
            });
        }
    }

    for a in assignments {
        if !a.is_published || a.deleted_at.is_some() || a.due_at > now { continue; }
        let enrolled = class_students.get(&a.class_id).cloned().unwrap_or_default();
        for &student_idx in &enrolled {
            let student = &students[student_idx];
            item_counter += 1;
            let has_override = (student_idx + item_counter) % 20 == 0;
            let base_score = (60.0 + ((student_idx + item_counter) % 40) as f64) / 100.0 * a.total_points as f64;
            let override_score = if has_override { Some(base_score * 1.1) } else { None };
            let grade_item_id = seed_id("grade_items", &format!("assign_{}_{}", a.id, a.grading_period_number));
            scores.push(crate::seed::specs::GradeScoreSpec {
                grade_item_id, student_id: student.id, score: Some(base_score),
                is_auto_populated: true, override_score,
            });
        }
    }

    scores
}

fn generate_period_grades(
    students: &[crate::seed::specs::UserSpec],
    grade_records: &[crate::seed::specs::GradeRecordSpec],
    grade_scores: &[crate::seed::specs::GradeScoreSpec],
    enrollments: &[crate::seed::specs::EnrollmentSpec],
    ctx: &SeedContext,
) -> Vec<crate::seed::specs::PeriodGradeSpec> {
    use crate::modules::grading::helpers::deped_weights::transmute_grade;
    use uuid::Uuid;
    let mut period_grades = Vec::new();

    let mut class_students: std::collections::HashMap<Uuid, Vec<usize>> = std::collections::HashMap::new();
    for (idx, student) in students.iter().enumerate() {
        if student.role != "student" { continue; }
        for e in enrollments {
            if e.user_id == student.id {
                class_students.entry(e.class_id).or_default().push(idx);
            }
        }
    }

    for record in grade_records {
        let enrolled = class_students.get(&record.class_id).cloned().unwrap_or_default();
        for &student_idx in &enrolled {
            let student_id = students[student_idx].id;
            let student_scores: Vec<f64> = grade_scores
                .iter().filter(|s| s.student_id == student_id).filter_map(|s| s.score).collect();
            let initial_grade = if student_scores.is_empty() { 0.0 }
                else { student_scores.iter().sum::<f64>() / student_scores.len() as f64 };
            let transmuted = transmute_grade(initial_grade);
            period_grades.push(crate::seed::specs::PeriodGradeSpec {
                class_id: record.class_id, student_id,
                grading_period_number: record.grading_period_number,
                initial_grade: Some(initial_grade), transmuted_grade: Some(transmuted),
                is_locked: false, computed_at: Some(ctx.days_ago(1 + student_idx as i64)),
            });
        }
    }

    period_grades
}
