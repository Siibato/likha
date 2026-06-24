use crate::cache::CacheKey;
use crate::modules::grading::schema::{
    GeneralAverageResponse, StudentGeneralAverage, SubjectGrade,
};
use crate::utils::{AppError, AppResult};
use uuid::Uuid;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_general_averages(
        &self,
        class_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<GeneralAverageResponse> {
        if !self
            .class_repo
            .is_teacher_of_class(teacher_id, class_id)
            .await?
        {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if let Some(ref cache) = self.cache {
            let key = CacheKey::GeneralAverages(class_id).as_str();
            if let Some(cached) = cache.get::<GeneralAverageResponse>(&key).await {
                return Ok(cached);
            }
        }

        let class = self
            .class_repo
            .find_by_id(class_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        let mut enrolled_students = self.repo.get_enrolled_student_ids(class_id).await?;
        enrolled_students.sort_by(|a, b| {
            let last_cmp = a.2.cmp(&b.2);
            if last_cmp != std::cmp::Ordering::Equal {
                return last_cmp;
            }
            a.1.cmp(&b.1)
        });
        let school_year = class.school_year.as_deref();

        // Process sequentially to avoid SQLite contention with the 5-connection pool.
        let mut students = Vec::new();
        for (student_id, first_name, last_name) in &enrolled_students {
            let student_name = format!("{}, {}", last_name, first_name);
            tracing::info!(student_id = %student_id, "Computing general average for student");
            let sga = self
                .compute_student_general_average(*student_id, student_name.clone(), school_year)
                .await
                .map_err(|e| {
                    tracing::error!(student_id = %student_id, error = %e, "Failed to compute general average for student");
                    e
                })?;
            students.push(sga);
        }

        let result = GeneralAverageResponse {
            class_id: class_id.to_string(),
            students,
        };
        if let Some(ref cache) = self.cache {
            let key = CacheKey::GeneralAverages(class_id).as_str();
            cache.set(&key, &result, cache.ttl.list_seconds).await;
        }
        Ok(result)
    }

    pub(crate) async fn compute_student_general_average(
        &self,
        student_id: Uuid,
        student_name: String,
        school_year: Option<&str>,
    ) -> AppResult<StudentGeneralAverage> {
        let enrolled_classes = self
            .repo
            .get_student_enrolled_classes(student_id, school_year)
            .await?;

        let mut subjects = Vec::new();
        let mut final_grades: Vec<i32> = Vec::new();

        for ec in &enrolled_classes {
            let term_grades = self
                .repo
                .get_term_grades_for_student_class(student_id, ec.class_id)
                .await?;

            let transmuted: Vec<i32> = term_grades
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
}
