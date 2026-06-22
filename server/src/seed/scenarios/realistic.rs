//! Realistic seeding scenario.

use sea_orm::DatabaseConnection;

use crate::seed::fixtures::realistic as fixtures;
use crate::seed::generators;
use crate::seed::inserters;
use crate::seed::tools::{disable_foreign_keys, enable_foreign_keys, SeedContext};
use crate::utils::AppError;

pub async fn seed_realistic_world(db: &DatabaseConnection) -> Result<(), AppError> {
    let ctx = SeedContext::new();

    let school = fixtures::realistic_school_details(&ctx);
    let users = fixtures::realistic_users(&ctx);
    let classes = fixtures::realistic_classes(&ctx);
    let enrollments = fixtures::realistic_enrollments();
    let learner_details = fixtures::realistic_learner_details();
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

    inserters::school::insert_school_details(db, &school).await?;
    inserters::users::insert_users(db, &users).await?;
    inserters::learner_details::insert_learner_details(db, &learner_details).await?;
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

    let term_grades = generate_term_grades(&students, &grade_records, &grade_scores, &grade_items, &enrollments, &ctx);
    inserters::grading::insert_term_grades(db, &term_grades, ctx.now()).await?;

    enable_foreign_keys(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

    println!(
        "Realistic seed complete: {} users, {} classes, {} enrollments, {} learner details, {} TOS, {} competencies, {} assessments, {} assignments, {} materials, {} assessment submissions, {} assignment submissions, {} grade records, {} grade items, {} grade scores, {} term grades",
        users.len(), classes.len(), enrollments.len(), learner_details.len(), tos_list.len(), competencies.len(),
        assessments.len(), assignments.len(), materials.len(), assessment_submissions.len(),
        assignment_submissions.len(), grade_records.len(), grade_items.len(), grade_scores.len(),
        term_grades.len()
    );

    Ok(())
}

fn generate_grade_records(classes: &[crate::seed::specs::ClassSpec]) -> Vec<crate::seed::specs::GradeRecordSpec> {
    use crate::modules::grading::helpers::deped_weights::get_preset;
    let mut records = Vec::new();
    for class in classes {
        if class.deleted_at.is_some() { continue; }
        let subject_group = if class.title.contains("English") { "language" }
            else if class.title.contains("Science") { "math_sci" }
            else if class.title.contains("Advisory") { "mapeh_tle" }
            else { "math_sci" };
        let preset = get_preset(subject_group)
            .unwrap_or(crate::modules::grading::helpers::deped_weights::WeightPreset { ww: 40.0, pt: 40.0, qa: 20.0 });
        for term in 1..=4 {
            records.push(crate::seed::specs::GradeRecordSpec {
                class_id: class.id,
                term_number: term,
                ww_weight: preset.ww,
                pt_weight: preset.pt,
                qa_weight: preset.qa,
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
        let id = seed_id("grade_items", &format!("assess_{}_{}", a.id, a.term_number));
        items.push(crate::seed::specs::GradeItemSpec {
            id, class_id: a.class_id, title: a.title.clone(), component: a.component.clone(),
            term_number: a.term_number, total_points: a.total_points as f64,
            source_type: "assessment".into(), source_id: Some(a.id.to_string()), order_index: 0,
        });
    }

    for a in assignments {
        if !a.is_published || a.deleted_at.is_some() || a.due_at > now { continue; }
        let id = seed_id("grade_items", &format!("assign_{}_{}", a.id, a.term_number));
        items.push(crate::seed::specs::GradeItemSpec {
            id, class_id: a.class_id, title: a.title.clone(), component: a.component.clone(),
            term_number: a.term_number, total_points: a.total_points as f64,
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
            let grade_item_id = seed_id("grade_items", &format!("assess_{}_{}", a.id, a.term_number));
            scores.push(crate::seed::specs::GradeScoreSpec {
                grade_item_id, student_id: student.id, score: Some(base_score),
                is_auto_populated: true, override_score,
                component: a.component.clone(),
                term_number: a.term_number,
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
            let grade_item_id = seed_id("grade_items", &format!("assign_{}_{}", a.id, a.term_number));
            scores.push(crate::seed::specs::GradeScoreSpec {
                grade_item_id, student_id: student.id, score: Some(base_score),
                is_auto_populated: true, override_score,
                component: a.component.clone(),
                term_number: a.term_number,
            });
        }
    }

    scores
}

fn generate_term_grades(
    students: &[crate::seed::specs::UserSpec],
    grade_records: &[crate::seed::specs::GradeRecordSpec],
    grade_scores: &[crate::seed::specs::GradeScoreSpec],
    grade_items: &[crate::seed::specs::GradeItemSpec],
    enrollments: &[crate::seed::specs::EnrollmentSpec],
    _ctx: &SeedContext,
) -> Vec<crate::seed::specs::TermGradeSpec> {
    use crate::modules::grading::helpers::deped_weights::transmute_grade;
    use uuid::Uuid;
    let mut term_grades = Vec::new();

    let mut class_students: std::collections::HashMap<Uuid, Vec<usize>> = std::collections::HashMap::new();
    for (idx, student) in students.iter().enumerate() {
        if student.role != "student" { continue; }
        for e in enrollments {
            if e.user_id == student.id {
                class_students.entry(e.class_id).or_default().push(idx);
            }
        }
    }

    let item_map: std::collections::HashMap<Uuid, (String, f64)> = grade_items.iter()
        .map(|i| (i.id, (i.component.clone(), i.total_points)))
        .collect();

    for record in grade_records {
        let enrolled = class_students.get(&record.class_id).cloned().unwrap_or_default();
        for &student_idx in &enrolled {
            let student_id = students[student_idx].id;

            let student_scores: Vec<_> = grade_scores.iter()
                .filter(|s| s.student_id == student_id && s.term_number == record.term_number)
                .collect();

            let mut ww_sum = 0.0;
            let mut ww_total = 0.0;
            let mut pt_sum = 0.0;
            let mut pt_total = 0.0;
            let mut qa_sum = 0.0;
            let mut qa_total = 0.0;

            for s in student_scores {
                let effective = s.override_score.or(s.score).unwrap_or(0.0);
                if let Some((component, total_points)) = item_map.get(&s.grade_item_id) {
                    match component.as_str() {
                        "written_work" => { ww_sum += effective; ww_total += *total_points; }
                        "performance_task" => { pt_sum += effective; pt_total += *total_points; }
                        "term_assessment" => { qa_sum += effective; qa_total += *total_points; }
                        _ => {}
                    }
                }
            }

            let ww_pct = if ww_total > 0.0 { (ww_sum / ww_total) * 100.0 } else { 0.0 };
            let pt_pct = if pt_total > 0.0 { (pt_sum / pt_total) * 100.0 } else { 0.0 };
            let qa_pct = if qa_total > 0.0 { (qa_sum / qa_total) * 100.0 } else { 0.0 };

            let initial_grade = ww_pct * (record.ww_weight / 100.0)
                + pt_pct * (record.pt_weight / 100.0)
                + qa_pct * (record.qa_weight / 100.0);

            let transmuted = transmute_grade(initial_grade);

            term_grades.push(crate::seed::specs::TermGradeSpec {
                class_id: record.class_id, student_id,
                term_number: record.term_number,
                initial_grade: Some(initial_grade), transmuted_grade: Some(transmuted),
                is_locked: false,
            });
        }
    }

    term_grades
}
