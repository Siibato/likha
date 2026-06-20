use std::sync::Arc;

use printpdf::*;
use uuid::Uuid;

use crate::modules::document_export::helpers::deped_header::DepedHeaderData;
use crate::modules::document_export::helpers::grade_table::GradeTableData;
use crate::modules::document_export::helpers::grade_table::StudentRow;
use crate::modules::document_export::helpers::pdf_engine::{PdfEngine, grey300, yellow};
use crate::modules::document_export::service::DocumentExportService;
use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;
use crate::utils::{AppError, AppResult};

const PAGE_W: f32 = 297.0;
const PAGE_H: f32 = 210.0;
const MARGIN: f32 = 10.0;
const NAME_W: f32 = 50.0;
const GRADE_W: f32 = 15.0;
const ROW_H: f32 = 8.0;
const HEADER_H: f32 = 10.0;
const STUDENTS_PER_PAGE: usize = 22;

#[derive(Clone, Copy)]
struct ColWidths {
    item_w: f32,
    tps_w: f32,
}

impl ColWidths {
    fn compute(table: &GradeTableData) -> Self {
        let total_printable = PAGE_W - 2.0 * MARGIN;
        let fixed = NAME_W + 2.0 * GRADE_W;
        let item_cols: usize = table.ww.items.len() + table.pt.items.len() + table.qa.items.len();
        let tps_sections = [&table.ww, &table.pt, &table.qa]
            .iter()
            .filter(|s| !s.items.is_empty())
            .count();
        let tps_total = tps_sections * 3;
        let flex = (total_printable - fixed).max(0.0);
        let units = item_cols + tps_total;
        if units == 0 {
            return Self { item_w: 11.0, tps_w: 13.0 };
        }
        let unit = flex / units as f32;
        let tps_w = (unit * 1.2).max(11.0);
        let item_w = ((flex - tps_total as f32 * tps_w) / item_cols.max(1) as f32).max(9.0);
        Self { item_w, tps_w }
    }
}

impl DocumentExportService {
    pub async fn export_class_grades_pdf(
        &self,
        class_id: Uuid,
        period: i32,
        teacher_id: Uuid,
    ) -> AppResult<Vec<u8>> {
        run(
            &self.grade_service,
            &self.setup_service,
            class_id,
            period,
            teacher_id,
        )
        .await
    }
}

pub async fn run(
    grade_service: &Arc<GradeComputationService>,
    setup_service: &Arc<SetupService>,
    class_id: Uuid,
    period: i32,
    teacher_id: Uuid,
) -> AppResult<Vec<u8>> {
    if !grade_service
        .class_repo
        .is_teacher_of_class(teacher_id, class_id)
        .await?
    {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let grade_data = grade_service.get_all_grade_data(class_id, period).await?;
    let settings = setup_service.get_school_details().await?;
    let class_model = grade_service
        .class_repo
        .find_by_id(class_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;
    let teacher = grade_service
        .class_repo
        .find_teacher_of_class(class_id)
        .await?;
    let teacher_name = teacher.map(|t| t.full_name).unwrap_or_default();

    let header = DepedHeaderData::from_settings(
        &settings,
        &class_model.title,
        class_model.grade_level.as_deref(),
        &teacher_name,
        period,
    );

    let table = GradeTableData::build(&grade_data);

    let engine = PdfEngine::new("Class Record")
        .map_err(|e| AppError::InternalServerError(format!("PDF init: {}", e)))?;

    let seal_bytes = load_asset_with_size("deped_seal.png");
    let logo_bytes = load_asset_with_size("deped_logo.png");

    let total_students = table.students.len();
    let total_pages = ((total_students + STUDENTS_PER_PAGE - 1) / STUDENTS_PER_PAGE).max(1);

    for page in 0..total_pages {
        let start = page * STUDENTS_PER_PAGE;
        let end = (start + STUDENTS_PER_PAGE).min(total_students);

        let (pidx, lidx) = if page == 0 {
            (engine.first_page, engine.first_layer)
        } else {
            engine.add_page(Mm(PAGE_W), Mm(PAGE_H))
        };
        let layer = engine.get_layer(pidx, lidx);

        let seal_img = seal_bytes.as_ref().and_then(|(b, w, h)| PdfEngine::load_png(b).ok().map(|img| (img, *w, *h)));
        let logo_img = logo_bytes.as_ref().and_then(|(b, w, h)| PdfEngine::load_png(b).ok().map(|img| (img, *w, *h)));
        draw_header(&engine, &layer, &header, seal_img, logo_img);
        let cw = ColWidths::compute(&table);
        draw_table(&engine, &layer, &table, cw, start, end, MARGIN, PAGE_H - MARGIN - 46.0_f32);
    }

    engine
        .save()
        .map_err(|e| AppError::InternalServerError(format!("PDF save: {}", e)))
}

fn load_asset_with_size(name: &str) -> Option<(Vec<u8>, u32, u32)> {
    let path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("assets/images")
        .join(name);
    let bytes = std::fs::read(&path).ok()?;
    let (w, h) = image_crate::image_dimensions(&path).ok()?;
    Some((bytes, w, h))
}

fn img_scale(px: u32, target_mm: f32) -> f32 {
    if px == 0 { return 1.0; }
    let native_mm = px as f32 * 25.4 / 300.0;
    target_mm / native_mm
}

fn draw_header(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    header: &DepedHeaderData,
    seal: Option<(Image, u32, u32)>,
    logo: Option<(Image, u32, u32)>,
) {
    let top = PAGE_H - MARGIN;
    let left = MARGIN;
    let seal_mm = 22.0_f32;
    let logo_mm = 28.0_f32;

    if let Some((img, w, h)) = seal {
        let sx = img_scale(w, seal_mm);
        let sy = img_scale(h, seal_mm);
        img.add_to_layer(
            layer.clone(),
            ImageTransform {
                translate_x: Some(Mm(left)),
                translate_y: Some(Mm(top - seal_mm)),
                scale_x: Some(sx),
                scale_y: Some(sy),
                ..Default::default()
            },
        );
    }

    if let Some((img, w, h)) = logo {
        let sx = img_scale(w, logo_mm);
        let sy = img_scale(h, logo_mm * 0.6);
        img.add_to_layer(
            layer.clone(),
            ImageTransform {
                translate_x: Some(Mm(PAGE_W - MARGIN - logo_mm)),
                translate_y: Some(Mm(top - logo_mm * 0.6)),
                scale_x: Some(sx),
                scale_y: Some(sy),
                ..Default::default()
            },
        );
    }

    engine.draw_text(layer, "Class Record", 16.0, Mm(PAGE_W / 2.0 - 30.0), Mm(top - 12.0), true);
    engine.draw_text(
        layer,
        "(Pursuant to DepEd Order 8 series of 2015)",
        8.0,
        Mm(PAGE_W / 2.0 - 45.0),
        Mm(top - 18.0),
        false,
    );

    let y = top - 30.0;
    let field_w = (PAGE_W - 2.0 * MARGIN) / 3.0;
    draw_meta_field(engine, layer, "REGION", &header.region, Mm(left), Mm(y), Mm(field_w));
    draw_meta_field(
        engine,
        layer,
        "DIVISION",
        &header.division,
        Mm(left + field_w),
        Mm(y),
        Mm(field_w),
    );
    draw_meta_field(
        engine,
        layer,
        "DISTRICT",
        &header.district,
        Mm(left + 2.0 * field_w),
        Mm(y),
        Mm(field_w),
    );

    let y2 = y - 8.0;
    draw_meta_field(
        engine,
        layer,
        "SCHOOL NAME",
        &header.school_name,
        Mm(left),
        Mm(y2),
        Mm(field_w * 1.6),
    );
    draw_meta_field(
        engine,
        layer,
        "SCHOOL ID",
        &header.school_id,
        Mm(left + field_w * 1.6),
        Mm(y2),
        Mm(field_w * 0.6),
    );
    draw_meta_field(
        engine,
        layer,
        "SCHOOL YEAR",
        &header.school_year,
        Mm(left + field_w * 2.2),
        Mm(y2),
        Mm(field_w * 0.8),
    );

    let y3 = y2 - 8.0;
    engine.draw_text(layer, &header.quarter_label, 8.0, Mm(left), Mm(y3), true);
    let gs_val = format!("{} {}", header.grade_level, header.section).trim().to_string();
    engine.draw_text(layer, "GRADE & SECTION:", 7.0, Mm(left + 22.0), Mm(y3), true);
    engine.draw_text(layer, &gs_val, 8.0, Mm(left + 58.0), Mm(y3), false);
    engine.draw_text(layer, "TEACHER:", 7.0, Mm(left + 118.0), Mm(y3), true);
    engine.draw_text(layer, &header.teacher_name, 8.0, Mm(left + 142.0), Mm(y3), false);
    engine.draw_text(layer, "SUBJECT:", 7.0, Mm(left + 190.0), Mm(y3), true);
    engine.draw_text(layer, &header.subject, 8.0, Mm(left + 214.0), Mm(y3), false);

    // Quarter box on the far right
    engine.draw_rect(
        layer,
        Mm(PAGE_W - MARGIN - 28.0),
        Mm(y3 - 1.0),
        Mm(28.0),
        Mm(7.0),
        Some(grey300()),
        true,
    );
    engine.draw_text(
        layer,
        &header.quarter_label,
        9.0,
        Mm(PAGE_W - MARGIN - 26.0),
        Mm(y3 + 0.5),
        true,
    );
}

fn draw_meta_field(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    label: &str,
    value: &str,
    x: Mm,
    y: Mm,
    w: Mm,
) {
    engine.draw_text(layer, label, 7.0, x, y, true);
    let val = if value.is_empty() { " " } else { value };
    engine.draw_rect(layer, Mm(x.0 + 20.0), y, Mm(w.0 - 20.0), Mm(5.0), None, true);
    engine.draw_text(layer, val, 8.0, Mm(x.0 + 22.0), Mm(y.0 + 1.0), false);
}

fn draw_table(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    table: &GradeTableData,
    cw: ColWidths,
    start: usize,
    end: usize,
    x: f32,
    y_top: f32,
) {
    draw_section_header_strip(engine, layer, table, cw, x, y_top);
    let y = y_top - HEADER_H;

    draw_column_headers(engine, layer, table, cw, x, y);
    let y = y - HEADER_H;

    draw_hps_row(engine, layer, table, cw, x, y);
    let mut y = y - ROW_H;

    for i in start..end {
        let row = &table.students[i];
        draw_student_row(engine, layer, table, cw, row, x, y);
        y -= ROW_H;
    }
}

fn draw_section_header_strip(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    table: &GradeTableData,
    cw: ColWidths,
    x: f32,
    y_top: f32,
) {
    let mut cx = x;
    engine.draw_rect(
        layer,
        Mm(cx),
        Mm(y_top - HEADER_H),
        Mm(NAME_W),
        Mm(HEADER_H),
        Some(grey300()),
        true,
    );
    engine.draw_text(
        layer,
        "LEARNER'S NAMES",
        7.0,
        Mm(cx + 2.0),
        Mm(y_top - HEADER_H + 2.0),
        true,
    );
    cx += NAME_W;

    for (section, label) in [
        (&table.ww, "WRITTEN WORKS"),
        (&table.pt, "PERFORMANCE TASKS"),
        (&table.qa, "QUARTERLY ASSESSMENT"),
    ] {
        if section.items.is_empty() {
            continue;
        }
        let total_w = section.items.len() as f32 * cw.item_w + 3.0 * cw.tps_w;
        engine.draw_rect(
            layer,
            Mm(cx),
            Mm(y_top - HEADER_H),
            Mm(total_w),
            Mm(HEADER_H),
            Some(grey300()),
            true,
        );
        let label_full = format!("{} ({:.0}%)", label, section.weight);
        engine.draw_text(
            layer,
            &label_full,
            7.0,
            Mm(cx + 2.0),
            Mm(y_top - HEADER_H + 2.0),
            true,
        );
        cx += total_w;
    }

    engine.draw_rect(
        layer,
        Mm(cx),
        Mm(y_top - HEADER_H),
        Mm(GRADE_W),
        Mm(HEADER_H),
        Some(grey300()),
        true,
    );
    engine.draw_text(
        layer,
        "Initial",
        7.0,
        Mm(cx + 1.0),
        Mm(y_top - HEADER_H + 4.0),
        true,
    );
    engine.draw_text(
        layer,
        "Grade",
        7.0,
        Mm(cx + 2.0),
        Mm(y_top - HEADER_H + 1.0),
        true,
    );
    cx += GRADE_W;

    engine.draw_rect(
        layer,
        Mm(cx),
        Mm(y_top - HEADER_H),
        Mm(GRADE_W),
        Mm(HEADER_H),
        Some(grey300()),
        true,
    );
    engine.draw_text(
        layer,
        "Transmuted",
        6.0,
        Mm(cx + 1.0),
        Mm(y_top - HEADER_H + 4.0),
        true,
    );
    engine.draw_text(
        layer,
        "Grade",
        7.0,
        Mm(cx + 2.0),
        Mm(y_top - HEADER_H + 1.0),
        true,
    );
}

fn draw_column_headers(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    table: &GradeTableData,
    cw: ColWidths,
    x: f32,
    y_top: f32,
) {
    let mut cx = x;
    draw_cell(engine, layer, "MALE", cx, y_top, NAME_W, HEADER_H, true);
    cx += NAME_W;

    for section in [&table.ww, &table.pt, &table.qa] {
        if section.items.is_empty() {
            continue;
        }
        for (i, _) in section.items.iter().enumerate() {
            draw_cell(engine, layer, &format!("{}", i + 1), cx, y_top, cw.item_w, HEADER_H, true);
            cx += cw.item_w;
        }
        draw_cell(engine, layer, "Total", cx, y_top, cw.tps_w, HEADER_H, true);
        cx += cw.tps_w;
        draw_cell(engine, layer, "PS", cx, y_top, cw.tps_w, HEADER_H, true);
        cx += cw.tps_w;
        draw_cell(engine, layer, "WS", cx, y_top, cw.tps_w, HEADER_H, true);
        cx += cw.tps_w;
    }

    draw_cell(engine, layer, "", cx, y_top, GRADE_W, HEADER_H, true);
    cx += GRADE_W;
    draw_cell(engine, layer, "", cx, y_top, GRADE_W, HEADER_H, true);
}

fn draw_hps_row(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    table: &GradeTableData,
    cw: ColWidths,
    x: f32,
    y_top: f32,
) {
    let mut cx = x;
    draw_cell(
        engine,
        layer,
        "HIGHEST POSSIBLE SCORE",
        cx,
        y_top,
        NAME_W,
        ROW_H,
        true,
    );
    cx += NAME_W;

    for section in [&table.ww, &table.pt, &table.qa] {
        if section.items.is_empty() {
            continue;
        }
        for item in &section.items {
            draw_cell(
                engine,
                layer,
                &format!("{:.0}", item.total_points),
                cx,
                y_top,
                cw.item_w,
                ROW_H,
                true,
            );
            cx += cw.item_w;
        }
        draw_cell(
            engine,
            layer,
            &format!("{:.0}", section.hps_total),
            cx,
            y_top,
            cw.tps_w,
            ROW_H,
            true,
        );
        cx += cw.tps_w;
        draw_cell(engine, layer, "100.00", cx, y_top, cw.tps_w, ROW_H, true);
        cx += cw.tps_w;
        draw_yellow_cell(
            engine,
            layer,
            &format!("{:.0}%", section.weight),
            cx,
            y_top,
            cw.tps_w,
            ROW_H,
        );
        cx += cw.tps_w;
    }

    draw_cell(engine, layer, "", cx, y_top, GRADE_W, ROW_H, true);
    cx += GRADE_W;
    draw_cell(engine, layer, "", cx, y_top, GRADE_W, ROW_H, true);
}

fn draw_student_row(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    table: &GradeTableData,
    cw: ColWidths,
    row: &StudentRow,
    x: f32,
    y_top: f32,
) {
    let mut cx = x;
    let name = format!("{}. {}", row.index, row.student_name);
    draw_cell_left(engine, layer, &name, cx, y_top, NAME_W, ROW_H, false);
    cx += NAME_W;

    for (result, section) in [
        (&row.ww, &table.ww),
        (&row.pt, &table.pt),
        (&row.qa, &table.qa),
    ] {
        if section.items.is_empty() {
            continue;
        }
        for score in &result.scores {
            let text = match score {
                Some(s) => format!("{:.1}", s),
                None => String::new(),
            };
            draw_cell(engine, layer, &text, cx, y_top, cw.item_w, ROW_H, false);
            cx += cw.item_w;
        }
        let total_text = match result.total {
            Some(t) => format!("{:.1}", t),
            None => String::new(),
        };
        draw_cell(engine, layer, &total_text, cx, y_top, cw.tps_w, ROW_H, false);
        cx += cw.tps_w;
        let ps_text = match result.ps {
            Some(p) => format!("{:.2}", p),
            None => String::new(),
        };
        draw_cell(engine, layer, &ps_text, cx, y_top, cw.tps_w, ROW_H, false);
        cx += cw.tps_w;
        let ws_text = match result.ws {
            Some(w) => format!("{:.2}", w),
            None => String::new(),
        };
        draw_cell(engine, layer, &ws_text, cx, y_top, cw.tps_w, ROW_H, false);
        cx += cw.tps_w;
    }

    let ig_text = match row.initial_grade {
        Some(ig) => format!("{:.2}", ig),
        None => String::new(),
    };
    draw_cell(engine, layer, &ig_text, cx, y_top, GRADE_W, ROW_H, false);
    cx += GRADE_W;
    let tg_text = match row.transmuted_grade {
        Some(tg) => format!("{}", tg),
        None => String::new(),
    };
    draw_cell(engine, layer, &tg_text, cx, y_top, GRADE_W, ROW_H, false);
}

fn draw_cell(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    x: f32,
    y_top: f32,
    w: f32,
    h: f32,
    bold: bool,
) {
    engine.draw_rect(layer, Mm(x), Mm(y_top - h), Mm(w), Mm(h), None, true);
    if !text.is_empty() {
        let text_w = text.len() as f32 * 1.2;
        let tx = x + (w - text_w) / 2.0;
        engine.draw_text(layer, text, 7.0, Mm(tx.max(x + 1.0)), Mm(y_top - h + 2.0), bold);
    }
}

fn draw_cell_left(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    x: f32,
    y_top: f32,
    w: f32,
    h: f32,
    bold: bool,
) {
    engine.draw_rect(layer, Mm(x), Mm(y_top - h), Mm(w), Mm(h), None, true);
    if !text.is_empty() {
        engine.draw_text(layer, text, 7.0, Mm(x + 2.0), Mm(y_top - h + 2.0), bold);
    }
}

fn draw_yellow_cell(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    x: f32,
    y_top: f32,
    w: f32,
    h: f32,
) {
    engine.draw_rect(layer, Mm(x), Mm(y_top - h), Mm(w), Mm(h), Some(yellow()), true);
    if !text.is_empty() {
        let text_w = text.len() as f32 * 1.2;
        let tx = x + (w - text_w) / 2.0;
        engine.draw_text(layer, text, 7.0, Mm(tx.max(x + 1.0)), Mm(y_top - h + 2.0), true);
    }
}
