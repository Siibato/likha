use rust_xlsxwriter::{Color, Format, FormatAlign, FormatBorder};

// ─────────────────────────────────────────────────────────────────────────────
// Column widths
// ─────────────────────────────────────────────────────────────────────────────

/// Total number of columns used by the template for each classification mode.
/// Bloom's: Topic, Competencies, Time, Weight, 6 levels, Actual, Adjusted = 12
/// Difficulty: Topic, Competencies, Time, Weight, 3 levels, Actual, Adjusted = 9
pub fn total_columns(is_blooms: bool) -> u16 {
    if is_blooms {
        12
    } else {
        9
    }
}

pub fn set_column_widths(sheet: &mut rust_xlsxwriter::Worksheet, is_blooms: bool) {
    sheet.set_column_width(0, 9.0).unwrap(); // Topic
    sheet.set_column_width(1, 32.0).unwrap(); // Competencies
    sheet.set_column_width(2, 11.0).unwrap(); // Time Spent/Frequency
    sheet.set_column_width(3, 9.0).unwrap(); // Weight %

    if is_blooms {
        for i in 4..10 {
            sheet.set_column_width(i, 11.0).unwrap(); // Bloom's levels
        }
        sheet.set_column_width(10, 9.0).unwrap(); // Actual
        sheet.set_column_width(11, 9.0).unwrap(); // Adjusted
    } else {
        for i in 4..7 {
            sheet.set_column_width(i, 11.0).unwrap(); // Difficulty levels
        }
        sheet.set_column_width(7, 9.0).unwrap(); // Actual
        sheet.set_column_width(8, 9.0).unwrap(); // Adjusted
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared format helpers
// ─────────────────────────────────────────────────────────────────────────────

pub fn tbl_header_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(8)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
        .set_background_color(Color::RGB(0xD9D9D9))
        .set_text_wrap()
}

pub fn cell_fmt() -> Format {
    Format::new()
        .set_font_size(9)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
}

pub fn left_cell_fmt() -> Format {
    Format::new()
        .set_font_size(9)
        .set_align(FormatAlign::Left)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
        .set_text_wrap()
}

pub fn total_row_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(9)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
        .set_background_color(Color::RGB(0xD9D9D9))
}

// ─────────────────────────────────────────────────────────────────────────────
// Document header / footer formats (match the printed template)
// ─────────────────────────────────────────────────────────────────────────────

pub fn division_fmt() -> Format {
    Format::new()
        .set_font_size(11)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}

pub fn school_name_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(12)
        .set_underline(rust_xlsxwriter::FormatUnderline::Single)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}

pub fn address_fmt() -> Format {
    Format::new()
        .set_font_size(10)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}

pub fn doc_title_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(14)
        .set_font_color(Color::RGB(0x1F1FA0))
        .set_underline(rust_xlsxwriter::FormatUnderline::Single)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}

pub fn band_label_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(10)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}

pub fn band_value_fmt() -> Format {
    Format::new()
        .set_font_size(10)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border_bottom(FormatBorder::Thin)
}

pub fn legend_fmt() -> Format {
    Format::new()
        .set_font_size(9)
        .set_align(FormatAlign::Left)
        .set_align(FormatAlign::VerticalCenter)
}

pub fn footer_label_fmt() -> Format {
    Format::new()
        .set_font_size(10)
        .set_align(FormatAlign::Right)
        .set_align(FormatAlign::VerticalCenter)
}

pub fn footer_line_fmt() -> Format {
    Format::new()
        .set_font_size(10)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border_bottom(FormatBorder::Thin)
}

pub fn footer_caption_fmt() -> Format {
    Format::new()
        .set_font_size(9)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}

/// Splits `total_cols` into 4 contiguous bands (for the SUBJECT/GRADE/
/// GRADING PERIOD/SCHOOL YEAR label row), returning (start, end) inclusive.
pub fn four_bands(total_cols: u16) -> Vec<(u16, u16)> {
    let base = total_cols / 4;
    let extra = total_cols % 4;
    let mut bands = Vec::with_capacity(4);
    let mut start = 0u16;
    for i in 0..4u16 {
        let width = base + if i < extra { 1 } else { 0 };
        let end = start + width - 1;
        bands.push((start, end));
        start = end + 1;
    }
    bands
}
