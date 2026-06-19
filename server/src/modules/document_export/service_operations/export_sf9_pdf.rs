use std::sync::Arc;

use printpdf::*;
use uuid::Uuid;

use crate::modules::document_export::helpers::pdf_engine::{PdfEngine, grey300};
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::grading::schema::Sf9Response;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;
use crate::utils::{AppError, AppResult};

// Letter landscape: 11" × 8.5" in mm
const PAGE_W: f32 = 279.4;
const PAGE_H: f32 = 215.9;
const MARGIN: f32 = 12.0;
const MID: f32 = PAGE_W / 2.0; // ~139.7

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
    let settings = setup_service.get_school_settings().await?;

    let engine = PdfEngine::new_with_size("SF9", Mm(PAGE_W), Mm(PAGE_H))
        .map_err(|e| AppError::InternalServerError(format!("PDF init: {}", e)))?;

    let seal_bytes = load_asset("deped_seal.png");
    let logo_bytes = load_asset("deped_logo.png");

    let seal_img = seal_bytes.as_ref().and_then(|b| PdfEngine::load_png(b).ok());
    let logo_img = logo_bytes.as_ref().and_then(|b| PdfEngine::load_png(b).ok());

    let school_name = settings.school_name.clone().unwrap_or_default();
    let region = settings.school_region.clone().unwrap_or_default();
    let division = settings.school_division.clone().unwrap_or_default();
    let district = settings.school_district.clone().unwrap_or_default();
    let school_head_name = settings.school_head_name.clone().unwrap_or_default();
    let school_head_position = settings.school_head_position.clone().unwrap_or_default();
    let school_id = settings.school_code.clone();
    let school_year = sf9
        .school_year
        .clone()
        .unwrap_or_else(|| settings.school_year.clone().unwrap_or_default());

    // Use the first page that PdfEngine::new already creates — do NOT add_page here
    let (p1, l1) = (engine.first_page, engine.first_layer);
    let layer1 = engine.get_layer(p1, l1);
    draw_page1(
        &engine,
        &layer1,
        &sf9,
        &school_name,
        &region,
        &division,
        &district,
        &school_id,
        &school_year,
        &school_head_name,
        &school_head_position,
        seal_img,
        logo_img,
    );

    // Page 2
    let (p2, l2) = engine.add_page(Mm(PAGE_W), Mm(PAGE_H));
    let layer2 = engine.get_layer(p2, l2);
    draw_page2(&engine, &layer2, &sf9);

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("PDF save: {}", e)))
}

fn load_asset(name: &str) -> Option<Vec<u8>> {
    let path = format!("assets/images/{}", name);
    std::fs::read(&path).ok()
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 1
// Left  half: Attendance, Certificate of Transfer, Cancellation
// Right half: SF9 label, DepEd header + seal, student info, Dear Parent, sigs
// ─────────────────────────────────────────────────────────────────────────────
fn draw_page1(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    sf9: &Sf9Response,
    school_name: &str,
    region: &str,
    division: &str,
    district: &str,
    school_id: &str,
    school_year: &str,
    school_head_name: &str,
    school_head_position: &str,
    seal: Option<Image>,
    logo: Option<Image>,
) {
    let top = PAGE_H - MARGIN; // ~203.9
    let left = MARGIN;         // 12.0
    let right = PAGE_W - MARGIN; // ~267.4
    let col_split = MID - 2.0; // ~137.7
    let l_w = col_split - left; // left column width
    let rx = col_split + 4.0;  // right column left edge
    let r_w = right - rx;      // right column width

    // ── RIGHT HALF ──────────────────────────────────────────────────────────

    // "SF9 - JHS" top-left of right column
    engine.draw_text(layer, "SF9 - JHS", 8.0, Mm(rx), Mm(top), true);

    // DepEd seal — left side of header, bigger (scale ~0.13)
    let seal_x = rx;
    let seal_y = top - 22.0;
    if let Some(img) = seal {
        img.add_to_layer(
            layer.clone(),
            ImageTransform {
                translate_x: Some(Mm(seal_x)),
                translate_y: Some(Mm(seal_y)),
                scale_x: Some(0.13),
                scale_y: Some(0.13),
                ..Default::default()
            },
        );
    }

    // DepEd logo — right side of header, bigger (scale ~0.13)
    let logo_x = right - 20.0;
    if let Some(img) = logo {
        img.add_to_layer(
            layer.clone(),
            ImageTransform {
                translate_x: Some(Mm(logo_x)),
                translate_y: Some(Mm(seal_y)),
                scale_x: Some(0.13),
                scale_y: Some(0.13),
                ..Default::default()
            },
        );
    }

    // DepEd text — centered in right column, next to seal
    let text_x = rx + 22.0; // leave room for seal on left
    let r_text_center = text_x + (logo_x - text_x) / 2.0;
    let mut hy = top - 6.0;
    engine.draw_text(
        layer,
        "Republic of the Philippines",
        7.0,
        Mm(r_text_center - 22.0),
        Mm(hy),
        false,
    );
    hy -= 5.0;
    engine.draw_text(
        layer,
        "Department of Education",
        8.5,
        Mm(r_text_center - 20.0),
        Mm(hy),
        true,
    );

    // School metadata — centered with underlines
    hy -= 7.0;
    draw_header_line(engine, layer, &format!("Region {}", region), 7.0, r_text_center, hy, 55.0);
    hy -= 7.0;
    draw_header_line(engine, layer, &format!("Division of {}", division), 7.0, r_text_center, hy, 70.0);
    if !district.is_empty() {
        hy -= 7.0;
        draw_header_line(engine, layer, district, 7.0, r_text_center, hy, 70.0);
    }
    hy -= 7.0;
    draw_header_line(engine, layer, school_name, 7.0, r_text_center, hy, 80.0);
    hy -= 7.0;
    draw_header_line(engine, layer, school_id, 7.0, r_text_center, hy, 40.0);

    // "LEARNER'S PROGRESS REPORT CARD"
    hy -= 9.0;
    engine.draw_text(
        layer,
        "LEARNER'S PROGRESS REPORT CARD",
        9.5,
        Mm(r_text_center - 44.0),
        Mm(hy),
        true,
    );

    // LRN row
    hy -= 7.0;
    engine.draw_text(layer, "Learner's Reference Number:", 7.0, Mm(rx), Mm(hy), true);
    let lrn = sf9.lrn.as_deref().unwrap_or("");
    let lrn_box_start = rx + 52.0;
    for i in 0..12usize {
        let ch = lrn.chars().nth(i).map(|c| c.to_string()).unwrap_or_default();
        let bx = lrn_box_start + i as f32 * 5.5;
        engine.draw_rect(layer, Mm(bx), Mm(hy - 4.5), Mm(5.0), Mm(5.0), None, true);
        engine.draw_text(layer, &ch, 6.0, Mm(bx + 1.2), Mm(hy - 3.2), false);
    }

    // Student info fields — using underlines not boxes
    hy -= 7.0;
    draw_field_line(engine, layer, "Name (Last, First, Middle):", &sf9.student_name, rx, hy, r_w);

    hy -= 7.0;
    let hw = r_w / 2.0 - 3.0;
    draw_field_line(engine, layer, "Age:", &sf9.age.map(|a| a.to_string()).unwrap_or_default(), rx, hy, hw);
    draw_field_line(engine, layer, "Sex:", sf9.sex.as_deref().unwrap_or(""), rx + hw + 6.0, hy, hw);

    hy -= 7.0;
    draw_field_line(engine, layer, "Grade:", sf9.grade_level.as_deref().unwrap_or(""), rx, hy, hw);
    draw_field_line(engine, layer, "Section:", sf9.section.as_deref().unwrap_or(""), rx + hw + 6.0, hy, hw);

    hy -= 7.0;
    draw_field_line(engine, layer, "School Year:", school_year, rx, hy, r_w);

    // Dear Parent
    hy -= 8.0;
    engine.draw_text(layer, "Dear Parent,", 7.0, Mm(rx), Mm(hy), false);
    hy -= 5.5;
    let letter = "This report card shows the ability and progress your child has made in different learning areas as well as his/her core values. The school welcomes you should you desire to know more about your child's progress.";
    draw_wrapped_text(engine, layer, letter, rx, hy, r_w, 6.5);

    // Principal / Teacher signature block
    let sig_y = MARGIN + 14.0; // anchor near bottom
    let sig_w = r_w / 2.0 - 6.0;
    draw_sig_block(engine, layer, rx, sig_y, sig_w, school_head_name, school_head_position);
    draw_sig_block(engine, layer, rx + sig_w + 12.0, sig_y, sig_w, sf9.teacher_name.as_deref().unwrap_or(""), "Teacher");

    // ── LEFT HALF ───────────────────────────────────────────────────────────
    let mut y = top;

    // Attendance Record
    engine.draw_text(layer, "ATTENDANCE RECORD", 8.0, Mm(left + l_w / 2.0 - 20.0), Mm(y), true);
    y -= 5.0;
    let att_bottom = draw_attendance_table(engine, layer, left, y, l_w);
    y = att_bottom - 8.0;

    // Certificate of Transfer
    engine.draw_text(layer, "Certificate of Transfer", 8.0, Mm(left), Mm(y), true);
    y -= 6.0;
    draw_field_line(engine, layer, "Admitted to Grade:", "", left, y, l_w / 2.0);
    draw_field_line(engine, layer, "Section:", "", left + l_w / 2.0 + 4.0, y, l_w / 2.0 - 4.0);
    y -= 6.0;
    draw_field_line(engine, layer, "Eligibility for Admission to Grade:", "", left, y, l_w);
    y -= 6.0;
    draw_field_line(engine, layer, "Approved:", "", left, y, l_w);
    y -= 10.0;
    let xfer_sig_w = l_w / 2.0 - 6.0;
    draw_sig_block(engine, layer, left, y, xfer_sig_w, "", "Principal");
    draw_sig_block(engine, layer, left + xfer_sig_w + 12.0, y, xfer_sig_w, "", "Teacher");

    // Cancellation of Eligibility to Transfer
    y -= 18.0;
    engine.draw_text(layer, "Cancellation of Eligibility to Transfer", 8.0, Mm(left), Mm(y), true);
    y -= 6.0;
    draw_field_line(engine, layer, "Admitted in:", "", left, y, l_w);
    y -= 6.0;
    draw_field_line(engine, layer, "Date:", "", left, y, l_w);
    y -= 10.0;
    draw_sig_block(engine, layer, left + l_w / 2.0 + 6.0, y, xfer_sig_w, "", "Principal");
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2
// Left  half: Report on Learning Progress + grading legend
// Right half: Report on Learner's Observed Values + marking legend
// ─────────────────────────────────────────────────────────────────────────────
fn draw_page2(engine: &PdfEngine, layer: &PdfLayerReference, sf9: &Sf9Response) {
    let top = PAGE_H - MARGIN;
    let left = MARGIN;
    let col_split = MID - 2.0;
    let rx = col_split + 4.0;
    let r_w = PAGE_W - MARGIN - rx;

    // Left column
    engine.draw_text(
        layer,
        "REPORT ON LEARNING PROGRESS AND ACHIEVEMENT",
        7.5,
        Mm(left),
        Mm(top),
        true,
    );
    let table_bottom = draw_learning_progress_table(engine, layer, sf9, left, top - 5.0, col_split - left - 2.0);
    draw_grading_scale_legend(engine, layer, left, table_bottom - 6.0);

    // Right column
    engine.draw_text(
        layer,
        "REPORT ON LEARNER'S OBSERVED VALUES",
        7.5,
        Mm(rx),
        Mm(top),
        true,
    );
    let cv_bottom = draw_core_values_table(engine, layer, rx, top - 5.0, r_w);

    // Marking legend
    let mut my = cv_bottom - 7.0;
    engine.draw_text(layer, "Marking", 6.5, Mm(rx), Mm(my), true);
    engine.draw_text(layer, "Non-numerical Rating", 6.5, Mm(rx + 22.0), Mm(my), true);
    let marks = [
        ("AO", "Always Observed"),
        ("SO", "Sometimes Observed"),
        ("RO", "Rarely Observed"),
        ("NO", "Not Observed"),
    ];
    for (code, desc) in &marks {
        my -= 5.5;
        engine.draw_text(layer, code, 6.5, Mm(rx), Mm(my), false);
        engine.draw_text(layer, desc, 6.5, Mm(rx + 22.0), Mm(my), false);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Centered text with a full-width underline below it (school header fields)
fn draw_header_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    font_size: f32,
    center_x: f32,
    y: f32,
    line_w: f32,
) {
    let text_w = text.len() as f32 * font_size * 0.42;
    engine.draw_text(layer, text, font_size, Mm(center_x - text_w / 2.0), Mm(y), false);
    // Draw line using a very-thin rect (0.3mm tall) as a horizontal rule
    engine.draw_rect(
        layer,
        Mm(center_x - line_w / 2.0),
        Mm(y - 2.0),
        Mm(line_w),
        Mm(0.3),
        Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
        true,
    );
}

/// Label + value with an underline spanning the rest of the field width
fn draw_field_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    label: &str,
    value: &str,
    x: f32,
    y: f32,
    total_w: f32,
) {
    let label_w = label.len() as f32 * 7.0 * 0.42 + 2.0;
    engine.draw_text(layer, label, 7.0, Mm(x), Mm(y), true);
    let line_x = x + label_w;
    let line_w = total_w - label_w;
    if line_w > 0.0 {
        engine.draw_rect(
            layer,
            Mm(line_x),
            Mm(y - 2.0),
            Mm(line_w),
            Mm(0.3),
            Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
            true,
        );
    }
    if !value.is_empty() {
        engine.draw_text(layer, value, 7.0, Mm(line_x + 1.0), Mm(y), false);
    }
}

/// Name centered above line, title centered below
fn draw_sig_block(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    w: f32,
    name: &str,
    title: &str,
) {
    if !name.is_empty() {
        let name_w = name.len() as f32 * 7.0 * 0.42;
        engine.draw_text(layer, name, 7.0, Mm(x + (w - name_w).max(0.0) / 2.0), Mm(y), false);
    }
    // Underline
    engine.draw_rect(
        layer,
        Mm(x),
        Mm(y - 2.0),
        Mm(w),
        Mm(0.3),
        Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
        true,
    );
    let title_w = title.len() as f32 * 6.5 * 0.42;
    engine.draw_text(layer, title, 6.5, Mm(x + (w - title_w).max(0.0) / 2.0), Mm(y - 5.5), false);
}

fn draw_wrapped_text(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    x: f32,
    y: f32,
    max_width: f32,
    font_size: f32,
) {
    let chars_per_line = (max_width / (font_size * 0.42)) as usize;
    let mut current_y = y;
    let words: Vec<&str> = text.split_whitespace().collect();
    let mut line = String::new();

    for word in words {
        if !line.is_empty() && line.len() + word.len() + 1 > chars_per_line {
            engine.draw_text(layer, &line, font_size, Mm(x), Mm(current_y), false);
            current_y -= font_size * 0.5;
            line = word.to_string();
        } else {
            if !line.is_empty() {
                line.push(' ');
            }
            line.push_str(word);
        }
    }
    if !line.is_empty() {
        engine.draw_text(layer, &line, font_size, Mm(x), Mm(current_y), false);
    }
}

fn draw_attendance_table(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    total_w: f32,
) -> f32 {
    let months = [
        "JUN", "JUL", "AUG", "SEP", "OCT",
        "NOV", "DEC", "JAN", "FEB", "MAR", "APR", "TOT",
    ];
    let rows = ["School Days", "No. of Days Present", "No. of Days Absent"];

    let col0_w = 30.0;
    let col_w = (total_w - col0_w) / months.len() as f32;
    let hdr_h = 14.0;
    let row_h = 12.0;

    // Header row — grey background
    engine.draw_rect(layer, Mm(x), Mm(y - hdr_h), Mm(col0_w), Mm(hdr_h), Some(grey300()), true);
    let mut cx = x + col0_w;
    for m in &months {
        engine.draw_rect(layer, Mm(cx), Mm(y - hdr_h), Mm(col_w), Mm(hdr_h), Some(grey300()), true);
        engine.draw_text(layer, m, 5.0, Mm(cx + 1.0), Mm(y - hdr_h + 2.0), true);
        cx += col_w;
    }

    // Data rows
    let mut cy = y - hdr_h;
    for row_label in &rows {
        engine.draw_rect(layer, Mm(x), Mm(cy - row_h), Mm(col0_w), Mm(row_h), None, true);
        engine.draw_text(layer, row_label, 5.0, Mm(x + 1.0), Mm(cy - row_h + 2.0), false);
        cx = x + col0_w;
        for _ in &months {
            engine.draw_rect(layer, Mm(cx), Mm(cy - row_h), Mm(col_w), Mm(row_h), None, true);
            cx += col_w;
        }
        cy -= row_h;
    }

    cy
}

fn draw_learning_progress_table(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    sf9: &Sf9Response,
    x: f32,
    y: f32,
    avail_w: f32,
) -> f32 {
    // Proportional widths: [Learning Areas, Q1, Q2, Q3, Q4, Final Rating, Remarks]
    let ratios = [38.0_f32, 10.0, 10.0, 10.0, 10.0, 14.0, 14.0];
    let ratio_sum: f32 = ratios.iter().sum();
    let cw: Vec<f32> = ratios.iter().map(|r| r / ratio_sum * avail_w).collect();

    let sub_hdr_h = 6.0; // "Quarter" super-header row height
    let hdr_h = 8.0;     // main header row height
    let row_h = 9.0;
    let mut cy = y;

    // ── Row 0: "Quarter" spanning Q1-Q4 ──
    let q_x = x + cw[0];
    let q_w = cw[1] + cw[2] + cw[3] + cw[4];
    // Empty cells for Learning Areas, Final Rating, Remarks columns (top row)
    engine.draw_rect(layer, Mm(x), Mm(cy - sub_hdr_h), Mm(cw[0]), Mm(sub_hdr_h), Some(grey300()), true);
    engine.draw_rect(layer, Mm(q_x), Mm(cy - sub_hdr_h), Mm(q_w), Mm(sub_hdr_h), Some(grey300()), true);
    engine.draw_text(layer, "Quarter", 5.5, Mm(q_x + q_w / 2.0 - 5.5), Mm(cy - sub_hdr_h + 1.5), true);
    engine.draw_rect(layer, Mm(x + cw[0] + q_w), Mm(cy - sub_hdr_h), Mm(cw[5]), Mm(sub_hdr_h), Some(grey300()), true);
    engine.draw_rect(layer, Mm(x + cw[0] + q_w + cw[5]), Mm(cy - sub_hdr_h), Mm(cw[6]), Mm(sub_hdr_h), Some(grey300()), true);
    cy -= sub_hdr_h;

    // ── Row 1: column headers ──
    let col_labels = ["Learning Areas", "Q1", "Q2", "Q3", "Q4", "Final Rating", "Remarks"];
    let mut cx = x;
    for (i, label) in col_labels.iter().enumerate() {
        engine.draw_rect(layer, Mm(cx), Mm(cy - hdr_h), Mm(cw[i]), Mm(hdr_h), Some(grey300()), true);
        let tx = if i == 0 { cx + 1.5 } else { cx + cw[i] / 2.0 - label.len() as f32 * 1.1 };
        engine.draw_text(layer, label, 5.5, Mm(tx.max(cx + 0.5)), Mm(cy - hdr_h + 1.5), true);
        cx += cw[i];
    }
    cy -= hdr_h;

    // ── Subject rows ──
    for subject in &sf9.subjects {
        let pg: Vec<String> = subject
            .period_grades
            .iter()
            .map(|g| g.map(|v| v.to_string()).unwrap_or_default())
            .collect();
        let final_g = subject.final_grade.map(|v| v.to_string()).unwrap_or_default();
        let remark = subject
            .final_grade
            .map(|g| if g >= 75 { "Passed" } else { "Failed" })
            .unwrap_or_default();
        let cells = [
            subject.class_title.as_str(),
            pg.get(0).map(|s| s.as_str()).unwrap_or(""),
            pg.get(1).map(|s| s.as_str()).unwrap_or(""),
            pg.get(2).map(|s| s.as_str()).unwrap_or(""),
            pg.get(3).map(|s| s.as_str()).unwrap_or(""),
            final_g.as_str(),
            remark,
        ];
        cx = x;
        for (i, cell) in cells.iter().enumerate() {
            engine.draw_rect(layer, Mm(cx), Mm(cy - row_h), Mm(cw[i]), Mm(row_h), None, true);
            let tx = if i == 0 {
                cx + 1.5
            } else {
                cx + cw[i] / 2.0 - cell.len() as f32 * 1.1
            };
            engine.draw_text(layer, cell, 5.5, Mm(tx.max(cx + 0.5)), Mm(cy - row_h + 1.5), i == 5);
            cx += cw[i];
        }
        cy -= row_h;
    }

    // ── General Average row ──
    if let Some(ref ga) = sf9.general_average {
        let pg: Vec<String> = ga
            .period_grades
            .iter()
            .map(|g| g.map(|v| v.to_string()).unwrap_or_default())
            .collect();
        let final_g = ga.final_average.map(|v| v.to_string()).unwrap_or_default();
        let remark = ga
            .final_average
            .map(|g| if g >= 75 { "Passed" } else { "Failed" })
            .unwrap_or_default();
        let cells = [
            "General Average",
            pg.get(0).map(|s| s.as_str()).unwrap_or(""),
            pg.get(1).map(|s| s.as_str()).unwrap_or(""),
            pg.get(2).map(|s| s.as_str()).unwrap_or(""),
            pg.get(3).map(|s| s.as_str()).unwrap_or(""),
            final_g.as_str(),
            remark,
        ];
        cx = x;
        for (i, cell) in cells.iter().enumerate() {
            engine.draw_rect(layer, Mm(cx), Mm(cy - row_h), Mm(cw[i]), Mm(row_h), Some(grey300()), true);
            let tx = if i == 0 {
                cx + 1.5
            } else {
                cx + cw[i] / 2.0 - cell.len() as f32 * 1.1
            };
            engine.draw_text(layer, cell, 5.5, Mm(tx.max(cx + 0.5)), Mm(cy - row_h + 1.5), true);
            cx += cw[i];
        }
        cy -= row_h;
    }

    cy
}

fn draw_grading_scale_legend(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
) -> f32 {
    let data = [
        ("Outstanding", "90-100", "Passed"),
        ("Very Satisfactory", "85-89", "Passed"),
        ("Satisfactory", "80-84", "Passed"),
        ("Fairly Satisfactory", "75-79", "Passed"),
        ("Did Not Meet Expectations", "Below 75", "Failed"),
    ];
    let cw = [50.0_f32, 22.0, 20.0];
    let hdr_h = 8.0;
    let row_h = 7.0;
    let mut cy = y;

    let hdrs = ["Descriptors", "Grading Scale", "Remarks"];
    let mut cx = x;
    for (i, h) in hdrs.iter().enumerate() {
        engine.draw_rect(layer, Mm(cx), Mm(cy - hdr_h), Mm(cw[i]), Mm(hdr_h), Some(grey300()), true);
        engine.draw_text(layer, h, 5.5, Mm(cx + 1.0), Mm(cy - hdr_h + 1.5), true);
        cx += cw[i];
    }
    cy -= hdr_h;

    for (desc, scale, rem) in &data {
        cx = x;
        for (i, cell) in [*desc, *scale, *rem].iter().enumerate() {
            engine.draw_rect(layer, Mm(cx), Mm(cy - row_h), Mm(cw[i]), Mm(row_h), None, true);
            engine.draw_text(layer, cell, 5.5, Mm(cx + 1.0), Mm(cy - row_h + 1.5), false);
            cx += cw[i];
        }
        cy -= row_h;
    }
    cy
}

fn draw_core_values_table(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    avail_w: f32,
) -> f32 {
    let core_values: &[(&str, &[&str])] = &[
        (
            "1. Maka-Diyos",
            &[
                "Expresses one's spiritual beliefs while respecting the spiritual beliefs of others",
                "Shows adherence to ethical principles by upholding truth in all circumstances",
            ],
        ),
        (
            "2. Makatao",
            &[
                "Demonstrates pride in being a Filipino; exercises the right and responsibilities of a Filipino citizen",
                "Listens attentively and speaks to communicate effectively",
            ],
        ),
        (
            "3. Maka-Kalikasan",
            &[
                "Cares for the environment and utilizes resources wisely, judiciously, and economically",
                "Demonstrates resourcefulness, creativity, and innovation in dealing with everyday problems",
            ],
        ),
        (
            "4. Maka-bansa",
            &[
                "Demonstrates pride in being a Filipino; exercises the rights and responsibilities of a Filipino citizen",
                "Demonstrates appropriate behavior in carrying out activities in the school, community, and country",
            ],
        ),
    ];

    // [Core Values, Behavior Statements, Q1, Q2, Q3, Q4]
    let ratios = [20.0_f32, 50.0, 7.5, 7.5, 7.5, 7.5];
    let ratio_sum: f32 = ratios.iter().sum();
    let cw: Vec<f32> = ratios.iter().map(|r| r / ratio_sum * avail_w).collect();

    let sub_hdr_h = 6.0;
    let hdr_h = 8.0;
    let row_h = 14.0; // tall enough for 3 lines of behavior text at 4.5pt
    let mut cy = y;

    // ── "Quarter" super-header spanning Q1-Q4 ──
    let q_x = x + cw[0] + cw[1];
    let q_w = cw[2] + cw[3] + cw[4] + cw[5];
    engine.draw_rect(layer, Mm(x), Mm(cy - sub_hdr_h), Mm(cw[0]), Mm(sub_hdr_h), Some(grey300()), true);
    engine.draw_rect(layer, Mm(x + cw[0]), Mm(cy - sub_hdr_h), Mm(cw[1]), Mm(sub_hdr_h), Some(grey300()), true);
    engine.draw_rect(layer, Mm(q_x), Mm(cy - sub_hdr_h), Mm(q_w), Mm(sub_hdr_h), Some(grey300()), true);
    engine.draw_text(layer, "Quarter", 5.5, Mm(q_x + q_w / 2.0 - 5.5), Mm(cy - sub_hdr_h + 1.5), true);
    cy -= sub_hdr_h;

    // ── Column header row ──
    let col_labels = ["Core Values", "Behavior Statements", "1", "2", "3", "4"];
    let mut cx = x;
    for (i, label) in col_labels.iter().enumerate() {
        engine.draw_rect(layer, Mm(cx), Mm(cy - hdr_h), Mm(cw[i]), Mm(hdr_h), Some(grey300()), true);
        let tx = if i <= 1 {
            cx + 1.5
        } else {
            cx + cw[i] / 2.0 - label.len() as f32 * 1.1
        };
        engine.draw_text(layer, label, 5.5, Mm(tx.max(cx + 0.5)), Mm(cy - hdr_h + 2.0), true);
        cx += cw[i];
    }
    cy -= hdr_h;

    // ── Core value rows ──
    for (cv_name, statements) in core_values {
        let n = statements.len();
        let cv_total_h = row_h * n as f32;

        // Core value name cell spans all its statement rows
        engine.draw_rect(layer, Mm(x), Mm(cy - cv_total_h), Mm(cw[0]), Mm(cv_total_h), None, true);
        engine.draw_text(layer, cv_name, 5.5, Mm(x + 1.0), Mm(cy - row_h + 2.5), true);

        for (i, stmt) in statements.iter().enumerate() {
            let row_top = cy - row_h * i as f32;
            let row_bottom = row_top - row_h;

            // Behavior statement cell
            engine.draw_rect(layer, Mm(x + cw[0]), Mm(row_bottom), Mm(cw[1]), Mm(row_h), None, true);
            // Draw behavior text with wrapping inside the cell
            draw_wrapped_text(
                engine,
                layer,
                stmt,
                x + cw[0] + 1.0,
                row_top - 2.5,
                cw[1] - 2.0,
                4.5,
            );

            // Q1-Q4 cells
            let mut qx = x + cw[0] + cw[1];
            for j in 2..=5 {
                engine.draw_rect(layer, Mm(qx), Mm(row_bottom), Mm(cw[j]), Mm(row_h), None, true);
                qx += cw[j];
            }
        }
        cy -= cv_total_h;
    }

    cy
}