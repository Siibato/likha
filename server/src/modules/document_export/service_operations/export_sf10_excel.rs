use std::sync::Arc;

use uuid::Uuid;

use crate::modules::document_export::helpers::excel_engine::{ExcelEngine, title_fmt, subtitle_fmt, header_fmt, data_fmt};
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::setup::service::SetupService;
use crate::modules::student_records::service::StudentRecordsService;
use crate::utils::{AppError, AppResult};

impl DocumentExportService {
    pub async fn export_sf10_excel(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<Vec<u8>> {
        run(
            &self.student_records_service,
            &self.setup_service,
            class_id,
            student_id,
            teacher_id,
        )
        .await
    }
}

pub async fn run(
    student_records_service: &Arc<StudentRecordsService>,
    setup_service: &Arc<SetupService>,
    class_id: Uuid,
    student_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<Vec<u8>> {
    let sf10 = student_records_service
        .get_sf10(class_id, student_id, teacher_id)
        .await?;
    let settings = setup_service.get_school_details().await?;

    let mut engine = ExcelEngine::new();
    let sheet = engine.worksheet();
    sheet.set_name("SF10").ok();

    let school_name = settings.school_name.clone().unwrap_or_default();
    let school_year = sf10.current_school_year.clone().unwrap_or_default();

    sheet.merge_range(0, 0, 0, 7, "SF10 — Learner's Permanent Record", &title_fmt())
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    sheet.merge_range(1, 0, 1, 7, &format!("School: {} — SY: {}", school_name, school_year), &subtitle_fmt())
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;

    sheet.write_with_format(3, 0, "Name", &header_fmt())
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    sheet.merge_range(3, 1, 3, 7, &sf10.student_name, &data_fmt())
        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;

    if let Some(lrn) = &sf10.lrn {
        sheet.write_with_format(4, 0, "LRN", &header_fmt())
            .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
        sheet.merge_range(4, 1, 4, 7, lrn, &data_fmt())
            .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
    }

    let mut row: u32 = 6;
    for record in &sf10.scholastic_records {
        let section_label = format!("{} — {} {}", record.school_year, record.grade_level, record.section.as_deref().unwrap_or(""));
        sheet.merge_range(row, 0, row, 7, &section_label, &header_fmt())
            .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
        row += 1;

        let headers = ["Subject", "T1", "T2", "T3", "T4", "Final", "Descriptor", "School"];
        for (col, h) in headers.iter().enumerate() {
            sheet.write_with_format(row, col as u16, *h, &header_fmt())
                .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
        }
        row += 1;

        for subject in &record.subjects {
            sheet.write_with_format(row, 0, &subject.class_title, &data_fmt())
                .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
            for (i, grade) in subject.term_grades.iter().enumerate() {
                if let Some(g) = grade {
                    sheet.write_with_format(row, (i + 1) as u16, *g, &data_fmt())
                        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
                } else {
                    sheet.write_with_format(row, (i + 1) as u16, "-", &data_fmt())
                        .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
                }
            }
            if let Some(fg) = subject.final_grade {
                sheet.write_with_format(row, 5, fg, &data_fmt())
                    .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
            } else {
                sheet.write_with_format(row, 5, "-", &data_fmt())
                    .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
            }
            sheet.write_with_format(row, 6, subject.descriptor.as_deref().unwrap_or("-"), &data_fmt())
                .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
            sheet.write_with_format(row, 7, &record.school_name, &data_fmt())
                .map_err(|e| AppError::InternalServerError(format!("Excel: {}", e)))?;
            row += 1;
        }
        row += 1;
    }

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("Excel save: {}", e)))
}
