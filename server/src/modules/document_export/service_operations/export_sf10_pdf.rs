use std::sync::Arc;

use printpdf::*;
use uuid::Uuid;

use crate::modules::document_export::helpers::pdf_engine::PdfEngine;
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::setup::service::SetupService;
use crate::modules::student_records::service::StudentRecordsService;
use crate::utils::{AppError, AppResult};

const PAGE_W: f32 = 210.0;
const PAGE_H: f32 = 297.0;
const MARGIN: f32 = 20.0;

impl DocumentExportService {
    pub async fn export_sf10_pdf(
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

    let engine = PdfEngine::new("SF10")
        .map_err(|e| AppError::InternalServerError(format!("PDF init: {}", e)))?;

    let (p1, l1) = engine.add_page(Mm(PAGE_W), Mm(PAGE_H));
    let layer = engine.get_layer(p1, l1);

    let school_name = settings.school_name.clone().unwrap_or_default();
    let school_year = sf10.current_school_year.clone().unwrap_or_default();

    engine.draw_text(&layer, "SF10 — Learner's Permanent Record", 14.0, Mm(MARGIN), Mm(PAGE_H - MARGIN - 20.0), true);
    engine.draw_text(&layer, &format!("School: {}", school_name), 11.0, Mm(MARGIN), Mm(PAGE_H - MARGIN - 30.0), false);
    engine.draw_text(&layer, &format!("School Year: {}", school_year), 11.0, Mm(MARGIN), Mm(PAGE_H - MARGIN - 40.0), false);
    engine.draw_text(&layer, &format!("Name: {}", sf10.student_name), 12.0, Mm(MARGIN), Mm(PAGE_H - MARGIN - 55.0), true);

    if let Some(lrn) = &sf10.lrn {
        engine.draw_text(&layer, &format!("LRN: {}", lrn), 11.0, Mm(MARGIN), Mm(PAGE_H - MARGIN - 65.0), false);
    }

    let mut y = PAGE_H - MARGIN - 80.0;
    for record in &sf10.scholastic_records {
        engine.draw_text(
            &layer,
            &format!(
                "{} — {} {} — Gen Avg: {}",
                record.school_year,
                record.grade_level,
                record.section.as_deref().unwrap_or(""),
                record.final_average.map(|f| f.to_string()).unwrap_or_else(|| "N/A".to_string()),
            ),
            10.0,
            Mm(MARGIN),
            Mm(y),
            true,
        );
        y -= 6.0;
        for subject in &record.subjects {
            engine.draw_text(
                &layer,
                &format!(
                    "  {} — Q1:{} Q2:{} Q3:{} Q4:{} Final:{}",
                    subject.class_title,
                    subject.period_grades.first().and_then(|g| g.map(|v| v.to_string())).unwrap_or_else(|| "-".to_string()),
                    subject.period_grades.get(1).and_then(|g| g.map(|v| v.to_string())).unwrap_or_else(|| "-".to_string()),
                    subject.period_grades.get(2).and_then(|g| g.map(|v| v.to_string())).unwrap_or_else(|| "-".to_string()),
                    subject.period_grades.get(3).and_then(|g| g.map(|v| v.to_string())).unwrap_or_else(|| "-".to_string()),
                    subject.final_grade.map(|f| f.to_string()).unwrap_or_else(|| "-".to_string()),
                ),
                9.0,
                Mm(MARGIN + 5.0),
                Mm(y),
                false,
            );
            y -= 5.0;
        }
        y -= 8.0;
    }

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("PDF save: {}", e)))
}
