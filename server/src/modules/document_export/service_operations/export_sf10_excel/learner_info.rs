use rust_xlsxwriter::Worksheet;

use crate::utils::AppResult;

use super::layout::{field_text, Formats, FULL_WIDTH_END};
use super::{excel_err, format_date, split_name, Sf10ExcelContext};

pub fn write(
    sheet: &mut Worksheet,
    start_row: u32,
    ctx: &Sf10ExcelContext<'_>,
    formats: &Formats,
) -> AppResult<u32> {
    let mut row = start_row;

    sheet
        .merge_range(row, 0, row, FULL_WIDTH_END, "LEARNER'S INFORMATION", &formats.section_bar)
        .map_err(excel_err)?;
    row += 1;

    let names = split_name(&ctx.sf10.student_name);

    // Row 1: LAST NAME / FIRST NAME / MIDDLE NAME
    write_fields(
        sheet,
        row,
        &[
            ("LAST NAME", names.last, 0, 6),
            ("FIRST NAME", names.first, 7, 13),
            ("MIDDLE NAME", names.middle, 14, FULL_WIDTH_END),
        ],
        formats,
    )?;
    row += 1;

    // Row 2: LRN / DATE OF BIRTH / SEX / DATE OF SHS ADMISSION
    write_fields(
        sheet,
        row,
        &[
            ("LRN", ctx.sf10.lrn.clone().unwrap_or_default(), 0, 6),
            (
                "Date of Birth (MM/DD/YYYY)",
                format_date(ctx.sf10.birthdate.as_ref()),
                7,
                12,
            ),
            (
                "Sex",
                ctx.sf10.sex.clone().unwrap_or_default(),
                13,
                15,
            ),
            (
                "Date of SHS Admission (MM/DD/YYYY)",
                String::new(),
                16,
                FULL_WIDTH_END,
            ),
        ],
        formats,
    )?;
    row += 1;

    Ok(row)
}

fn write_fields(
    sheet: &mut Worksheet,
    row: u32,
    fields: &[(&str, String, u16, u16)],
    formats: &Formats,
) -> AppResult<()> {
    sheet.set_row_height(row, 16.0).ok();
    for (label, value, start, end) in fields {
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
    Ok(())
}
