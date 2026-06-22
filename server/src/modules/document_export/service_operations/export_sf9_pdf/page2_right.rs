use printpdf::*;

use crate::modules::document_export::helpers::pdf_engine::{PdfEngine, grey300};
use crate::modules::grading::schema::Sf9Response;

use super::layout::*;

pub fn draw_page2_right(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    sf9: &Sf9Response,
) {
    let top = CONTENT_TOP;
    let rx = RIGHT_COL_LEFT;
    let r_w = RIGHT_COL_WIDTH;

    engine.draw_text(
        layer,
        "REPORT ON LEARNER'S OBSERVED VALUES",
        FONT_SIZE_LARGE,
        Mm(rx),
        Mm(top),
        true,
    );
    let cv_bottom = draw_core_values_table(engine, layer, sf9, rx, top - GAP_MEDIUM, r_w);

    // Marking legend
    let mut my = cv_bottom - GAP_XL;
    engine.draw_text(layer, "Marking", FONT_SIZE_LARGE, Mm(rx), Mm(my), true);
    engine.draw_text(layer, "Non-numerical Rating", FONT_SIZE_LARGE, Mm(rx + 40.0), Mm(my), true);
    let marks = [
        ("AO", "Always Observed"),
        ("SO", "Sometimes Observed"),
        ("RO", "Rarely Observed"),
        ("NO", "Not Observed"),
    ];
    for (code, desc) in &marks {
        my -= GAP_MEDIUM;
        engine.draw_text(layer, code, FONT_SIZE_LARGE, Mm(rx + 5.0), Mm(my), false);
        engine.draw_text(layer, desc, FONT_SIZE_LARGE, Mm(rx + 40.0), Mm(my), false);
    }
}

fn draw_core_values_table(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    sf9: &Sf9Response,
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

    let ratios = [18.0_f32, 60.0, 7.0, 7.0, 8.0];
    let ratio_sum: f32 = ratios.iter().sum();
    let column_widths: Vec<f32> = ratios.iter().map(|ratio| ratio / ratio_sum * avail_w).collect();

    let term_header_height = TABLE_TERM_HEADER_HEIGHT;
    let header_row_height = TABLE_HEADER_HEIGHT;
    let mut current_y = y;

    // "Term" super-header spanning T1-T3
    let term_start_x = x + column_widths[0] + column_widths[1];
    let term_section_width = column_widths[2] + column_widths[3] + column_widths[4];
    engine.draw_rect(layer, Mm(x), Mm(current_y - term_header_height), Mm(column_widths[0]), Mm(term_header_height), Some(grey300()), true);
    engine.draw_rect(layer, Mm(x + column_widths[0]), Mm(current_y - term_header_height), Mm(column_widths[1]), Mm(term_header_height), Some(grey300()), true);
    engine.draw_rect(layer, Mm(term_start_x), Mm(current_y - term_header_height), Mm(term_section_width), Mm(term_header_height), Some(grey300()), true);
    engine.draw_text(layer, "Term", FONT_SIZE_NORMAL, Mm(term_start_x + term_section_width / 2.0 - 9.0), Mm(current_y - term_header_height + 2.5), true);
    current_y -= term_header_height;

    // Column header row
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
        engine.draw_text(layer, label, FONT_SIZE_NORMAL, Mm(text_x.max(current_x + 0.5)), Mm(current_y - header_row_height + 3.0), true);
        current_x += column_widths[i];
    }
    current_y -= header_row_height;

    // Build a lookup map: (core_value_id, term_number) -> marking
    let mut marking_map: std::collections::HashMap<(i32, i32), &str> = std::collections::HashMap::new();
    for cv in &sf9.core_values {
        marking_map.insert((cv.core_value_id, cv.term_number), cv.marking.as_str());
    }

    // Core value rows
    let mut statement_id = 1;
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
            engine.draw_text(layer, line, FONT_SIZE_NORMAL, Mm(x + 1.5), Mm(label_y), false);
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
            super::layout::draw_wrapped_text(
                engine,
                layer,
                statement,
                x + column_widths[0] + BEHAVIOR_TEXT_PADDING_X,
                row_top - BEHAVIOR_TEXT_PADDING_TOP,
                column_widths[1] - BEHAVIOR_TEXT_PADDING_RIGHT,
                BEHAVIOR_FONT_SIZE,
            );

            // Term columns — draw markings from sf9.core_values
            let mut term_x = x + column_widths[0] + column_widths[1];
            for term_num in 1..=3 {
                let marking = marking_map
                    .get(&(statement_id, term_num))
                    .unwrap_or(&"");
                engine.draw_rect(
                    layer,
                    Mm(term_x),
                    Mm(row_bottom),
                    Mm(column_widths[term_num as usize + 1]),
                    Mm(CORE_VALUES_ROW_HEIGHT),
                    None,
                    true,
                );
                if !marking.is_empty() {
                    let text_w = text_width(marking, FONT_SIZE_NORMAL);
                    let text_x = term_x + column_widths[term_num as usize + 1] / 2.0 - text_w / 2.0;
                    engine.draw_text(
                        layer,
                        marking,
                        FONT_SIZE_NORMAL,
                        Mm(text_x.max(term_x + 0.5)),
                        Mm(row_bottom + CORE_VALUES_ROW_HEIGHT / 2.0 - 2.5),
                        false,
                    );
                }
                term_x += column_widths[term_num as usize + 1];
            }
        }
        statement_id += statement_count as i32;
        current_y -= core_value_height;
    }

    current_y
}
