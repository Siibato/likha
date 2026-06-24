use super::layout::*;
use crate::modules::tos::schema::TosResponse;

pub fn write_table(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    tos: &TosResponse,
) -> Result<u32, rust_xlsxwriter::XlsxError> {
    let is_blooms = tos.classification_mode == "blooms";

    // Two-row grouped header.
    write_table_header(sheet, start_row, is_blooms)?;
    let mut row = start_row + 2;

    let total_time = tos.competencies.iter().map(|c| c.time_units_taught).sum::<i32>();

    // Column indices for the "Total Number of Items" group depend on the mode.
    let actual_col: u16 = if is_blooms { 10 } else { 7 };
    let adjusted_col: u16 = actual_col + 1;

    let mut sum_actual = 0i32;
    let mut sum_adjusted = 0i32;

    for c in &tos.competencies {
        let weight = if total_time > 0 {
            c.time_units_taught as f64 / total_time as f64 * 100.0
        } else {
            0.0
        };
        let target_items = if total_time > 0 {
            (c.time_units_taught as f64 / total_time as f64 * tos.total_items as f64).round() as i32
        } else {
            0
        };

        let topic = c.competency_code.clone().unwrap_or_default();

        // Per-level distributed counts (explicit value, else weight-based).
        let counts: Vec<i32> = if is_blooms {
            vec![
                c.remembering_count.unwrap_or_else(|| (target_items as f64 * tos.remembering_percentage / 100.0).round() as i32),
                c.understanding_count.unwrap_or_else(|| (target_items as f64 * tos.understanding_percentage / 100.0).round() as i32),
                c.applying_count.unwrap_or_else(|| (target_items as f64 * tos.applying_percentage / 100.0).round() as i32),
                c.analyzing_count.unwrap_or_else(|| (target_items as f64 * tos.analyzing_percentage / 100.0).round() as i32),
                c.evaluating_count.unwrap_or_else(|| (target_items as f64 * tos.evaluating_percentage / 100.0).round() as i32),
                c.creating_count.unwrap_or_else(|| (target_items as f64 * tos.creating_percentage / 100.0).round() as i32),
            ]
        } else {
            vec![
                c.easy_count.unwrap_or_else(|| (target_items as f64 * tos.easy_percentage / 100.0).round() as i32),
                c.medium_count.unwrap_or_else(|| (target_items as f64 * tos.medium_percentage / 100.0).round() as i32),
                c.hard_count.unwrap_or_else(|| (target_items as f64 * tos.hard_percentage / 100.0).round() as i32),
            ]
        };
        let actual: i32 = counts.iter().sum();
        sum_actual += actual;
        sum_adjusted += target_items;

        sheet.write_with_format(row, 0, &topic, &cell_fmt())?;
        sheet.write_with_format(row, 1, &c.competency_text, &left_cell_fmt())?;
        sheet.write_with_format(row, 2, c.time_units_taught, &cell_fmt())?;
        sheet.write_with_format(row, 3, format!("{:.0}%", weight), &cell_fmt())?;
        for (i, v) in counts.iter().enumerate() {
            sheet.write_with_format(row, 4 + i as u16, *v, &cell_fmt())?;
        }
        sheet.write_with_format(row, actual_col, actual, &cell_fmt())?;
        sheet.write_with_format(row, adjusted_col, target_items, &cell_fmt())?;
        row += 1;
    }

    // TOTAL row: 100% under Time, percentage distribution under each level,
    // and the summed item totals under Actual/Adjusted.
    sheet.merge_range(row, 0, row, 1, "TOTAL", &total_row_fmt())?;
    sheet.write_with_format(row, 2, "100%", &total_row_fmt())?;
    sheet.write_with_format(row, 3, " ", &total_row_fmt())?;

    let level_pcts: Vec<f64> = if is_blooms {
        vec![
            tos.remembering_percentage,
            tos.understanding_percentage,
            tos.applying_percentage,
            tos.analyzing_percentage,
            tos.evaluating_percentage,
            tos.creating_percentage,
        ]
    } else {
        vec![tos.easy_percentage, tos.medium_percentage, tos.hard_percentage]
    };
    for (i, p) in level_pcts.iter().enumerate() {
        sheet.write_with_format(row, 4 + i as u16, format!("{:.0}%", p), &total_row_fmt())?;
    }
    sheet.write_with_format(row, actual_col, sum_actual, &total_row_fmt())?;
    sheet.write_with_format(row, adjusted_col, sum_adjusted, &total_row_fmt())?;

    Ok(row + 1)
}

fn write_table_header(
    sheet: &mut rust_xlsxwriter::Worksheet,
    top: u32,
    is_blooms: bool,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let bottom = top + 1;
    let h = tbl_header_fmt();

    // Vertically merged single columns spanning both header rows.
    sheet.merge_range(top, 0, bottom, 0, "Topic", &h)?;
    sheet.merge_range(top, 1, bottom, 1, "Competencies", &h)?;
    sheet.merge_range(top, 2, bottom, 2, "Time Spent/ Frequency", &h)?;
    sheet.merge_range(top, 3, bottom, 3, "Weight %", &h)?;

    // Level group header + sub-headers.
    let (levels, parent): (Vec<&str>, &str) = if is_blooms {
        (
            vec!["Remembering", "Understanding", "Applying", "Analyzing", "Evaluating", "Creating"],
            "BLOOM'S TAXONOMY LEVEL OF LEARNINGS",
        )
    } else {
        (vec!["Easy", "Average", "Difficult"], "LEVEL OF DIFFICULTY")
    };
    let level_start = 4u16;
    let level_end = level_start + levels.len() as u16 - 1;
    sheet.merge_range(top, level_start, top, level_end, parent, &h)?;
    for (i, l) in levels.iter().enumerate() {
        sheet.write_with_format(bottom, level_start + i as u16, *l, &h)?;
    }

    // "Total Number of Items" group split into Actual / Adjusted.
    let actual_col = level_end + 1;
    let adjusted_col = actual_col + 1;
    sheet.merge_range(top, actual_col, top, adjusted_col, "Total Number of Items", &h)?;
    sheet.write_with_format(bottom, actual_col, "Actual", &h)?;
    sheet.write_with_format(bottom, adjusted_col, "Adjusted", &h)?;

    Ok(())
}
