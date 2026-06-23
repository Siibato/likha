use printpdf::*;

use crate::modules::document_export::helpers::pdf_engine::PdfEngine;
use crate::modules::grading::schema::Sf9Response;

use super::layout::*;

pub fn draw_page1_left(engine: &PdfEngine, layer: &PdfLayerReference, sf9: &Sf9Response) {
    let left = LEFT_COL_LEFT;
    let top = CONTENT_TOP;
    let l_w = LEFT_COL_WIDTH;
    let mut y = top;

    // Attendance Record
    draw_centered_text(engine, layer, "Attendance Record", 13.0, left, l_w, y, true);
    y -= GAP_MEDIUM;
    let att_bottom = draw_attendance_table(engine, layer, left, y, l_w, sf9);
    y = att_bottom - GAP_XXL;

    // PARENT/GUARDIAN'S SIGNATURE
    engine.draw_text(
        layer,
        "PARENT/GUARDIAN'S SIGNATURE",
        FONT_SIZE_HEADER,
        Mm(left + 5.0),
        Mm(y),
        true,
    );
    y -= GAP_XL;

    let terms = ["Term 1", "Term 2", "Term 3"];
    for term in &terms {
        engine.draw_text(layer, term, FONT_SIZE_LARGE, Mm(left + 5.0), Mm(y), false);
        draw_horizontal_line(engine, layer, left + 35.0, y - 2.0, l_w - 40.0, 0.3);
        y -= GAP_XL;
    }
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
        ("Jun", "June"),
        ("Jul", "July"),
        ("Aug", "August"),
        ("Sept", "September"),
        ("Oct", "October"),
        ("Nov", "November"),
        ("Dec", "December"),
        ("Jan", "January"),
        ("Feb", "February"),
        ("Mar", "March"),
        ("Apr", "April"),
    ];
    let total_label = "Total";
    let rows = [
        "No. of\nSchool\nDays",
        "No. of\nDays\nPresent",
        "No. of\nTimes\nAbsent",
    ];
    let row_labels_single = [
        "No. of School Days",
        "No. of Days Present",
        "No. of Times Absent",
    ];

    let label_column_width = 18.0;
    let data_column_width = (total_width - label_column_width) / (month_names.len() as f32 + 1.0);
    let header_height = TABLE_TERM_HEADER_HEIGHT;
    let row_height = 14.0;

    // Build a map month -> record for quick lookup (full month names as keys)
    let att_map: std::collections::HashMap<
        &str,
        &crate::modules::grading::schema::Sf9AttendanceRecord,
    > = sf9
        .attendance
        .iter()
        .map(|r| (r.month.as_str(), r))
        .collect();

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
        engine.draw_text(
            layer,
            abbr,
            FONT_SIZE_SMALL,
            Mm(current_x + 1.0),
            Mm(origin_y - header_height + 3.0),
            false,
        );
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
    engine.draw_text(
        layer,
        total_label,
        FONT_SIZE_SMALL,
        Mm(current_x + 1.0),
        Mm(origin_y - header_height + 3.0),
        false,
    );

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
                FONT_SIZE_XS,
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
                        absent.to_string()
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
                engine.draw_text(
                    layer,
                    &text,
                    FONT_SIZE_SMALL,
                    Mm(tx.max(current_x + 0.5)),
                    Mm(current_y - row_height + 3.0),
                    false,
                );
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
        let tx = current_x + data_column_width / 2.0 - total.to_string().len() as f32 * 1.8;
        engine.draw_text(
            layer,
            &total.to_string(),
            FONT_SIZE_SMALL,
            Mm(tx.max(current_x + 0.5)),
            Mm(current_y - row_height + 3.0),
            true,
        );

        current_y -= row_height;
    }

    current_y
}
