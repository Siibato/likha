use uuid::Uuid;
use crate::cache::CacheKey;
use crate::modules::grading::schema::{Sf9Response, Sf9SubjectRow, Sf9PeriodAverages};
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

        let teacher = self.class_repo.find_teacher_of_class(class_id).await?;
        let teacher_name = teacher.map(|t| t.full_name);

        let enrolled_students = self.repo.get_enrolled_student_ids(class_id).await?;
        let student_name = enrolled_students
            .iter()
            .find(|(id, _)| *id == student_id)
            .map(|(_, name)| name.clone())
            .ok_or_else(|| AppError::NotFound("Student not enrolled in this advisory class".to_string()))?;
        let enrolled_classes = self.repo.get_student_enrolled_classes(
            student_id,
            class.school_year.as_deref(),
        ).await?;

        let learner_details = self.repo.get_learner_details(student_id).await?;

        let mut subjects = Vec::new();
        let num_periods = crate::modules::grading::helpers::period_count::period_count(&class.term_type);
        let mut period_sums: Vec<Vec<i32>> = (0..num_periods).map(|_| Vec::new()).collect();
        let mut final_grades: Vec<i32> = Vec::new();

        for ec in &enrolled_classes {
            let term_grades_raw = self.repo.get_term_grades_for_student_class(
                student_id, ec.class_id,
            ).await?;

            let mut period_vals: Vec<Option<i32>> = vec![None; num_periods];
            for pg in &term_grades_raw {
                let idx = (pg.term_number - 1) as usize;
                if idx < num_periods {
                    if let Some(t) = pg.transmuted_grade {
                        period_vals[idx] = Some(t);
                        period_sums[idx].push(t);
                    }
                }
            }

            let transmuted: Vec<i32> = period_vals.iter().filter_map(|&v| v).collect();
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
                term_grades: period_vals,
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

        let general_average = Some(Sf9PeriodAverages {
            term_grades: (0..num_periods).map(|i| compute_avg(&period_sums[i])).collect(),
            final_average,
            descriptor: ga_descriptor,
        });

        let result = Sf9Response {
            student_id: student_id.to_string(),
            student_name,
            grade_level: class.grade_level.clone(),
            school_year: class.school_year.clone(),
            section: Some(class.title.clone()),
            lrn: learner_details.as_ref().and_then(|d| d.lrn.clone()),
            age: learner_details.as_ref().and_then(|d| d.age),
            sex: learner_details.as_ref().and_then(|d| d.sex.clone()),
            track_strand: learner_details.as_ref().and_then(|d| d.track_strand.clone()),
            curriculum: learner_details.as_ref().and_then(|d| d.curriculum.clone()),
            teacher_name,
            term_type: Some(class.term_type.clone()),
            subjects,
            general_average,
        };
        if let Some(ref cache) = self.cache {
            if !result.student_name.eq_ignore_ascii_case("Unknown Student") {
                let key = CacheKey::SF9(class_id, student_id).as_str();
                cache.set(&key, &result, cache.ttl.detail_seconds).await;
            }
        }
        Ok(result)
    }

}
