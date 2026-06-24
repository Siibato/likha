use std::path::PathBuf;

use rust_xlsxwriter::{Image, Worksheet};

use crate::utils::AppResult;

use super::layout::{Formats, FULL_WIDTH_END, TOTAL_COLS};
use super::{excel_err, Sf10ExcelContext};

pub fn write(
    sheet: &mut Worksheet,
    start_row: u32,
    _ctx: &Sf10ExcelContext<'_>,
    formats: &Formats,
) -> AppResult<u32> {
    let mut row = start_row;

    insert_logos(sheet, row);

    // Row 1: "REPUBLIC OF THE PHILIPPINES" centered, with "SF 10-SHS" on the right.
    sheet.set_row_height(row, 18.0).ok();
    sheet
        .merge_range(row, 3, row, 18, "REPUBLIC OF THE PHILIPPINES", &formats.banner_org)
        .map_err(excel_err)?;
    sheet
        .merge_range(row, 19, row, FULL_WIDTH_END, "SF 10-SHS", &formats.sf10_code)
        .map_err(excel_err)?;
    row += 1;

    // Row 2: "DEPARTMENT OF EDUCATION" centered.
    sheet.set_row_height(row, 18.0).ok();
    sheet
        .merge_range(row, 3, row, 18, "DEPARTMENT OF EDUCATION", &formats.banner_org)
        .map_err(excel_err)?;
    row += 1;

    // Spacer row.
    row += 1;

    // Title row centered full width.
    sheet.set_row_height(row, 24.0).ok();
    sheet
        .merge_range(
            row,
            0,
            row,
            FULL_WIDTH_END,
            "SENIOR HIGH SCHOOL STUDENT PERMANENT RECORD",
            &formats.banner_title,
        )
        .map_err(excel_err)?;
    row += 1;

    Ok(row)
}

fn insert_logos(sheet: &mut Worksheet, row: u32) {
    let base = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("assets/images");
    let seal_path = base.join("deped_seal.png");
    if let Ok(img) = Image::new(&seal_path) {
        let img = img.set_scale_to_size(90, 90, true);
        let _ = sheet.insert_image_with_offset(row, 0, &img, 2, 0);
    }

    let logo_path = base.join("deped_logo.png");
    if let Ok(img) = Image::new(&logo_path) {
        let img = img.set_scale_to_size(110, 60, true);
        let col = TOTAL_COLS.saturating_sub(4);
        let _ = sheet.insert_image_with_offset(row, col, &img, 0, 0);
    }
}
