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

const BEHAVIOR_TEXT_PADDING_X: f32 = 1.5;
const BEHAVIOR_TEXT_PADDING_TOP: f32 = 4.0;
const BEHAVIOR_TEXT_PADDING_RIGHT: f32 = -2.0;
const BEHAVIOR_FONT_SIZE: f32 = 8.0;
const HEADER_META_FONT_SIZE: f32 = 7.7; // 30% smaller than 11pt
const HEADER_TEXT_OFFSET: f32 = 25.0;
const TITLE_TEXT_OFFSET: f32 = 23.0;
const HEADER_META_LINE_GAP: f32 = 4.0;
const HEADER_META_CHAR_FACTOR: f32 = 0.18;
const HEADER_META_LABEL_PADDING: f32 = 0.1;
const CORE_VALUES_ROW_HEIGHT: f32 = 12.0;
const CORE_VALUE_LABEL_TOP_PADDING: f32 = 6.0;

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

    let engine = PdfEngine::new_with_size("SF9", Mm(PAGE_W), Mm(PAGE_H))
        .map_err(|e| AppError::InternalServerError(format!("PDF init: {}", e)))?;

    let seal_bytes = load_asset("deped_seal.png");

    let seal_img = seal_bytes.as_ref().and_then(|b| PdfEngine::load_png(b).ok());

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
// Left  half: Attendance Record + Parent/Guardian's Signature
// Right half: SF9 label, DepEd header + seal, student info, Dear Parent,
//             Certificate of Transfer, Cancellation
// ─────────────────────────────────────────────────────────────────────────────
fn draw_page1(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    sf9: &Sf9Response,
    school_name: &str,
    region: &str,
    division: &str,
    district: &str,
    _school_id: &str,
    school_year: &str,
    school_head_name: &str,
    _school_head_position: &str,
    seal: Option<Image>,
) {
    let top = PAGE_H - MARGIN; // ~203.9
    let left = MARGIN;         // 12.0
    let right = PAGE_W - MARGIN; // ~267.4
    let col_split = MID - 2.0; // ~137.7
    let l_w = col_split - left; // left column width
    let rx = col_split + 4.0;  // right column left edge
    let inner_left: f32 = rx + 14.0;
    let inner_right = right - 12.0;
    let inner_width = inner_right - inner_left;
    let header_center = inner_left + inner_width / 2.0;

    // ── RIGHT HALF ──────────────────────────────────────────────────────────

    if let Some(img) = seal {
        let seal_x = inner_left - 6.0;
        let seal_y = top - 18.0;
        img.add_to_layer(
            layer.clone(),
            ImageTransform {
                translate_x: Some(Mm(seal_x)),
                translate_y: Some(Mm(seal_y)),
                scale_x: Some(0.18),
                scale_y: Some(0.18),
                ..Default::default()
            },
        );
    }

    // DepEd text — centered in right column
    let mut header_y = top - 6.0;
    let line1 = "Republic of the Philippines";
    let line1_w = line1.len() as f32 * 11.0 * 0.42;
    engine.draw_text(
        layer,
        line1,
        11.0,
        Mm(header_center + HEADER_TEXT_OFFSET + 10.0 - line1_w / 2.0),
        Mm(header_y),
        false,
    );
    header_y -= 6.0;
    let line2 = "DEPARTMENT OF EDUCATION";
    let line2_w = line2.len() as f32 * 12.0 * 0.42;
    engine.draw_text(
        layer,
        line2,
        12.0,
        Mm(header_center + HEADER_TEXT_OFFSET - line2_w / 2.0),
        Mm(header_y),
        true,
    );

    header_y -= 8.0;
    let indent = inner_left + 12.0;
    let meta_line_w = inner_width;
    draw_labeled_header_line(engine, layer, "Region", region, indent, header_y, meta_line_w);
    header_y -= HEADER_META_LINE_GAP;
    draw_labeled_header_line(engine, layer, "Division", division, indent, header_y, meta_line_w);
    if !district.is_empty() {
        header_y -= HEADER_META_LINE_GAP;
        draw_labeled_header_line(engine, layer, "District", district, indent, header_y, meta_line_w);
    }
    header_y -= HEADER_META_LINE_GAP;
    draw_labeled_header_line(engine, layer, "School", school_name, indent, header_y, meta_line_w);

    // "LEARNER'S PROGRESS REPORT CARD"
    header_y -= 10.0;
    let title = "LEARNER'S PROGRESS REPORT CARD";
    let title_size = 11.7; 
    let title_w = title.len() as f32 * title_size * 0.42;
    engine.draw_text(
        layer,
        title,
        title_size,
        Mm(header_center + TITLE_TEXT_OFFSET + 8.0 - title_w / 2.0),
        Mm(header_y),
        true,
    );
    header_y -= 4.0;
    let sy_text = format!("School Year  {}", school_year);
    let sy_w = sy_text.len() as f32 * 11.0 * 0.42;
    engine.draw_text(layer, &sy_text, 11.0, Mm(header_center + 18.0 - sy_w / 2.0), Mm(header_y), false);

    // Student info fields
    header_y -= 9.0;
    draw_field_line(engine, layer, "Name:", &sf9.student_name, inner_left, header_y, inner_width);

    header_y -= 9.0;
    let half_w = inner_width / 2.0 - 8.0;
    draw_field_line(
        engine,
        layer,
        "Age:",
        &sf9.age.map(|a| a.to_string()).unwrap_or_default(),
        inner_left,
        header_y,
        half_w,
    );
    draw_field_line(
        engine,
        layer,
        "Sex:",
        sf9.sex.as_deref().unwrap_or(""),
        inner_left + half_w + 16.0,
        header_y,
        half_w,
    );

    header_y -= 9.0;
    draw_field_line(
        engine,
        layer,
        "Grade:",
        sf9.grade_level.as_deref().unwrap_or(""),
        inner_left,
        header_y,
        half_w,
    );
    draw_field_line(
        engine,
        layer,
        "Section:",
        sf9.section.as_deref().unwrap_or(""),
        inner_left + half_w + 16.0,
        header_y,
        half_w,
    );

    header_y -= 9.0;
    header_y = draw_lrn_boxes(
        engine,
        layer,
        inner_left,
        header_y,
        inner_width,
        "Learner's Reference Number:",
        sf9.lrn.as_deref().unwrap_or(""),
    );

    // Dear Parent
    header_y -= 4.0;
    engine.draw_text(layer, "Dear Parent,", 11.0, Mm(inner_left), Mm(header_y), false);
    header_y -= 8.0;
    let parent_letter = "This report card shows the ability and the progress your child has made in the different learning areas as well as his/her progress in core values. The school welcomes you should you desire to know more about your child's progress.";
    header_y = draw_wrapped_text(engine, layer, parent_letter, inner_left, header_y, inner_width - 10.0, 10.0) - 2.0;

    // Signatures (principal left, teacher right)
    header_y -= 8.0;
    let sig_w = inner_width / 2.0 - 10.0;
    draw_sig_block(engine, layer, inner_left, header_y, sig_w, school_head_name, "Head Teacher/ Principal");
    draw_sig_block(
        engine,
        layer,
        inner_left + sig_w + 20.0,
        header_y,
        sig_w,
        sf9.teacher_name.as_deref().unwrap_or(""),
        "Teacher",
    );
    header_y -= 20.0;

    // Certificate of Transfer
    header_y -= 14.0;
    engine.draw_text(layer, "Certificate of Transfer", 12.0, Mm(header_center - 30.0), Mm(header_y), true);
    header_y -= 8.0;
    draw_field_line(engine, layer, "Admitted to Grade", "", inner_left, header_y, 45.0);
    draw_field_line(engine, layer, "Section", "", inner_left + 48.0, header_y, 30.0);
    draw_field_line(engine, layer, "Room", "", inner_left + 82.0, header_y, inner_width - 82.0);
    header_y -= 8.0;
    draw_field_line(engine, layer, "Eligible for Admission to Grade", "", inner_left, header_y, inner_width);
    header_y -= 8.0;
    engine.draw_text(layer, "Approved:", 11.0, Mm(inner_left), Mm(header_y), false);
    header_y -= 10.0;
    let xfer_sig_w = inner_width / 2.0 - 6.0;
    draw_sig_block(engine, layer, inner_left, header_y, xfer_sig_w, "", "Head Teacher/ Principal");
    draw_sig_block(engine, layer, inner_left + xfer_sig_w + 12.0, header_y, xfer_sig_w, "", "Teacher");

    // Cancellation of Eligibility to Transfer
    header_y -= 14.0;
    engine.draw_text(layer, "Cancellation of Eligibility to Transfer", 11.0, Mm(inner_left + 8.0), Mm(header_y), false);
    header_y -= 8.0;
    draw_field_line(engine, layer, "Admitted in", "", inner_left, header_y, inner_width);
    header_y -= 8.0;
    draw_field_line(engine, layer, "Date:", "", inner_left, header_y, inner_width / 2.0);
    header_y -= 12.0;
    draw_sig_block(engine, layer, inner_left + inner_width / 2.0, header_y, xfer_sig_w, "", "Principal");

    // ── LEFT HALF ───────────────────────────────────────────────────────────
    let mut y = top;

    // Attendance Record
    engine.draw_text(layer, "Attendance Record", 13.0, Mm(left + l_w / 2.0 - 25.0), Mm(y), true);
    y -= 8.0;
    let att_bottom = draw_attendance_table(engine, layer, left, y, l_w, sf9);
    y = att_bottom - 14.0;

    // PARENT/GUARDIAN'S SIGNATURE
    engine.draw_text(layer, "PARENT/GUARDIAN'S SIGNATURE", 12.0, Mm(left + 5.0), Mm(y), true);
    y -= 12.0;

    let terms = ["Term 1", "Term 2", "Term 3"];
    for term in &terms {
        engine.draw_text(layer, term, 11.0, Mm(left + 5.0), Mm(y), false);
        // Signature line
        engine.draw_rect(
            layer,
            Mm(left + 35.0),
            Mm(y - 2.0),
            Mm(l_w - 40.0),
            Mm(0.3),
            Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
            true,
        );
        y -= 12.0;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2
// Left  half: Report on Learning Progress + grading legend (plain text)
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
        11.0,
        Mm(left),
        Mm(top),
        true,
    );
    let table_bottom = draw_learning_progress_table(engine, layer, sf9, left, top - 8.0, col_split - left - 2.0);
    draw_grading_scale_legend(engine, layer, left, table_bottom - 10.0);

    // Right column
    engine.draw_text(
        layer,
        "REPORT ON LEARNER'S OBSERVED VALUES",
        11.0,
        Mm(rx),
        Mm(top),
        true,
    );
    let cv_bottom = draw_core_values_table(engine, layer, rx, top - 8.0, r_w);

    // Marking legend
    let mut my = cv_bottom - 12.0;
    engine.draw_text(layer, "Marking", 11.0, Mm(rx), Mm(my), true);
    engine.draw_text(layer, "Non-numerical Rating", 11.0, Mm(rx + 40.0), Mm(my), true);
    let marks = [
        ("AO", "Always Observed"),
        ("SO", "Sometimes Observed"),
        ("RO", "Rarely Observed"),
        ("NO", "Not Observed"),
    ];
    for (code, desc) in &marks {
        my -= 8.0;
        engine.draw_text(layer, code, 11.0, Mm(rx + 5.0), Mm(my), false);
        engine.draw_text(layer, desc, 11.0, Mm(rx + 40.0), Mm(my), false);
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
        Mm(y - 3.0),
        Mm(line_w),
        Mm(0.3),
        Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
        true,
    );
}

/// Left-aligned text with a full-width underline below it
fn draw_left_header_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    font_size: f32,
    x: f32,
    y: f32,
    line_w: f32,
) {
    engine.draw_text(layer, text, font_size, Mm(x), Mm(y), false);
    engine.draw_rect(
        layer,
        Mm(x),
        Mm(y - 3.0),
        Mm(line_w),
        Mm(0.3),
        Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
        true,
    );
}

/// Label (e.g., "Region:") followed by underlined value space, smaller font
fn draw_labeled_header_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    label: &str,
    value: &str,
    x: f32,
    y: f32,
    total_w: f32,
) {
    let label_text = format!("{}:", label);
    let label_w = label_text.len() as f32 * HEADER_META_FONT_SIZE * HEADER_META_CHAR_FACTOR + HEADER_META_LABEL_PADDING;
    engine.draw_text(layer, &label_text, HEADER_META_FONT_SIZE, Mm(x), Mm(y), true);
    let value_x = x + label_w;
    let value_w = (total_w - label_w).max(10.0);
    engine.draw_rect(
        layer,
        Mm(value_x),
        Mm(y - 1.0),
        Mm(value_w),
        Mm(0.1),
        Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
        true,
    );
    if !value.is_empty() {
        engine.draw_text(layer, value, HEADER_META_FONT_SIZE, Mm(value_x + 1.0), Mm(y), false);
    }
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
    let label_w = label.len() as f32 * 11.0 * 0.42 + 2.0;
    engine.draw_text(layer, label, 11.0, Mm(x), Mm(y), true);
    let line_x = x + label_w;
    let line_w = total_w - label_w;
    if line_w > 0.0 {
        engine.draw_rect(
            layer,
            Mm(line_x),
            Mm(y - 3.0),
            Mm(line_w),
            Mm(0.3),
            Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
            true,
        );
    }
    if !value.is_empty() {
        engine.draw_text(layer, value, 11.0, Mm(line_x + 1.0), Mm(y), false);
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
        let name_w = name.len() as f32 * 11.0 * 0.42;
        engine.draw_text(layer, name, 11.0, Mm(x + (w - name_w).max(0.0) / 2.0), Mm(y), false);
    }
    // Underline
    engine.draw_rect(
        layer,
        Mm(x),
        Mm(y - 3.0),
        Mm(w),
        Mm(0.3),
        Some(Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))),
        true,
    );
    let title_w = title.len() as f32 * 10.0 * 0.42;
    engine.draw_text(layer, title, 10.0, Mm(x + (w - title_w).max(0.0) / 2.0), Mm(y - 6.0), false);
}

fn draw_wrapped_text(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    x: f32,
    y: f32,
    max_width: f32,
    font_size: f32,
) -> f32 {
    let chars_per_line = (max_width / (font_size * 0.17)).max(1.0) as usize;
    let mut current_y = y;
    let line_height = font_size * 0.45;
    let words: Vec<&str> = text.split_whitespace().collect();
    let mut line = String::new();

    for word in words {
        if !line.is_empty() && line.len() + word.len() + 1 > chars_per_line {
            engine.draw_text(layer, &line, font_size, Mm(x), Mm(current_y), false);
            current_y -= line_height;
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
        current_y -= line_height;
    }
    current_y
}

fn draw_lrn_boxes(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    total_w: f32,
    label: &str,
    lrn: &str,
) -> f32 {
    engine.draw_text(layer, label, 11.0, Mm(x), Mm(y), true);
    let boxes = 12usize;
    let box_size = 7.0;
    let box_gap = 1.4;
    let boxes_width = boxes as f32 * box_size + (boxes - 1) as f32 * box_gap;
    let start_x = x + total_w - boxes_width;
    let box_y = y - 8.5;
    let chars: Vec<char> = lrn.chars().collect();
    for i in 0..boxes {
        let bx = start_x + i as f32 * (box_size + box_gap);
        engine.draw_rect(layer, Mm(bx), Mm(box_y), Mm(box_size), Mm(7.5), None, true);
        if let Some(ch) = chars.get(i) {
            engine.draw_text(layer, &ch.to_string(), 9.0, Mm(bx + 2.0), Mm(box_y + 2.5), false);
        }
    }
    box_y - 2.5
}

fn draw_attendance_table(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    origin_x: f32,
    origin_y: f32,
    total_width: f32,
    sf9: &Sf9Response,
) -> f32 {
    let month_names = [
        ("Jun", "June"), ("Jul", "July"), ("Aug", "August"), ("Sept", "September"),
        ("Oct", "October"), ("Nov", "November"), ("Dec", "December"),
        ("Jan", "January"), ("Feb", "February"), ("Mar", "March"), ("Apr", "April"),
    ];
    let total_label = "Total";
    let rows = ["No. of\nSchool\nDays", "No. of\nDays\nPresent", "No. of\nTimes\nAbsent"];
    let row_labels_single = ["No. of School Days", "No. of Days Present", "No. of Times Absent"];

    let label_column_width = 22.0;
    let data_column_width = (total_width - label_column_width) / (month_names.len() as f32 + 1.0);
    let header_height = 10.0;
    let row_height = 14.0;

    // Build a map month -> record for quick lookup (full month names as keys)
    let att_map: std::collections::HashMap<&str, &crate::modules::grading::schema::Sf9AttendanceRecord> =
        sf9.attendance.iter().map(|r| (r.month.as_str(), r)).collect();

    // Header row
    engine.draw_rect(
        layer,
        Mm(origin_x),
        Mm(origin_y - header_height),
        Mm(label_column_width),
        Mm(header_height),
        None,
        true,
    );
    let mut current_x = origin_x + label_column_width;
    for (abbr, _) in &month_names {
        engine.draw_rect(
            layer,
            Mm(current_x),
            Mm(origin_y - header_height),
            Mm(data_column_width),
            Mm(header_height),
            None,
            true,
        );
        engine.draw_text(layer, abbr, 8.0, Mm(current_x + 1.0), Mm(origin_y - header_height + 3.0), false);
        current_x += data_column_width;
    }
    // Total column header
    engine.draw_rect(
        layer,
        Mm(current_x),
        Mm(origin_y - header_height),
        Mm(data_column_width),
        Mm(header_height),
        None,
        true,
    );
    engine.draw_text(layer, total_label, 8.0, Mm(current_x + 1.0), Mm(origin_y - header_height + 3.0), false);

    // Data rows
    let mut current_y = origin_y - header_height;
    for (idx, _row_label) in rows.iter().enumerate() {
        engine.draw_rect(
            layer,
            Mm(origin_x),
            Mm(current_y - row_height),
            Mm(label_column_width),
            Mm(row_height),
            None,
            true,
        );
        // Draw multi-line label
        let label_lines: Vec<&str> = rows[idx].split('\n').collect();
        for (li, line) in label_lines.iter().enumerate() {
            engine.draw_text(
                layer,
                line,
                7.0,
                Mm(origin_x + 1.0),
                Mm(current_y - 4.0 - li as f32 * 3.5),
                false,
            );
        }
        let _ = row_labels_single[idx]; // keep for reference
        current_x = origin_x + label_column_width;

        // Compute totals
        let mut total = 0i32;
        for (_, full) in &month_names {
            if let Some(rec) = att_map.get(full) {
                let val = match idx {
                    0 => rec.school_days,
                    1 => rec.days_present,
                    2 => (rec.school_days - rec.days_present).max(0),
                    _ => 0,
                };
                total += val;
            }
        }

        for (_, full) in &month_names {
            let text = if let Some(rec) = att_map.get(full) {
                match idx {
                    0 => rec.school_days.to_string(),
                    1 => rec.days_present.to_string(),
                    2 => {
                        let absent = rec.school_days - rec.days_present;
                        if absent > 0 { absent.to_string() } else { String::new() }
                    }
                    _ => String::new(),
                }
            } else {
                String::new()
            };

            engine.draw_rect(
                layer,
                Mm(current_x),
                Mm(current_y - row_height),
                Mm(data_column_width),
                Mm(row_height),
                None,
                true,
            );
            if !text.is_empty() {
                let tx = current_x + data_column_width / 2.0 - text.len() as f32 * 1.8;
                engine.draw_text(layer, &text, 8.0, Mm(tx.max(current_x + 0.5)), Mm(current_y - row_height + 3.0), false);
            }
            current_x += data_column_width;
        }
        // Total column
        engine.draw_rect(
            layer,
            Mm(current_x),
            Mm(current_y - row_height),
            Mm(data_column_width),
            Mm(row_height),
            None,
            true,
        );
        if total > 0 {
            let tx = current_x + data_column_width / 2.0 - total.to_string().len() as f32 * 1.8;
            engine.draw_text(layer, &total.to_string(), 8.0, Mm(tx.max(current_x + 0.5)), Mm(current_y - row_height + 3.0), true);
        }

        current_y -= row_height;
    }

    current_y
}

fn draw_learning_progress_table(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    sf9: &Sf9Response,
    x: f32,
    y: f32,
    avail_w: f32,
) -> f32 {
    // Proportional widths: [Learning Areas, T1, T2, T3, Final Rating, Remarks]
    let ratios = [40.0_f32, 10.0, 10.0, 10.0, 15.0, 15.0];
    let ratio_sum: f32 = ratios.iter().sum();
    let column_widths: Vec<f32> = ratios.iter().map(|ratio| ratio / ratio_sum * avail_w).collect();

    let term_header_height = 10.0; // "Term" super-header row height
    let header_row_height = 12.0;  // main header row height
    let row_height = 12.0;
    let mut current_y = y;

    // ── Row 0: "Term" spanning T1-T3 ──
    let term_section_x = x + column_widths[0];
    let term_section_width = column_widths[1] + column_widths[2] + column_widths[3];
    engine.draw_rect(
        layer,
        Mm(x),
        Mm(current_y - term_header_height),
        Mm(column_widths[0]),
        Mm(term_header_height),
        Some(grey300()),
        true,
    );
    engine.draw_rect(
        layer,
        Mm(term_section_x),
        Mm(current_y - term_header_height),
        Mm(term_section_width),
        Mm(term_header_height),
        Some(grey300()),
        true,
    );
    engine.draw_text(
        layer,
        "Term",
        9.0,
        Mm(term_section_x + term_section_width / 2.0 - 9.0),
        Mm(current_y - term_header_height + 2.5),
        true,
    );
    engine.draw_rect(
        layer,
        Mm(x + column_widths[0] + term_section_width),
        Mm(current_y - term_header_height),
        Mm(column_widths[4]),
        Mm(term_header_height),
        Some(grey300()),
        true,
    );
    engine.draw_rect(
        layer,
        Mm(x + column_widths[0] + term_section_width + column_widths[4]),
        Mm(current_y - term_header_height),
        Mm(column_widths[5]),
        Mm(term_header_height),
        Some(grey300()),
        true,
    );
    current_y -= term_header_height;

    // ── Row 1: column headers ──
    let column_labels = ["Learning Areas", "T1", "T2", "T3", "Final\nRating", "Remarks"];
    let mut current_x = x;
    let header_line_spacing = 5.0;
    for (i, label) in column_labels.iter().enumerate() {
        engine.draw_rect(
            layer,
            Mm(current_x),
            Mm(current_y - header_row_height),
            Mm(column_widths[i]),
            Mm(header_row_height),
            Some(grey300()),
            true,
        );
        let lines: Vec<&str> = label.split('\n').collect();
        let total_block_height = (lines.len() as f32 - 1.0) * header_line_spacing;
        let mut line_y = current_y - header_row_height / 2.0 + total_block_height / 2.0;
        for line in lines {
            let text_x = if i == 0 {
                current_x + 2.0
            } else {
                current_x + column_widths[i] / 2.0 - line.len() as f32 * 1.8
            };
            engine.draw_text(
                layer,
                line,
                9.0,
                Mm(text_x.max(current_x + 0.5)),
                Mm(line_y),
                true,
            );
            line_y -= header_line_spacing;
        }
        current_x += column_widths[i];
    }
    current_y -= header_row_height;

    // ── Subject rows ──
    for subject in &sf9.subjects {
        let pg: Vec<String> = subject
            .term_grades
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
            final_g.as_str(),
            remark,
        ];
        current_x = x;
        for (i, cell) in cells.iter().enumerate() {
            engine.draw_rect(layer, Mm(current_x), Mm(current_y - row_height), Mm(column_widths[i]), Mm(row_height), None, true);
            let text_x = if i == 0 {
                current_x + 2.0
            } else {
                current_x + column_widths[i] / 2.0 - cell.len() as f32 * 1.8
            };
            engine.draw_text(layer, cell, 9.0, Mm(text_x.max(current_x + 0.5)), Mm(current_y - row_height + 3.0), i == 5);
            current_x += column_widths[i];
        }
        current_y -= row_height;
    }

    // ── General Average row ──
    if let Some(ref ga) = sf9.general_average {
        let pg: Vec<String> = ga
            .term_grades
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
            final_g.as_str(),
            remark,
        ];
        current_x = x;
        for (i, cell) in cells.iter().enumerate() {
            engine.draw_rect(
                layer,
                Mm(current_x),
                Mm(current_y - row_height),
                Mm(column_widths[i]),
                Mm(row_height),
                Some(grey300()),
                true,
            );
            let text_x = if i == 0 {
                current_x + 2.0
            } else {
                current_x + column_widths[i] / 2.0 - cell.len() as f32 * 1.8
            };
            engine.draw_text(layer, cell, 9.0, Mm(text_x.max(current_x + 0.5)), Mm(current_y - row_height + 3.0), true);
            current_x += column_widths[i];
        }
        current_y -= row_height;
    }

    current_y
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

    let descriptor_x = x;
    let scale_x = x + 50.0;
    let remarks_x = x + 80.0;
    let row_height = 8.0;
    let mut current_y = y;

    // Headers (plain text, bold)
    engine.draw_text(layer, "Descriptors", 10.0, Mm(descriptor_x), Mm(current_y), true);
    engine.draw_text(layer, "Grading Scale", 10.0, Mm(scale_x), Mm(current_y), true);
    engine.draw_text(layer, "Remarks", 10.0, Mm(remarks_x), Mm(current_y), true);
    current_y -= 4.0;

    // Data rows (plain text, no table borders)
    for (desc, scale, rem) in &data {
        current_y -= row_height;
        engine.draw_text(layer, desc, 10.0, Mm(descriptor_x), Mm(current_y), false);
        engine.draw_text(layer, scale, 10.0, Mm(scale_x), Mm(current_y), false);
        engine.draw_text(layer, rem, 10.0, Mm(remarks_x), Mm(current_y), false);
    }
    current_y
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
                "Shows adherence to ethical principles by upholding truth",
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
            "3. Maka-\nkalikasan",
            &[
                "Cares for the environment and utilizes resources wisely, judiciously, and economically",
                "Demonstrates resourcefulness, creativity, and innovation in dealing with everyday problems",
            ],
        ),
        (
            "4. Makabansa",
            &[
                "Demonstrates pride in being a Filipino; exercises the rights and responsibilities of a Filipino citizen",
                "Demonstrates appropriate behavior in carrying out activities in the school, community, and country",
            ],
        ),
    ];

    // [Core Values, Behavior Statements, T1, T2, T3] — only 3 terms
    let ratios = [18.0_f32, 60.0, 7.0, 7.0, 8.0];
    let ratio_sum: f32 = ratios.iter().sum();
    let column_widths: Vec<f32> = ratios.iter().map(|ratio| ratio / ratio_sum * avail_w).collect();

    let term_header_height = 10.0;
    let header_row_height = 12.0;
    let mut current_y = y;

    // ── "Term" super-header spanning T1-T3 ──
    let term_start_x = x + column_widths[0] + column_widths[1];
    let term_section_width = column_widths[2] + column_widths[3] + column_widths[4];
    engine.draw_rect(layer, Mm(x), Mm(current_y - term_header_height), Mm(column_widths[0]), Mm(term_header_height), Some(grey300()), true);
    engine.draw_rect(layer, Mm(x + column_widths[0]), Mm(current_y - term_header_height), Mm(column_widths[1]), Mm(term_header_height), Some(grey300()), true);
    engine.draw_rect(layer, Mm(term_start_x), Mm(current_y - term_header_height), Mm(term_section_width), Mm(term_header_height), Some(grey300()), true);
    engine.draw_text(layer, "Term", 9.0, Mm(term_start_x + term_section_width / 2.0 - 9.0), Mm(current_y - term_header_height + 2.5), true);
    current_y -= term_header_height;

    // ── Column header row ──
    let column_labels = ["Core Values", "Behavior Statements", "T1", "T2", "T3"];
    let mut current_x = x;
    for (i, label) in column_labels.iter().enumerate() {
        engine.draw_rect(
            layer,
            Mm(current_x),
            Mm(current_y - header_row_height),
            Mm(column_widths[i]),
            Mm(header_row_height),
            Some(grey300()),
            true,
        );
        let text_x = if i <= 1 {
            current_x + 2.0
        } else {
            current_x + column_widths[i] / 2.0 - label.len() as f32 * 1.8
        };
        engine.draw_text(layer, label, 9.0, Mm(text_x.max(current_x + 0.5)), Mm(current_y - header_row_height + 3.0), true);
        current_x += column_widths[i];
    }
    current_y -= header_row_height;

    // ── Core value rows ──
    for (core_label, statements) in core_values {
        let statement_count = statements.len();
        let core_value_height = CORE_VALUES_ROW_HEIGHT * statement_count as f32;

        // Core value name cell spans all its statement rows
        engine.draw_rect(
            layer,
            Mm(x),
            Mm(current_y - core_value_height),
            Mm(column_widths[0]),
            Mm(core_value_height),
            None,
            true,
        );
        let label_lines: Vec<&str> = core_label.split('\n').collect();
        let mut label_y = current_y - CORE_VALUE_LABEL_TOP_PADDING;
        for line in label_lines {
            engine.draw_text(layer, line, 9.0, Mm(x + 1.5), Mm(label_y), false);
            label_y -= 4.5;
        }

        for (index, statement) in statements.iter().enumerate() {
            let row_top = current_y - CORE_VALUES_ROW_HEIGHT * index as f32;
            let row_bottom = row_top - CORE_VALUES_ROW_HEIGHT;

            // Behavior statement cell
            engine.draw_rect(
                layer,
                Mm(x + column_widths[0]),
                Mm(row_bottom),
                Mm(column_widths[1]),
                Mm(CORE_VALUES_ROW_HEIGHT),
                None,
                true,
            );
            draw_wrapped_text(
                engine,
                layer,
                statement,
                x + column_widths[0] + BEHAVIOR_TEXT_PADDING_X,
                row_top - BEHAVIOR_TEXT_PADDING_TOP,
                column_widths[1] - BEHAVIOR_TEXT_PADDING_RIGHT,
                BEHAVIOR_FONT_SIZE,
            );

            // Term columns
            let mut term_x = x + column_widths[0] + column_widths[1];
            for column_index in 2..=4 {
                engine.draw_rect(
                    layer,
                    Mm(term_x),
                    Mm(row_bottom),
                    Mm(column_widths[column_index]),
                    Mm(CORE_VALUES_ROW_HEIGHT),
                    None,
                    true,
                );
                term_x += column_widths[column_index];
            }
        }
        current_y -= core_value_height;
    }

    current_y
}