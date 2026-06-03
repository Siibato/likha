use uuid::Uuid;
use crate::modules::grading::schema::{GeneralAverageResponse, StudentGeneralAverage, SubjectGrade};
use crate::utils::{AppError, AppResult};

impl crate::modules::grading::service::GradeComputationService {
    pub async fn compute_general_averages(
        &self,
        class_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<GeneralAverageResponse> {
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

    pub(crate) async fn compute_student_general_average(
        &self,
        student_id: Uuid,
        school_year: Option<&str>,
    ) -> AppResult<StudentGeneralAverage> {
        let enrolled_classes = self.repo.get_student_enrolled_classes(student_id, school_year).await?;
        let student_name = self.get_student_name(student_id).await?;

        let mut subjects = Vec::new();
        let mut final_grades: Vec<i32> = Vec::new();

        for ec in &enrolled_classes {
            let quarterly = self.repo.get_period_grades_for_student_class(
                student_id, ec.class_id,
            ).await?;

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
}
