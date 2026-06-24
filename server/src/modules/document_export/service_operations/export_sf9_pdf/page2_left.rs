use printpdf::*;

use crate::modules::document_export::helpers::pdf_engine::{grey300, PdfEngine};
use crate::modules::grading::schema::Sf9Response;

use super::layout::*;

pub fn draw_page2_left(engine: &PdfEngine, layer: &PdfLayerReference, sf9: &Sf9Response) {
    let top = CONTENT_TOP;
    let left = LEFT_COL_LEFT;
    let col_split = LEFT_COL_RIGHT;

    engine.draw_text(
        layer,
        "REPORT ON LEARNING PROGRESS AND ACHIEVEMENT",
        FONT_SIZE_LARGE,
        Mm(left),
        Mm(top),
        true,
    );
    let table_bottom = draw_learning_progress_table(
        engine,
        layer,
        sf9,
        left,
        top - GAP_MEDIUM,
        col_split - left - 2.0,
    );
    draw_grading_scale_legend(engine, layer, left, table_bottom - GAP_LARGE);
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
    let column_widths: Vec<f32> = ratios
        .iter()
        .map(|ratio| ratio / ratio_sum * avail_w)
        .collect();

    let term_header_height = TABLE_TERM_HEADER_HEIGHT;
    let header_row_height = TABLE_HEADER_HEIGHT;
    let row_height = TABLE_ROW_HEIGHT;
    let mut current_y = y;

    // Row 0: "Term" spanning T1-T3
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
        FONT_SIZE_NORMAL,
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

    // Row 1: column headers
    let column_labels = [
        "Learning Areas",
        "T1",
        "T2",
        "T3",
        "Final\nRating",
        "Remarks",
    ];
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
                FONT_SIZE_NORMAL,
                Mm(text_x.max(current_x + 0.5)),
                Mm(line_y),
                true,
            );
            line_y -= header_line_spacing;
        }
        current_x += column_widths[i];
    }
    current_y -= header_row_height;

    // Subject rows
    for subject in &sf9.subjects {
        let pg: Vec<String> = subject
            .term_grades
            .iter()
            .map(|g| g.map(|v| v.to_string()).unwrap_or_default())
            .collect();
        let final_g = subject
            .final_grade
            .map(|v| v.to_string())
            .unwrap_or_default();
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
            engine.draw_rect(
                layer,
                Mm(current_x),
                Mm(current_y - row_height),
                Mm(column_widths[i]),
                Mm(row_height),
                None,
                true,
            );
            let text_x = if i == 0 {
                current_x + 2.0
            } else {
                current_x + column_widths[i] / 2.0 - cell.len() as f32 * 1.8
            };
            engine.draw_text(
                layer,
                cell,
                FONT_SIZE_NORMAL,
                Mm(text_x.max(current_x + 0.5)),
                Mm(current_y - row_height + 3.0),
                i == 5,
            );
            current_x += column_widths[i];
        }
        current_y -= row_height;
    }

    // General Average row
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
            engine.draw_text(
                layer,
                cell,
                FONT_SIZE_NORMAL,
                Mm(text_x.max(current_x + 0.5)),
                Mm(current_y - row_height + 3.0),
                true,
            );
            current_x += column_widths[i];
        }
        current_y -= row_height;
    }

    current_y
}

fn draw_grading_scale_legend(engine: &PdfEngine, layer: &PdfLayerReference, x: f32, y: f32) -> f32 {
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
    let row_height = GAP_MEDIUM;
    let mut current_y = y;

    engine.draw_text(
        layer,
        "Descriptors",
        FONT_SIZE_MEDIUM,
        Mm(descriptor_x),
        Mm(current_y),
        true,
    );
    engine.draw_text(
        layer,
        "Grading Scale",
        FONT_SIZE_MEDIUM,
        Mm(scale_x),
        Mm(current_y),
        true,
    );
    engine.draw_text(
        layer,
        "Remarks",
        FONT_SIZE_MEDIUM,
        Mm(remarks_x),
        Mm(current_y),
        true,
    );
    current_y -= GAP_SMALL;

    for (desc, scale, rem) in &data {
        current_y -= row_height;
        engine.draw_text(
            layer,
            desc,
            FONT_SIZE_MEDIUM,
            Mm(descriptor_x),
            Mm(current_y),
            false,
        );
        engine.draw_text(
            layer,
            scale,
            FONT_SIZE_MEDIUM,
            Mm(scale_x),
            Mm(current_y),
            false,
        );
        engine.draw_text(
            layer,
            rem,
            FONT_SIZE_MEDIUM,
            Mm(remarks_x),
            Mm(current_y),
            false,
        );
    }
    current_y
}
