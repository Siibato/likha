use sea_orm::EntityTrait;
use uuid::Uuid;

use crate::schema::grading_schema::*;
use crate::utils::{AppError, AppResult};

use super::deped_weights;

impl super::GradeComputationService {
    /// Compute period grade for a single student.
    pub async fn compute_student_quarterly(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<QuarterlyGradeResponse> {
        // 1. Get weight config for this class/period
        let config = self
            .repo
            .get_config(class_id, grading_period_number)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(
                    "Grading config not set up for this class/period".to_string(),
                )
            })?;

        // 2. Get all grade items for this class/period
        let items = self.repo.get_items(class_id, grading_period_number).await?;

        // 3. Group items by component
        let mut ww_items = Vec::new();
        let mut pt_items = Vec::new();
        let mut qa_items = Vec::new();
        for item in &items {
            match item.component.as_str() {
                "written_work" => ww_items.push(item),
                "performance_task" => pt_items.push(item),
                "quarterly_assessment" => qa_items.push(item),
                _ => {}
            }
        }

        // 4. Get all scores for this student in this class/period
        let scores = self
            .repo
            .get_scores_by_student_class_period(student_id, class_id, grading_period_number)
            .await?;

        // Build a map of grade_item_id -> effective_score
        let mut score_map = std::collections::HashMap::new();
        for s in &scores {
            let effective = s.override_score.or(s.score);
            if let Some(eff) = effective {
                score_map.insert(s.grade_item_id, eff);
            }
        }

        // 5. Compute per-component
        let (_, ww_weighted) = compute_component(&ww_items, &score_map, config.ww_weight);
        let (_, pt_weighted) = compute_component(&pt_items, &score_map, config.pt_weight);
        let (_, qa_weighted) = compute_component(&qa_items, &score_map, config.qa_weight);

        // 6. Initial grade
        let initial_grade = ww_weighted + pt_weighted + qa_weighted;

        // 7. Transmute
        let transmuted = deped_weights::transmute_grade(initial_grade);

        // 8. Locked when all items have scores
        let is_locked = items.iter().all(|item| score_map.contains_key(&item.id));

        // 9. Upsert period grade
        let model = self
            .repo
            .upsert_period_grade(
                class_id,
                student_id,
                grading_period_number,
                initial_grade,
                transmuted,
                is_locked,
            )
            .await?;

        Ok(QuarterlyGradeResponse::from(model))
    }

    /// Compute period grades for all enrolled students in a class.
    pub async fn compute_class_quarterly(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<Vec<QuarterlyGradeResponse>> {
        let student_ids = self.repo.get_enrolled_student_ids(class_id).await?;
        let mut results = Vec::new();
        for student_id in student_ids {
            let result = self
                .compute_student_quarterly(class_id, student_id, grading_period_number)
                .await?;
            results.push(result);
        }
        Ok(results)
    }

    /// Compute final grade for a student (average of quarterly transmuted grades).
    pub async fn compute_final_grade(
        &self,
        class_id: Uuid,
        student_id: Uuid,
    ) -> AppResult<FinalGradeResponse> {
        let quarters = self
            .repo
            .get_all_for_student(class_id, student_id)
            .await?;

        let period_responses: Vec<QuarterlyGradeResponse> =
            quarters.into_iter().map(QuarterlyGradeResponse::from).collect();

        // Compute average of locked period transmuted grades
        let locked_grades: Vec<f64> = period_responses
            .iter()
            .filter(|q| q.is_locked)
            .filter_map(|q| q.transmuted_grade.map(|t| t as f64))
            .collect();

        let final_grade = if locked_grades.is_empty() {
            None
        } else {
            Some(locked_grades.iter().sum::<f64>() / locked_grades.len() as f64)
        };

        Ok(FinalGradeResponse {
            student_id: student_id.to_string(),
            period_grades: period_responses,
            final_grade,
        })
    }

    /// Get grade summary for all students in a class/period.
    pub async fn get_grade_summary(
        &self,
        class_id: Uuid,
        grading_period_number: i32,
    ) -> AppResult<GradeSummaryResponse> {
        let config = self
            .repo
            .get_config(class_id, grading_period_number)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest(
                    "Grading config not set up for this class/period".to_string(),
                )
            })?;

        let period_grades_data = self.repo.get_all_for_class(class_id, grading_period_number).await?;

        // Get student names via participants + users
        let participants = self
            .class_repo
            .find_participants_by_class_id(class_id, None)
            .await?;

        let mut student_name_map: std::collections::HashMap<Uuid, String> =
            std::collections::HashMap::new();
        for p in &participants {
            if let Ok(Some(user)) = ::entity::users::Entity::find_by_id(p.user_id)
                .one(&self.db)
                .await
            {
                student_name_map.insert(p.user_id, user.full_name);
            }
        }

        let students = period_grades_data
            .into_iter()
            .map(|qg| {
                let descriptor = qg
                    .transmuted_grade
                    .map(|t| deped_weights::get_descriptor(t).to_string());
                GradeSummaryRow {
                    student_id: qg.student_id.to_string(),
                    student_name: student_name_map
                        .get(&qg.student_id)
                        .cloned()
                        .unwrap_or_else(|| "Unknown".to_string()),
                    initial_grade: qg.initial_grade,
                    transmuted_grade: qg.transmuted_grade,
                    descriptor,
                    is_locked: qg.is_locked,
                }
            })
            .collect();

        Ok(GradeSummaryResponse {
            class_id: class_id.to_string(),
            grading_period_number,
            ww_weight: config.ww_weight,
            pt_weight: config.pt_weight,
            qa_weight: config.qa_weight,
            students,
        })
    }

    // ===== GENERAL AVERAGE (GSA) =====

    /// Compute general averages for all students in a class.
    /// For each student, finds all their enrolled classes (same school_year)
    /// and computes average of final grades.
    pub async fn compute_general_averages(
        &self,
        class_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<GeneralAverageResponse> {
        // Verify teacher owns class
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let class = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let student_ids = self.repo.get_enrolled_student_ids(class_id).await?;
        let mut students = Vec::new();

        for student_id in student_ids {
            let student_ga = self.compute_student_general_average(
                student_id,
                class.school_year.as_deref(),
            ).await?;
            students.push(student_ga);
        }

        Ok(GeneralAverageResponse {
            class_id: class_id.to_string(),
            students,
        })
    }

    /// Compute general average for a single student across all enrolled classes.
    async fn compute_student_general_average(
        &self,
        student_id: Uuid,
        school_year: Option<&str>,
    ) -> AppResult<StudentGeneralAverage> {
        let enrolled_classes = self.repo.get_student_enrolled_classes(student_id, school_year).await?;

        // Get student name
        let student_name = self.get_student_name(student_id).await?;

        let mut subjects = Vec::new();
        let mut final_grades: Vec<i32> = Vec::new();

        for ec in &enrolled_classes {
            let quarterly = self.repo.get_period_grades_for_student_class(
                student_id, ec.class_id,
            ).await?;

            // Compute final grade = average of Q1-Q4 transmuted grades (where available)
            let transmuted: Vec<i32> = quarterly
                .iter()
                .filter_map(|qg| qg.transmuted_grade)
                .collect();

            let final_grade = if transmuted.is_empty() {
                None
            } else {
                let avg = transmuted.iter().sum::<i32>() as f64 / transmuted.len() as f64;
                Some(avg.round() as i32)
            };

            if let Some(fg) = final_grade {
                final_grades.push(fg);
            }

            subjects.push(SubjectGrade {
                class_id: ec.class_id.to_string(),
                class_title: ec.title.clone(),
                final_grade,
            });
        }

        let general_average = if final_grades.is_empty() {
            None
        } else {
            let avg = final_grades.iter().sum::<i32>() as f64 / final_grades.len() as f64;
            Some(avg.round() as i32)
        };

        Ok(StudentGeneralAverage {
            student_id: student_id.to_string(),
            student_name,
            general_average,
            subject_count: subjects.len(),
            subjects,
        })
    }

    // ===== SF9 (Learner's Progress Report Card) =====

    /// Generate SF9 report for a student in an advisory class.
    pub async fn compute_sf9(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<Sf9Response> {
        // Verify teacher owns advisory class
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let class = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !class.is_advisory {
            return Err(AppError::BadRequest("Class is not an advisory class".to_string()));
        }

        // Verify student is enrolled in this advisory class
        let enrolled_student_ids = self.repo.get_enrolled_student_ids(class_id).await?;
        if !enrolled_student_ids.contains(&student_id) {
            return Err(AppError::NotFound("Student not enrolled in this advisory class".to_string()));
        }

        let student_name = self.get_student_name(student_id).await?;
        let enrolled_classes = self.repo.get_student_enrolled_classes(
            student_id,
            class.school_year.as_deref(),
        ).await?;

        let mut subjects = Vec::new();
        // For per-quarter general averages
        let mut q_sums: [Vec<i32>; 4] = [Vec::new(), Vec::new(), Vec::new(), Vec::new()];
        let mut final_grades: Vec<i32> = Vec::new();

        for ec in &enrolled_classes {
            let quarterly = self.repo.get_period_grades_for_student_class(
                student_id, ec.class_id,
            ).await?;

            let mut q = [None, None, None, None];
            for qg in &quarterly {
                let idx = (qg.grading_period_number - 1) as usize;
                if idx < 4 {
                    if let Some(t) = qg.transmuted_grade {
                        q[idx] = Some(t);
                        q_sums[idx].push(t);
                    }
                }
            }

            // Final grade = average of available quarterly transmuted grades
            let transmuted: Vec<i32> = q.iter().filter_map(|&v| v).collect();
            let final_grade = if transmuted.is_empty() {
                None
            } else {
                let avg = transmuted.iter().sum::<i32>() as f64 / transmuted.len() as f64;
                Some(avg.round() as i32)
            };

            if let Some(fg) = final_grade {
                final_grades.push(fg);
            }

            let descriptor = final_grade.map(|fg| deped_weights::get_descriptor(fg).to_string());

            subjects.push(Sf9SubjectRow {
                class_title: ec.title.clone(),
                subject_group: None,
                q1: q[0],
                q2: q[1],
                q3: q[2],
                q4: q[3],
                final_grade,
                descriptor,
            });
        }

        // Compute per-quarter general averages
        let compute_avg = |grades: &[i32]| -> Option<i32> {
            if grades.is_empty() {
                None
            } else {
                let avg = grades.iter().sum::<i32>() as f64 / grades.len() as f64;
                Some(avg.round() as i32)
            }
        };

        let final_average = compute_avg(&final_grades);
        let ga_descriptor = final_average.map(|fa| deped_weights::get_descriptor(fa).to_string());

        let general_average = Some(Sf9QuarterlyAverages {
            q1: compute_avg(&q_sums[0]),
            q2: compute_avg(&q_sums[1]),
            q3: compute_avg(&q_sums[2]),
            q4: compute_avg(&q_sums[3]),
            final_average,
            descriptor: ga_descriptor,
        });

        Ok(Sf9Response {
            student_id: student_id.to_string(),
            student_name,
            grade_level: class.grade_level.clone(),
            school_year: class.school_year.clone(),
            section: Some(class.title.clone()),
            subjects,
            general_average,
        })
    }

    /// Get student name by ID
    async fn get_student_name(&self, student_id: Uuid) -> AppResult<String> {
        use ::entity::users;
        let user = users::Entity::find_by_id(student_id)
            .one(&self.db)
            .await
            .map_err(|e| AppError::InternalServerError(format!("Database error: {}", e)))?;

        Ok(user
            .map(|u| u.full_name)
            .unwrap_or_else(|| "Unknown Student".to_string()))
    }
}

/// Compute percentage and weighted score for a single component.
pub(crate) fn compute_component(
    items: &[&::entity::grade_items::Model],
    score_map: &std::collections::HashMap<Uuid, f64>,
    weight: f64,
) -> (f64, f64) {
    let mut sum_scores = 0.0;
    let mut sum_total = 0.0;

    for item in items {
        if let Some(&score) = score_map.get(&item.id) {
            sum_scores += score;
            sum_total += item.total_points;
        } else {
            // Item with no score: still count total_points for denominator
            sum_total += item.total_points;
        }
    }

    if sum_total <= 0.0 {
        return (0.0, 0.0);
    }

    let percentage = (sum_scores / sum_total) * 100.0;
    let weighted = percentage * (weight / 100.0);
    (percentage, weighted)
}
