use std::sync::Arc;

use printpdf::*;
use uuid::Uuid;

use crate::modules::document_export::helpers::pdf_engine::{PdfEngine, grey300};
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::grading::schema::Sf9Response;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;
use crate::utils::{AppError, AppResult};

const PAGE_W: f32 = 210.0;
const PAGE_H: f32 = 297.0;
const MARGIN: f32 = 20.0;

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

    let engine = PdfEngine::new("SF9")
        .map_err(|e| AppError::InternalServerError(format!("PDF init: {}", e)))?;

    let seal_bytes = load_asset("deped_seal.png");
    let logo_bytes = load_asset("deped_logo.png");

    let seal_img = seal_bytes.as_ref().and_then(|b| PdfEngine::load_png(b).ok());
    let logo_img = logo_bytes.as_ref().and_then(|b| PdfEngine::load_png(b).ok());

    let school_name = settings.school_name.clone().unwrap_or_default();
    let region = settings.school_region.clone().unwrap_or_default();
    let division = settings.school_division.clone().unwrap_or_default();
    let district = settings.school_district.clone().unwrap_or_default();
    let school_id = settings.school_code.clone();
    let school_year = sf9.school_year.clone().unwrap_or_else(|| settings.school_year.clone().unwrap_or_default());

    // Page 1
    let (p1, l1) = engine.add_page(Mm(PAGE_W), Mm(PAGE_H));
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
    seal: Option<Image>,
    logo: Option<Image>,
) {
    let top = PAGE_H - MARGIN;
    let left = MARGIN;
    let right = PAGE_W - MARGIN;
    let center = PAGE_W / 2.0;

    // --- Top row: SF9-SHS label + DepEd header + Student info ---
    // SF9-SHS label (left)
    engine.draw_text(layer, "SF9-SHS", 10.0, Mm(left), Mm(top), true);
    engine.draw_text(layer, "LRN", 7.0, Mm(left), Mm(top - 8.0), true);

    let lrn = sf9.lrn.as_deref().unwrap_or("");
    for i in 0..12 {
        let ch = lrn.chars().nth(i).unwrap_or(' ');
        let x = left + i as f32 * 6.0;
        engine.draw_rect(layer, Mm(x), Mm(top - 22.0), Mm(6.0), Mm(6.0), None, true);
        engine.draw_text(layer, &ch.to_string(), 6.0, Mm(x + 2.0), Mm(top - 21.0), false);
    }

    // DepEd header (center)
    let header_y = top - 4.0;
    if let Some(img) = seal {
        img.add_to_layer(
            layer.clone(),
            ImageTransform {
                translate_x: Some(Mm(center - 15.0)),
                translate_y: Some(Mm(header_y - 18.0)),
                scale_x: Some(0.06),
                scale_y: Some(0.06),
                ..Default::default()
            },
        );
    }

    engine.draw_text(layer, "Republic of the Philippines", 9.0, Mm(center), Mm(header_y - 20.0), true);
    engine.draw_text(layer, "DEPARTMENT OF EDUCATION", 9.0, Mm(center - 35.0), Mm(header_y - 26.0), true);

    let mut meta_y = header_y - 34.0;
    draw_meta_line(engine, layer, "Region", region, center, meta_y);
    meta_y -= 5.0;
    draw_meta_line(engine, layer, "Division", division, center, meta_y);
    if !district.is_empty() {
        meta_y -= 5.0;
        draw_meta_line(engine, layer, "District", district, center, meta_y);
    }
    meta_y -= 5.0;
    draw_meta_line(engine, layer, "School Name", school_name, center, meta_y);
    meta_y -= 5.0;
    draw_meta_line(engine, layer, "School ID", school_id, center, meta_y);

    // Logo (right)
    if let Some(img) = logo {
        img.add_to_layer(
            layer.clone(),
            ImageTransform {
                translate_x: Some(Mm(right - 30.0)),
                translate_y: Some(Mm(top - 20.0)),
                scale_x: Some(0.06),
                scale_y: Some(0.06),
                ..Default::default()
            },
        );
    }

    // Student info block (right)
    let info_x = right - 80.0;
    let mut info_y = top - 4.0;
    draw_info_field(engine, layer, "Name (Last, First, Middle)", &sf9.student_name, info_x, info_y, 80.0);
    info_y -= 7.0;
    draw_info_field(engine, layer, "Age", &sf9.age.map(|a| a.to_string()).unwrap_or_default(), info_x, info_y, 80.0);
    info_y -= 7.0;
    draw_info_field(engine, layer, "Sex", sf9.sex.as_deref().unwrap_or(""), info_x, info_y, 80.0);
    info_y -= 7.0;
    draw_info_field(engine, layer, "Grade Level", sf9.grade_level.as_deref().unwrap_or(""), info_x, info_y, 80.0);
    info_y -= 7.0;
    draw_info_field(engine, layer, "Section", sf9.section.as_deref().unwrap_or(""), info_x, info_y, 80.0);
    info_y -= 7.0;
    draw_info_field(engine, layer, "Curriculum", sf9.curriculum.as_deref().unwrap_or(""), info_x, info_y, 80.0);
    info_y -= 7.0;
    draw_info_field(engine, layer, "School Year", school_year, info_x, info_y, 80.0);
    info_y -= 7.0;
    draw_info_field(engine, layer, "Track/Strand", sf9.track_strand.as_deref().unwrap_or(""), info_x, info_y, 80.0);

    // --- Report on Attendance ---
    let mut y = meta_y - 16.0;
    engine.draw_text(layer, "REPORT ON ATTENDANCE", 9.0, Mm(left), Mm(y), true);
    y -= 6.0;
    draw_attendance_table(engine, layer, left, y);

    // --- Parent's/Guardian's Signature ---
    y -= 50.0;
    engine.draw_text(layer, "Parent's/Guardian's Signature", 9.0, Mm(left), Mm(y), true);
    y -= 8.0;
    draw_signature_line(engine, layer, left, y, "1st Quarter");
    draw_signature_line(engine, layer, left + 50.0, y, "2nd Quarter");
    draw_signature_line(engine, layer, left + 100.0, y, "3rd Quarter");
    draw_signature_line(engine, layer, left + 150.0, y, "4th Quarter");

    // --- Certificate of Transfer ---
    y -= 20.0;
    engine.draw_text(layer, "CERTIFICATE OF TRANSFER", 9.0, Mm(left), Mm(y), true);
    y -= 8.0;
    draw_info_field(engine, layer, "Admitted to Grade", "", left, y, 120.0);
    y -= 8.0;
    draw_info_field(engine, layer, "School", "", left, y, 120.0);
    y -= 8.0;
    draw_info_field(engine, layer, "Date", "", left, y, 120.0);
    y -= 8.0;
    draw_info_field(engine, layer, "Signature of School Head", "", left, y, 120.0);

    // --- Cancellation of Eligibility to Transfer ---
    y -= 16.0;
    engine.draw_text(layer, "CANCELLATION OF ELIGIBILITY TO TRANSFER", 8.0, Mm(left), Mm(y), true);
    y -= 8.0;
    draw_info_field(engine, layer, "Eligibility cancelled on", "", left, y, 120.0);
    y -= 8.0;
    draw_info_field(engine, layer, "Reason", "", left, y, 120.0);
    y -= 8.0;
    draw_info_field(engine, layer, "Signature of School Head", "", left, y, 120.0);

    // --- Dear Parent/Guardian letter ---
    y -= 14.0;
    engine.draw_text(layer, "Dear Parent/Guardian:", 8.0, Mm(left), Mm(y), false);
    y -= 10.0;
    let letter_text = "Please be informed that the enclosed report card shows the scholastic standing of your child/ward in this school. You are hereby requested to examine this report carefully. If you have any questions regarding the report, please see the class adviser.";
    draw_wrapped_text(engine, layer, letter_text, left, y, PAGE_W - 2.0 * MARGIN, 7.0);
    y -= 20.0;
    draw_info_field(engine, layer, "Class Adviser", "", left, y, 120.0);
}

fn draw_page2(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    sf9: &Sf9Response,
) {
    let top = PAGE_H - MARGIN;
    let left = MARGIN;
    let _right = PAGE_W - MARGIN;
    let mut y = top;

    // Left side: Report on Learning Progress and Achievement
    engine.draw_text(layer, "REPORT ON LEARNING PROGRESS AND ACHIEVEMENT", 8.0, Mm(left), Mm(y), true);
    y -= 6.0;
    let table_bottom = draw_learning_progress_table(engine, layer, sf9, left, y);
    y = table_bottom - 8.0;
    draw_grading_scale_legend(engine, layer, left, y);

    // Right side: Report on Learner's Observed Values
    let right_x = left + 120.0;
    let mut ry = top;
    engine.draw_text(layer, "REPORT ON LEARNER'S OBSERVED VALUES", 7.0, Mm(right_x), Mm(ry), true);
    ry -= 6.0;
    draw_core_values_table(engine, layer, right_x, ry);
}

fn draw_meta_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    label: &str,
    value: &str,
    center: f32,
    y: f32,
) {
    let display = if value.is_empty() { "_______" } else { value };
    let text = format!("{}: {}", label, display);
    let text_w = text.len() as f32 * 1.8;
    engine.draw_text(layer, &text, 7.0, Mm(center - text_w / 2.0), Mm(y), false);
}

fn draw_info_field(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    label: &str,
    value: &str,
    x: f32,
    y: f32,
    w: f32,
) {
    engine.draw_text(layer, &format!("{}: ", label), 7.0, Mm(x), Mm(y), true);
    let label_w = label.len() as f32 * 1.8 + 6.0;
    let val = if value.is_empty() { " " } else { value };
    engine.draw_rect(
        layer,
        Mm(x + label_w),
        Mm(y - 1.0),
        Mm(w - label_w),
        Mm(4.0),
        None,
        true,
    );
    engine.draw_text(layer, val, 7.0, Mm(x + label_w + 2.0), Mm(y), false);
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
    let chars_per_line = (max_width / (font_size * 0.45)) as usize;
    let mut current_y = y;
    let words: Vec<&str> = text.split_whitespace().collect();
    let mut line = String::new();

    for word in words {
        if line.len() + word.len() + 1 > chars_per_line {
            engine.draw_text(layer, &line, font_size, Mm(x), Mm(current_y), false);
            current_y -= font_size * 1.2;
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

fn draw_signature_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    label: &str,
) {
    engine.draw_rect(layer, Mm(x), Mm(y - 12.0), Mm(40.0), Mm(12.0), None, true);
    engine.draw_text(layer, label, 7.0, Mm(x), Mm(y - 16.0), false);
}

fn draw_attendance_table(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
) -> f32 {
    let months = [
        "June", "July", "Aug", "Sept", "Oct",
        "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "TOTAL",
    ];
    let rows = ["No. of School Days", "Days Present", "Days Absent"];

    let col0_w = 50.0;
    let col_w = (PAGE_W - 2.0 * MARGIN - col0_w) / months.len() as f32;
    let row_h = 10.0;

    let mut cx = x;
    // Header row
    engine.draw_rect(layer, Mm(cx), Mm(y - row_h), Mm(col0_w), Mm(row_h), Some(grey300()), true);
    engine.draw_text(layer, "Month", 6.0, Mm(cx + 2.0), Mm(y - row_h + 2.0), true);
    cx += col0_w;

    for m in &months {
        engine.draw_rect(layer, Mm(cx), Mm(y - row_h), Mm(col_w), Mm(row_h), Some(grey300()), true);
        engine.draw_text(layer, m, 5.0, Mm(cx + 1.0), Mm(y - row_h + 2.0), true);
        cx += col_w;
    }

    let mut cy = y - row_h;
    for row_label in &rows {
        cx = x;
        engine.draw_rect(layer, Mm(cx), Mm(cy - row_h), Mm(col0_w), Mm(row_h), None, true);
        engine.draw_text(layer, row_label, 5.0, Mm(cx + 2.0), Mm(cy - row_h + 2.0), true);
        cx += col0_w;
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
) -> f32 {
    let headers = ["Learning Areas", "Q1", "Q2", "Q3", "Q4", "Final\nRating", "Remarks"];
    let col_widths = [60.0, 18.0, 18.0, 18.0, 18.0, 22.0, 24.0];
    let row_h = 10.0;
    let header_h = 14.0;

    let _total_w: f32 = col_widths.iter().sum();
    let mut cy = y;

    // Header
    let mut cx = x;
    for (i, h) in headers.iter().enumerate() {
        engine.draw_rect(
            layer,
            Mm(cx),
            Mm(cy - header_h),
            Mm(col_widths[i]),
            Mm(header_h),
            Some(grey300()),
            true,
        );
        engine.draw_text(layer, h, 6.0, Mm(cx + 2.0), Mm(cy - header_h + 3.0), true);
        cx += col_widths[i];
    }
    cy -= header_h;

    // Subject rows
    for subject in &sf9.subjects {
        let period_grades: Vec<String> = subject.period_grades.iter().map(|g| g.map(|v| v.to_string()).unwrap_or_default()).collect();
        let row_data = [
            subject.class_title.clone(),
            period_grades.get(0).cloned().unwrap_or_default(),
            period_grades.get(1).cloned().unwrap_or_default(),
            period_grades.get(2).cloned().unwrap_or_default(),
            period_grades.get(3).cloned().unwrap_or_default(),
            subject.final_grade.map(|v| v.to_string()).unwrap_or_default(),
            subject.final_grade.map(|g| if g >= 75 { "Passed".to_string() } else { "Failed".to_string() }).unwrap_or_default(),
        ];

        cx = x;
        for (i, cell) in row_data.iter().enumerate() {
            engine.draw_rect(
                layer,
                Mm(cx),
                Mm(cy - row_h),
                Mm(col_widths[i]),
                Mm(row_h),
                None,
                true,
            );
            let align_x = if i == 0 { cx + 2.0 } else { cx + col_widths[i] / 2.0 - cell.len() as f32 * 1.2 };
            engine.draw_text(layer, cell, 6.0, Mm(align_x.max(cx + 1.0)), Mm(cy - row_h + 2.0), i == 5);
            cx += col_widths[i];
        }
        cy -= row_h;
    }

    // General Average row
    if let Some(ref ga) = sf9.general_average {
        let period_grades: Vec<String> = ga.period_grades.iter().map(|g| g.map(|v| v.to_string()).unwrap_or_default()).collect();
        let row_data = [
            "General Average".to_string(),
            period_grades.get(0).cloned().unwrap_or_default(),
            period_grades.get(1).cloned().unwrap_or_default(),
            period_grades.get(2).cloned().unwrap_or_default(),
            period_grades.get(3).cloned().unwrap_or_default(),
            ga.final_average.map(|v| v.to_string()).unwrap_or_default(),
            ga.final_average.map(|g| if g >= 75 { "Passed".to_string() } else { "Failed".to_string() }).unwrap_or_default(),
        ];

        cx = x;
        for (i, cell) in row_data.iter().enumerate() {
            engine.draw_rect(
                layer,
                Mm(cx),
                Mm(cy - row_h),
                Mm(col_widths[i]),
                Mm(row_h),
                Some(grey300()),
                true,
            );
            let align_x = if i == 0 { cx + 2.0 } else { cx + col_widths[i] / 2.0 - cell.len() as f32 * 1.2 };
            engine.draw_text(layer, cell, 6.0, Mm(align_x.max(cx + 1.0)), Mm(cy - row_h + 2.0), true);
            cx += col_widths[i];
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
    let legend_data = [
        ("90-94", "Outstanding", "Passed"),
        ("85-89", "Very Satisfactory", "Passed"),
        ("80-84", "Satisfactory", "Passed"),
        ("75-79", "Fairly Satisfactory", "Passed"),
        ("Below 75", "Did Not Meet Expectations", "Failed"),
    ];

    let col_widths = [30.0, 60.0, 30.0];
    let row_h = 8.0;
    let header_h = 10.0;
    let mut cy = y;

    let headers = ["Range", "Descriptor", "Remarks"];
    let mut cx = x;
    for (i, h) in headers.iter().enumerate() {
        engine.draw_rect(
            layer,
            Mm(cx),
            Mm(cy - header_h),
            Mm(col_widths[i]),
            Mm(header_h),
            Some(grey300()),
            true,
        );
        engine.draw_text(layer, h, 5.0, Mm(cx + 2.0), Mm(cy - header_h + 2.0), true);
        cx += col_widths[i];
    }
    cy -= header_h;

    for (range, desc, remarks) in &legend_data {
        cx = x;
        let cells = [*range, *desc, *remarks];
        for (i, cell) in cells.iter().enumerate() {
            engine.draw_rect(
                layer,
                Mm(cx),
                Mm(cy - row_h),
                Mm(col_widths[i]),
                Mm(row_h),
                None,
                true,
            );
            engine.draw_text(layer, cell, 5.0, Mm(cx + 2.0), Mm(cy - row_h + 2.0), false);
            cx += col_widths[i];
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
) -> f32 {
    let core_values = [
        ("Maka-Diyos", vec![
            "Expresses one's spiritual beliefs while respecting those of others",
            "Shows adherence to ethical principles by upholding truth and justice at all times",
        ]),
        ("Makatao", vec![
            "Demonstrates pride in being a Filipino without looking down on others",
            "Listens attentively and responds appropriately to the opinions of others",
        ]),
        ("Maka-Kalikasan", vec![
            "Shows care and concern for the environment",
            "Demonstrates resourcefulness and creativity in solving problems",
        ]),
        ("Maka-bansa", vec![
            "Demonstrates pride in being a Filipino without looking down on others",
            "Shows commitment to the ideals of democracy and nationalism",
        ]),
    ];

    let col_widths = [28.0, 60.0, 14.0, 14.0, 14.0, 14.0];
    let row_h = 10.0;
    let header_h = 12.0;
    let mut cy = y;

    let headers = ["Core Values", "Behavior Statements", "Q1", "Q2", "Q3", "Q4"];
    let mut cx = x;
    for (i, h) in headers.iter().enumerate() {
        engine.draw_rect(
            layer,
            Mm(cx),
            Mm(cy - header_h),
            Mm(col_widths[i]),
            Mm(header_h),
            Some(grey300()),
            true,
        );
        engine.draw_text(layer, h, 5.0, Mm(cx + 2.0), Mm(cy - header_h + 3.0), true);
        cx += col_widths[i];
    }
    cy -= header_h;

    for (cv_name, statements) in &core_values {
        for (i, stmt) in statements.iter().enumerate() {
            cx = x;
            let name = if i == 0 { *cv_name } else { "" };
            let cells = [name, stmt, "", "", "", ""];
            for (j, cell) in cells.iter().enumerate() {
                engine.draw_rect(
                    layer,
                    Mm(cx),
                    Mm(cy - row_h),
                    Mm(col_widths[j]),
                    Mm(row_h),
                    None,
                    true,
                );
                let tx = if j == 1 { cx + 1.0 } else { cx + 2.0 };
                let bold = j == 0 && i == 0;
                engine.draw_text(layer, cell, 4.0, Mm(tx), Mm(cy - row_h + 2.0), bold);
                cx += col_widths[j];
            }
            cy -= row_h;
        }
    }

    // Marking legend row
    cx = x;
    let legend_text = "Marking: AO - Always Observed | SO - Sometimes Observed | RO - Rarely Observed | NO - Not Observed";
    engine.draw_rect(
        layer,
        Mm(cx),
        Mm(cy - 6.0),
        Mm(col_widths.iter().sum()),
        Mm(6.0),
        None,
        true,
    );
    engine.draw_text(layer, legend_text, 3.5, Mm(cx + 1.0), Mm(cy - 4.0), false);
    cy -= 6.0;

    cy
}

