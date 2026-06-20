use uuid::Uuid;

use crate::modules::grading::helpers::deped_weights;
use crate::modules::student_records::schema::{
    Sf10Response, Sf10SchoolHistory, Sf10PreviousSubject, Sf10AttendanceMonth,
    Sf10YearRecord, Sf10SubjectRow,
};
use crate::utils::{AppError, AppResult};
use crate::modules::student_records::service::StudentRecordsService;

impl StudentRecordsService {
    pub async fn get_sf10(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<Sf10Response> {
        // Authorization: teacher must be the advisory teacher
        if !self.class_repo.is_teacher_of_class(teacher_id, class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let class = self.class_repo.find_by_id(class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !class.is_advisory {
            return Err(AppError::BadRequest("Class is not an advisory class".to_string()));
        }

        // Verify student is enrolled
        let enrolled_students = self.grade_service.repo.get_enrolled_student_ids(class_id).await?;
        let student_name = enrolled_students
            .iter()
            .find(|(id, _)| *id == student_id)
            .map(|(_, name)| name.clone())
            .ok_or_else(|| AppError::NotFound("Student not enrolled in this advisory class".to_string()))?;

        // Get learner details
        let learner_details = self.repo.get_learner_details(student_id).await?;

        // Get SF9 data for current school year (scholastic records)
        let sf9 = self.grade_service.compute_sf9(class_id, student_id, teacher_id).await?;

        // Build current year record from SF9
        let current_year = Sf10YearRecord {
            school_year: sf9.school_year.clone().unwrap_or_default(),
            grade_level: sf9.grade_level.clone().unwrap_or_default(),
            section: sf9.section.clone(),
            school_name: String::new(), // Will be filled from settings on export
            subjects: sf9.subjects.iter().map(|s| Sf10SubjectRow {
                class_title: s.class_title.clone(),
                subject_group: s.subject_group.clone(),
                term_grades: s.term_grades.clone(),
                final_grade: s.final_grade,
                descriptor: s.descriptor.clone(),
            }).collect(),
            final_average: sf9.general_average.as_ref().and_then(|ga| ga.final_average),
            descriptor: sf9.general_average.as_ref().and_then(|ga| ga.descriptor.clone()),
            attendance: Vec::new(), // Filled below
        };

        // Get attendance for current school year
        let current_attendance = self.repo.get_attendance(
            student_id,
            Some(class_id),
            class.school_year.as_deref(),
        ).await?;

        let current_attendance_months: Vec<Sf10AttendanceMonth> = current_attendance
            .iter()
            .map(|a| Sf10AttendanceMonth {
                month: a.month.clone(),
                school_days: a.school_days,
                days_present: a.days_present,
                days_absent: a.days_absent,
            })
            .collect();

        let mut scholastic_records = vec![Sf10YearRecord {
            attendance: current_attendance_months,
            ..current_year
        }];

        // Get school history (previous schools)
        let history = self.repo.get_school_history(student_id).await?;
        let mut school_history_entries: Vec<Sf10SchoolHistory> = Vec::new();

        for h in &history {
            let subjects = self.repo.get_previous_subjects(student_id, Some(h.id)).await?;
            let attendance = self.repo.get_previous_attendance(student_id, Some(h.id)).await?;

            let subject_rows: Vec<Sf10PreviousSubject> = subjects.iter().map(|s| Sf10PreviousSubject {
                subject_name: s.subject_name.clone(),
                subject_group: s.subject_group.clone(),
                q1_grade: s.q1_grade,
                q2_grade: s.q2_grade,
                q3_grade: s.q3_grade,
                q4_grade: s.q4_grade,
                final_grade: s.final_grade,
                descriptor: s.descriptor.clone(),
            }).collect();

            let attendance_months: Vec<Sf10AttendanceMonth> = attendance.iter().map(|a| Sf10AttendanceMonth {
                month: a.month.clone(),
                school_days: a.school_days,
                days_present: a.days_present,
                days_absent: a.days_absent,
            }).collect();

            school_history_entries.push(Sf10SchoolHistory {
                id: h.id.to_string(),
                school_name: h.school_name.clone(),
                school_id: h.school_id.clone(),
                grade_level: h.grade_level.clone(),
                school_year: h.school_year.clone(),
                section: h.section.clone(),
                date_from: h.date_from.map(|d| d.to_string()),
                date_to: h.date_to.map(|d| d.to_string()),
                record_type: h.record_type.clone(),
                subjects: subject_rows,
                attendance: attendance_months,
            });
        }

        // Build previous year records from school history
        for h in &history {
            let prev_subjects = self.repo.get_previous_subjects(student_id, Some(h.id)).await?;
            let prev_attendance = self.repo.get_previous_attendance(student_id, Some(h.id)).await?;

            let subject_rows: Vec<Sf10SubjectRow> = prev_subjects.iter().map(|s| {
                let final_grade = s.final_grade;
                let descriptor = final_grade.map(|fg| deped_weights::get_descriptor(fg).to_string());
                Sf10SubjectRow {
                    class_title: s.subject_name.clone(),
                    subject_group: s.subject_group.clone(),
                    term_grades: vec![s.q1_grade, s.q2_grade, s.q3_grade, s.q4_grade],
                    final_grade,
                    descriptor,
                }
            }).collect();

            let attendance_months: Vec<Sf10AttendanceMonth> = prev_attendance.iter().map(|a| Sf10AttendanceMonth {
                month: a.month.clone(),
                school_days: a.school_days,
                days_present: a.days_present,
                days_absent: a.days_absent,
            }).collect();

            let final_avg = {
                let finals: Vec<i32> = subject_rows.iter().filter_map(|s| s.final_grade).collect();
                if finals.is_empty() {
                    None
                } else {
                    let avg = finals.iter().sum::<i32>() as f64 / finals.len() as f64;
                    Some(avg.round() as i32)
                }
            };
            let descriptor = final_avg.map(|fa| deped_weights::get_descriptor(fa).to_string());

            scholastic_records.push(Sf10YearRecord {
                school_year: h.school_year.clone(),
                grade_level: h.grade_level.clone(),
                section: h.section.clone(),
                school_name: h.school_name.clone(),
                subjects: subject_rows,
                final_average: final_avg,
                descriptor,
                attendance: attendance_months,
            });
        }

        Ok(Sf10Response {
            student_id: student_id.to_string(),
            student_name,
            lrn: learner_details.as_ref().and_then(|d| d.lrn.clone()),
            birthdate: learner_details.as_ref().and_then(|d| d.birthdate.map(|b| b.to_string())),
            birthplace: learner_details.as_ref().and_then(|d| d.birthplace.clone()),
            home_address: learner_details.as_ref().and_then(|d| d.home_address.clone()),
            sex: learner_details.as_ref().and_then(|d| d.sex.clone()),
            age: learner_details.as_ref().and_then(|d| d.age),
            father_name: learner_details.as_ref().and_then(|d| d.father_name.clone()),
            mother_name: learner_details.as_ref().and_then(|d| d.mother_name.clone()),
            guardian_name: learner_details.as_ref().and_then(|d| d.guardian_name.clone()),
            guardian_contact: learner_details.as_ref().and_then(|d| d.guardian_contact.clone()),
            track_strand: learner_details.as_ref().and_then(|d| d.track_strand.clone()),
            curriculum: learner_details.as_ref().and_then(|d| d.curriculum.clone()),
            current_school_year: class.school_year.clone(),
            current_grade_level: class.grade_level.clone(),
            current_section: Some(class.title.clone()),
            school_history: school_history_entries,
            scholastic_records,
        })
    }
}
