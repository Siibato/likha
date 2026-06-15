use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::{Sf9Response, Sf9SubjectRow, Sf9QuarterlyAverages};
use crate::utils::{AppError, AppResult};
use crate::modules::grading::helpers::deped_weights;

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_sf9(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<Sf9Response> {
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        if let Some(ref cache) = self.cache {
            let key = CacheKey::SF9(class_id, student_id).as_str();
            if let Some(cached) = cache.get::<Sf9Response>(&key).await {
                return Ok(cached);
            }
        }

        let class = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !class.is_advisory {
            return Err(AppError::BadRequest("Class is not an advisory class".to_string()));
        }

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

        let result = Sf9Response {
            student_id: student_id.to_string(),
            student_name,
            grade_level: class.grade_level.clone(),
            school_year: class.school_year.clone(),
            section: Some(class.title.clone()),
            subjects,
            general_average,
        };
        if let Some(ref cache) = self.cache {
            let key = CacheKey::SF9(class_id, student_id).as_str();
            cache.set(&key, &result, cache.ttl.detail_seconds).await;
        }
        Ok(result)
    }

    pub(crate) async fn get_student_name(&self, student_id: Uuid) -> AppResult<String> {
        use sea_orm::EntityTrait;
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
