use super::layout::*;
use crate::modules::document_export::helpers::excel_engine::bordered_data_fmt;
use crate::modules::document_export::helpers::grade_table::GradeTableData;

// ─────────────────────────────────────────────────────────────────────────────
// Section header row
// ─────────────────────────────────────────────────────────────────────────────

pub fn write_section_header_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let fmt = tbl_header_fmt();

    sheet.write_with_format(row, name_col as u16, "LEARNERS' NAMES", &fmt)?;

    for (section, start, prefix) in [
        (&table.ww, ww_start, "WRITTEN WORKS"),
        (&table.pt, pt_start, "PERFORMANCE TASKS"),
        (&table.qa, qa_start, "TERM ASSESSMENT"),
    ] {
        if start < 0 {
            continue;
        }
        let span = (section.items.len() + 3) as i32;
        let label = format!("{}({:.0}%)", prefix, section.weight);
        sheet.merge_range(
            row,
            start as u16,
            row,
            (start + span - 1) as u16,
            &label,
            &fmt,
        )?;
    }

    sheet.write_with_format(row, initial_col as u16, "INITIAL\nGRADE", &fmt)?;
    sheet.write_with_format(row, tg_col as u16, "TERM\nGRADE", &fmt)?;
    sheet.write_with_format(row, remarks_col as u16, "REMARKS", &fmt)?;

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// Column sub-header row
// ─────────────────────────────────────────────────────────────────────────────

pub fn write_column_header_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let fmt = tbl_header_fmt();

    sheet.write_with_format(row, name_col as u16, "", &fmt)?;

    for (section, start) in [
        (&table.ww, ww_start),
        (&table.pt, pt_start),
        (&table.qa, qa_start),
    ] {
        if start < 0 {
            continue;
        }
        for (i, _) in section.items.iter().enumerate() {
            sheet.write_with_format(row, (start + i as i32) as u16, (i + 1).to_string(), &fmt)?;
        }
        let n = section.items.len() as i32;
        sheet.write_with_format(row, (start + n) as u16, "Total", &fmt)?;
        sheet.write_with_format(row, (start + n + 1) as u16, "PS", &fmt)?;
        sheet.write_with_format(row, (start + n + 2) as u16, "WS", &fmt)?;
    }

    sheet.write_with_format(row, initial_col as u16, "Grade", &fmt)?;
    sheet.write_with_format(row, tg_col as u16, "Grade", &fmt)?;
    sheet.write_with_format(row, remarks_col as u16, "", &fmt)?;

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// HPS row
// ─────────────────────────────────────────────────────────────────────────────

pub fn write_hps_row(
    sheet: &mut rust_xlsxwriter::Worksheet,
    row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let fmt = tbl_header_fmt();

    sheet.write_with_format(row, name_col as u16, "HIGHEST POSSIBLE SCORE", &fmt)?;

    for (section, start) in [
        (&table.ww, ww_start),
        (&table.pt, pt_start),
        (&table.qa, qa_start),
    ] {
        if start < 0 {
            continue;
        }
        for (i, item) in section.items.iter().enumerate() {
            sheet.write_with_format(
                row,
                (start + i as i32) as u16,
                format!("{:.0}", item.total_points),
                &fmt,
            )?;
        }
        let n = section.items.len() as i32;
        sheet.write_with_format(
            row,
            (start + n) as u16,
            format!("{:.0}", section.hps_total),
            &fmt,
        )?;
        sheet.write_with_format(row, (start + n + 1) as u16, "100.00", &fmt)?;
        sheet.write_with_format(
            row,
            (start + n + 2) as u16,
            format!("{:.0}%", section.weight),
            &fmt,
        )?;
    }

    sheet.write_with_format(row, initial_col as u16, "", &grey_cell_fmt())?;
    sheet.write_with_format(row, tg_col as u16, "", &grey_cell_fmt())?;
    sheet.write_with_format(row, remarks_col as u16, "", &grey_cell_fmt())?;

    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// Student rows  — with REMARKS
// ─────────────────────────────────────────────────────────────────────────────

pub fn write_student_rows(
    sheet: &mut rust_xlsxwriter::Worksheet,
    start_row: u32,
    table: &GradeTableData,
) -> Result<(), rust_xlsxwriter::XlsxError> {
    let (name_col, ww_start, pt_start, qa_start, initial_col, tg_col, remarks_col) =
        calc_col_indices(table);
    let data_fmt = bordered_data_fmt();

    let mut row = start_row;
    for sr in &table.students {
        // Name
        let name = format!("{}. {}", sr.index, sr.student_name);
        sheet.write_with_format(row, name_col as u16, &name, &name_data_fmt())?;

        // Scores
        for (result, section, start) in [
            (&sr.ww, &table.ww, ww_start),
            (&sr.pt, &table.pt, pt_start),
            (&sr.qa, &table.qa, qa_start),
        ] {
            if start < 0 {
                continue;
            }
            for (i, score) in result.scores.iter().enumerate() {
                let text = score.map(|s| format!("{:.1}", s)).unwrap_or_default();
                sheet.write_with_format(row, (start + i as i32) as u16, &text, &data_fmt)?;
            }
            let n = section.items.len() as i32;
            sheet.write_with_format(
                row,
                (start + n) as u16,
                result
                    .total
                    .map(|t| format!("{:.1}", t))
                    .unwrap_or_default(),
                &data_fmt,
            )?;
            sheet.write_with_format(
                row,
                (start + n + 1) as u16,
                result.ps.map(|p| format!("{:.2}", p)).unwrap_or_default(),
                &data_fmt,
            )?;
            sheet.write_with_format(
                row,
                (start + n + 2) as u16,
                result.ws.map(|w| format!("{:.2}", w)).unwrap_or_default(),
                &data_fmt,
            )?;
        }

        // Initial grade
        sheet.write_with_format(
            row,
            initial_col as u16,
            sr.initial_grade
                .map(|v| format!("{:.2}", v))
                .unwrap_or_default(),
            &data_fmt,
        )?;

        // Term grade
        sheet.write_with_format(
            row,
            tg_col as u16,
            sr.transmuted_grade
                .map(|v| v.to_string())
                .unwrap_or_default(),
            &data_fmt,
        )?;

        // REMARKS: Pass / Fail
        let (remarks_text, remarks_fmt) = match sr.transmuted_grade {
            Some(tg) if tg >= 75 => ("PASSED", remarks_pass_fmt()),
            Some(_) => ("FAILED", remarks_fail_fmt()),
            None => ("", bordered_data_fmt()),
        };
        sheet.write_with_format(row, remarks_col as u16, remarks_text, &remarks_fmt)?;

        row += 1;
    }
    Ok(())
}
