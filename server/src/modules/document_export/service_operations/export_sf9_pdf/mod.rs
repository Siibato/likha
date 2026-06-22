use std::sync::Arc;

use printpdf::*;
use uuid::Uuid;

use crate::modules::document_export::helpers::pdf_engine::PdfEngine;
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;
use crate::utils::{AppError, AppResult};

pub mod layout;
pub mod page1_left;
pub mod page1_right;
pub mod page2_left;
pub mod page2_right;

// Re-export all layout constants so page modules can use `super::*`
pub use layout::*;

impl DocumentExportService {
    pub async fn export_sf9_pdf(
        &self,
        class_id: Uuid,
        student_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<Vec<u8>> {
        run(
            &self.grade_service,
            &self.setup_service,
            class_id,
            student_id,
            teacher_id,
        )
        .await
    }
}

pub async fn run(
    grade_service: &Arc<GradeComputationService>,
    setup_service: &Arc<SetupService>,
    class_id: Uuid,
    student_id: Uuid,
    teacher_id: Uuid,
) -> AppResult<Vec<u8>> {
    let sf9 = grade_service
        .compute_sf9(class_id, student_id, teacher_id)
        .await?;
    let settings = setup_service.get_school_details().await?;

    let engine = PdfEngine::new_with_size("SF9", Mm(layout::PAGE_W), Mm(layout::PAGE_H))
        .map_err(|e| AppError::InternalServerError(format!("PDF init: {}", e)))?;

    let seal_bytes = load_asset("deped_seal.png");
    let seal_img = seal_bytes.as_ref().and_then(|b| PdfEngine::load_png(b).ok());

    let school_name = settings.school_name.clone().unwrap_or_default();
    let region = settings.school_region.clone().unwrap_or_default();
    let division = settings.school_division.clone().unwrap_or_default();
    let district = settings.school_district.clone().unwrap_or_default();
    let school_head_name = settings.school_head_name.clone().unwrap_or_default();
    let school_year = sf9
        .school_year
        .clone()
        .unwrap_or_else(|| settings.school_year.clone().unwrap_or_default());

    let (p1, l1) = (engine.first_page, engine.first_layer);
    let layer1 = engine.get_layer(p1, l1);

    // ── Dev: center split line on page 1 ──
    layout::draw_center_split_line(&engine, &layer1, 0.3);

    page1_right::draw_page1_right(
        &engine,
        &layer1,
        &sf9,
        &school_name,
        &region,
        &division,
        &district,
        &school_year,
        &school_head_name,
        seal_img,
    );

    page1_left::draw_page1_left(&engine, &layer1, &sf9);

    let (p2, l2) = engine.add_page(Mm(layout::PAGE_W), Mm(layout::PAGE_H));
    let layer2 = engine.get_layer(p2, l2);

    // ── Dev: center split line on page 2 ──
    layout::draw_center_split_line(&engine, &layer2, 0.3);

    page2_left::draw_page2_left(&engine, &layer2, &sf9);
    page2_right::draw_page2_right(&engine, &layer2);

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("PDF save: {}", e)))
}

fn load_asset(name: &str) -> Option<Vec<u8>> {
    let path = format!("assets/images/{}", name);
    std::fs::read(&path).ok()
}
