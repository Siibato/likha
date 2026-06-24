use rust_xlsxwriter::Worksheet;

use crate::utils::AppResult;

use super::layout::{field_text, Formats, FULL_WIDTH_END};
use super::{excel_err, Sf10ExcelContext};

pub fn write(
    sheet: &mut Worksheet,
    start_row: u32,
    _ctx: &Sf10ExcelContext<'_>,
    formats: &Formats,
) -> AppResult<u32> {
    let mut row = start_row;

    sheet
        .merge_range(
            row,
            0,
            row,
            FULL_WIDTH_END,
            "ELIGIBILITY FOR SHS ENROLMENT",
            &formats.section_bar,
        )
        .map_err(excel_err)?;
    row += 1;

    // Row A: completer checkboxes + general averages.
    sheet.set_row_height(row, 16.0).ok();
    checkbox(sheet, row, 0, formats)?;
    label(sheet, row, 1, 5, "High School Completer*", formats)?;
    field(sheet, row, 6, 9, "Gen. Ave", "", formats)?;
    checkbox(sheet, row, 10, formats)?;
    label(sheet, row, 11, 16, "Junior High School Completer", formats)?;
    field(sheet, row, 17, FULL_WIDTH_END, "Gen. Ave", "", formats)?;
    row += 1;

    // Row B: graduation date, school name, school address.
    sheet.set_row_height(row, 16.0).ok();
    field(sheet, row, 0, 6, "Date of Graduation/Completion (MM/DD/YYYY)", "", formats)?;
    field(sheet, row, 7, 13, "Name of School", "", formats)?;
    field(sheet, row, 14, FULL_WIDTH_END, "School Address", "", formats)?;
    row += 1;

    // Row C: PEPT / ALS A&E / Others.
    sheet.set_row_height(row, 16.0).ok();
    checkbox(sheet, row, 0, formats)?;
    label(sheet, row, 1, 4, "PEPT Passer**", formats)?;
    field(sheet, row, 5, 8, "Rating", "", formats)?;
    checkbox(sheet, row, 9, formats)?;
    label(sheet, row, 10, 13, "ALS A&E Passer***", formats)?;
    field(sheet, row, 14, 16, "Rating", "", formats)?;
    checkbox(sheet, row, 17, formats)?;
    field(sheet, row, 18, FULL_WIDTH_END, "Others (Pls. Specify)", "", formats)?;
    row += 1;

    // Row D: examination date + community learning center.
    sheet.set_row_height(row, 16.0).ok();
    field(sheet, row, 0, 7, "Date of Examination/Assessment (MM/DD/YYYY)", "", formats)?;
    field(
        sheet,
        row,
        8,
        FULL_WIDTH_END,
        "Name and Address of Community Learning Center",
        "",
        formats,
    )?;
    row += 1;

    // Footnotes.
    sheet
        .merge_range(
            row,
            0,
            row,
            FULL_WIDTH_END,
            "*High School Completers are students who graduated from secondary school under the old curriculum          ***ALS A&E - Alternative Learning System Accreditation and Equivalency Test for JHS",
            &formats.footnote,
        )
        .map_err(excel_err)?;
    row += 1;
    sheet
        .merge_range(
            row,
            0,
            row,
            FULL_WIDTH_END,
            "**PEPT - Philippine Educational Placement Test for JHS",
            &formats.footnote,
        )
        .map_err(excel_err)?;
    row += 1;

    Ok(row)
}

fn checkbox(sheet: &mut Worksheet, row: u32, col: u16, formats: &Formats) -> AppResult<()> {
    sheet
        .write_with_format(row, col, "", &formats.checkbox)
        .map_err(excel_err)?;
    Ok(())
}

fn label(
    sheet: &mut Worksheet,
    row: u32,
    start: u16,
    end: u16,
    text: &str,
    formats: &Formats,
) -> AppResult<()> {
    sheet
        .merge_range(row, start, row, end, text, &formats.sig_label)
        .map_err(excel_err)?;
    Ok(())
}

fn field(
    sheet: &mut Worksheet,
    row: u32,
    start: u16,
    end: u16,
    label: &str,
    value: &str,
    formats: &Formats,
) -> AppResult<()> {
    sheet
        .merge_range(
            row,
            start,
            row,
            end,
            field_text(label, value).as_str(),
            &formats.field,
        )
        .map_err(excel_err)?;
    Ok(())
}
