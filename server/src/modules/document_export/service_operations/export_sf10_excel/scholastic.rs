use rust_xlsxwriter::Worksheet;

use crate::modules::student_records::schema::Sf10YearRecord;
use crate::utils::AppResult;

use super::layout::{
    field_text, Formats, SemesterLayout, ACTION_COL_END, ACTION_COL_START, FINAL_COL, FULL_WIDTH_END,
    QUARTER_COL_END, QUARTER_COL_START, SUBJECT_COL_END, SUBJECT_COL_START, TYPE_COL_END,
    TYPE_COL_START,
};
use super::{action_taken, excel_err, grade_for_indices, resolve_school_name, Sf10ExcelContext};

const MIN_SUBJECT_ROWS: usize = 12;

pub fn write_semester_block(
    sheet: &mut Worksheet,
    start_row: u32,
    ctx: &Sf10ExcelContext<'_>,
    record: &Sf10YearRecord,
    semester: &SemesterLayout,
    formats: &Formats,
) -> AppResult<u32> {
    let mut row = start_row;

    sheet
        .merge_range(row, 0, row, FULL_WIDTH_END, "SCHOLASTIC RECORD", &formats.section_bar)
        .map_err(excel_err)?;
    row += 1;

    row = write_context_row(
        sheet,
        row,
        &[
            ("SCHOOL", resolve_school_name(record, ctx), 0, 10),
            ("SCHOOL ID", ctx.settings.school_code.clone(), 11, 13),
            ("GRADE LEVEL", record.grade_level.clone(), 14, 15),
            ("SY", record.school_year.clone(), 16, 18),
            ("TERM", semester.sem_no.to_string(), 19, FULL_WIDTH_END),
        ],
        formats,
    )?;

    row = write_context_row(
        sheet,
        row,
        &[
            (
                "TRACK/STRAND",
                ctx.sf10.track_strand.clone().unwrap_or_default(),
                0,
                10,
            ),
            (
                "SECTION",
                record
                    .section
                    .clone()
                    .unwrap_or_else(|| ctx.sf10.current_section.clone().unwrap_or_default()),
                11,
                FULL_WIDTH_END,
            ),
        ],
        formats,
    )?;

    row = write_table_header(sheet, row, semester, formats)?;

    let mut collected_grades = Vec::new();
    let mut rows_written = 0usize;

    for subject in &record.subjects {
        let q1 = subject
            .term_grades
            .get(semester.quarter_indices[0])
            .and_then(|g| *g);
        let q2 = subject
            .term_grades
            .get(semester.quarter_indices[1])
            .and_then(|g| *g);
        let final_grade = grade_for_indices(subject, &semester.quarter_indices);
        if let Some(grade) = final_grade {
            collected_grades.push(grade);
        }

        let subject_type = title_case(
            &subject
                .subject_group
                .clone()
                .unwrap_or_else(|| "Core".to_string()),
        );

        sheet
            .merge_range(
                row,
                TYPE_COL_START,
                row,
                TYPE_COL_END,
                subject_type.as_str(),
                &formats.table_cell_center,
            )
            .map_err(excel_err)?;
        sheet
            .merge_range(
                row,
                SUBJECT_COL_START,
                row,
                SUBJECT_COL_END,
                subject.class_title.as_str(),
                &formats.table_cell_left,
            )
            .map_err(excel_err)?;

        write_grade_cell(sheet, row, QUARTER_COL_START, q1, formats)?;
        write_grade_cell(sheet, row, QUARTER_COL_END, q2, formats)?;
        write_grade_cell(sheet, row, FINAL_COL, final_grade, formats)?;

        let action = action_taken(final_grade).unwrap_or("");
        sheet
            .merge_range(row, ACTION_COL_START, row, ACTION_COL_END, action, &formats.table_cell_center)
            .map_err(excel_err)?;

        row += 1;
        rows_written += 1;
    }

    // Pad with empty rows so the table keeps the official fixed height.
    while rows_written < MIN_SUBJECT_ROWS {
        row = write_blank_subject_row(sheet, row, formats)?;
        rows_written += 1;
    }

    let general_avg = if collected_grades.is_empty() {
        None
    } else {
        let sum: i32 = collected_grades.iter().sum();
        Some((sum as f64 / collected_grades.len() as f64).round() as i32)
    };

    sheet
        .merge_range(
            row,
            TYPE_COL_START,
            row,
            FINAL_COL - 1,
            "General Ave. for the Semester:",
            &formats.table_cell_left,
        )
        .map_err(excel_err)?;
    write_grade_cell(sheet, row, FINAL_COL, general_avg, formats)?;
    let action = action_taken(general_avg).unwrap_or("");
    sheet
        .merge_range(row, ACTION_COL_START, row, ACTION_COL_END, action, &formats.table_cell_center)
        .map_err(excel_err)?;
    row += 1;

    Ok(row)
}

fn title_case(value: &str) -> String {
    value
        .split_whitespace()
        .map(|word| {
            let mut chars = word.chars();
            match chars.next() {
                Some(first) => {
                    first.to_uppercase().collect::<String>() + &chars.as_str().to_lowercase()
                }
                None => String::new(),
            }
        })
        .collect::<Vec<_>>()
        .join(" ")
}

fn write_blank_subject_row(
    sheet: &mut Worksheet,
    row: u32,
    formats: &Formats,
) -> AppResult<u32> {
    sheet
        .merge_range(row, TYPE_COL_START, row, TYPE_COL_END, "", &formats.table_cell_center)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, SUBJECT_COL_START, row, SUBJECT_COL_END, "", &formats.table_cell_left)
        .map_err(excel_err)?;
    write_grade_cell(sheet, row, QUARTER_COL_START, None, formats)?;
    write_grade_cell(sheet, row, QUARTER_COL_END, None, formats)?;
    write_grade_cell(sheet, row, FINAL_COL, None, formats)?;
    sheet
        .merge_range(row, ACTION_COL_START, row, ACTION_COL_END, "", &formats.table_cell_center)
        .map_err(excel_err)?;
    Ok(row + 1)
}

fn write_context_row(
    sheet: &mut Worksheet,
    start_row: u32,
    segments: &[(&str, String, u16, u16)],
    formats: &Formats,
) -> AppResult<u32> {
    let row = start_row;
    sheet.set_row_height(row, 16.0).ok();
    for (label, value, start, end) in segments {
        sheet
            .merge_range(
                row,
                *start,
                row,
                *end,
                field_text(label, value).as_str(),
                &formats.field,
            )
            .map_err(excel_err)?;
    }
    Ok(row + 1)
}

fn write_table_header(
    sheet: &mut Worksheet,
    start_row: u32,
    semester: &SemesterLayout,
    formats: &Formats,
) -> AppResult<u32> {
    let mut row = start_row;

    sheet
        .merge_range(
            row,
            TYPE_COL_START,
            row + 1,
            TYPE_COL_END,
            "Indicate if Subject is CORE, APPLIED, or SPECIALIZED",
            &formats.table_header,
        )
        .map_err(excel_err)?;
    sheet
        .merge_range(row, SUBJECT_COL_START, row + 1, SUBJECT_COL_END, "SUBJECTS", &formats.table_header)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, QUARTER_COL_START, row, QUARTER_COL_END, "Quarter", &formats.table_header)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, FINAL_COL, row + 1, FINAL_COL, "TERM FINAL GRADE", &formats.table_header)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, ACTION_COL_START, row + 1, ACTION_COL_END, "ACTION TAKEN", &formats.table_header)
        .map_err(excel_err)?;

    row += 1;
    sheet
        .write_with_format(row, QUARTER_COL_START, semester.quarter_headers[0], &formats.table_header)
        .map_err(excel_err)?;
    sheet
        .write_with_format(row, QUARTER_COL_END, semester.quarter_headers[1], &formats.table_header)
        .map_err(excel_err)?;

    row += 1;
    Ok(row)
}

fn write_grade_cell(
    sheet: &mut Worksheet,
    row: u32,
    col: u16,
    grade: Option<i32>,
    formats: &Formats,
) -> AppResult<()> {
    let value = grade.map(|g| g.to_string()).unwrap_or_else(|| "".to_string());
    sheet
        .write_with_format(row, col, value, &formats.table_cell_center)
        .map_err(excel_err)?;
    Ok(())
}
