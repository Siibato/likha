use rust_xlsxwriter::{Color, Format, FormatAlign, FormatBorder, Worksheet};

pub const TOTAL_COLS: u16 = 22;
pub const FULL_WIDTH_END: u16 = TOTAL_COLS - 1;
pub const TYPE_COL_START: u16 = 0;
pub const TYPE_COL_END: u16 = 2;
pub const SUBJECT_COL_START: u16 = 3;
pub const SUBJECT_COL_END: u16 = 15;
pub const QUARTER_COL_START: u16 = 16;
pub const QUARTER_COL_END: u16 = 17;
pub const FINAL_COL: u16 = 18;
pub const ACTION_COL_START: u16 = 19;
pub const ACTION_COL_END: u16 = 21;

const COLUMN_WIDTHS: [f64; TOTAL_COLS as usize] = [
    4.0, 4.0, 4.0, 6.8, 6.8, 6.8, 6.8, 6.8, 6.8, 6.8, 6.8, 6.8,
    6.8, 6.8, 6.8, 6.8, 4.2, 4.2, 5.4, 6.0, 6.0, 6.0,
];

pub fn apply_column_widths(sheet: &mut Worksheet) {
    for (idx, width) in COLUMN_WIDTHS.iter().enumerate() {
        let _ = sheet.set_column_width(idx as u16, *width);
    }
}

/// Builds an inline "LABEL:  value" string used for underlined form fields.
pub fn field_text(label: &str, value: &str) -> String {
    if value.trim().is_empty() {
        format!("{}:  ", label)
    } else {
        format!("{}:  {}", label, value)
    }
}

#[derive(Clone, Copy)]
pub struct SemesterLayout {
    pub sem_no: &'static str,
    pub quarter_headers: [&'static str; 2],
    pub quarter_indices: [usize; 2],
}

pub const SEMESTERS: [SemesterLayout; 2] = [
    SemesterLayout {
        sem_no: "1ST",
        quarter_headers: ["1ST", "2ND"],
        quarter_indices: [0, 1],
    },
    SemesterLayout {
        sem_no: "2ND",
        quarter_headers: ["3RD", "4TH"],
        quarter_indices: [2, 3],
    },
];

const GRAY_BAR: Color = Color::RGB(0xBFBFBF);
const GRAY_HEADER: Color = Color::RGB(0xD9D9D9);

pub struct Formats {
    pub banner_org: Format,
    pub banner_title: Format,
    pub sf10_code: Format,
    pub section_bar: Format,
    pub field: Format,
    pub checkbox: Format,
    pub footnote: Format,
    pub table_header: Format,
    pub table_cell_left: Format,
    pub table_cell_center: Format,
    pub sig_label: Format,
    pub sig_name: Format,
    pub sig_caption: Format,
}

impl Formats {
    pub fn new() -> Self {
        Self {
            banner_org: build_banner_org(),
            banner_title: build_banner_title(),
            sf10_code: build_sf10_code(),
            section_bar: build_section_bar(),
            field: build_field(),
            checkbox: build_checkbox(),
            footnote: build_footnote(),
            table_header: build_table_header(),
            table_cell_left: build_table_cell_left(),
            table_cell_center: build_table_cell_center(),
            sig_label: build_sig_label(),
            sig_name: build_sig_name(),
            sig_caption: build_sig_caption(),
        }
    }
}

fn build_banner_org() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(10.5)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}

fn build_banner_title() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(13.0)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}

fn build_sf10_code() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(9.0)
        .set_align(FormatAlign::Right)
        .set_align(FormatAlign::VerticalCenter)
}

fn build_section_bar() -> Format {
    Format::new()
        .set_bold()
        .set_font_color(Color::RGB(0x000000))
        .set_background_color(GRAY_BAR)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
        .set_font_size(9.0)
}

fn build_field() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(8.0)
        .set_align(FormatAlign::Left)
        .set_align(FormatAlign::VerticalCenter)
        .set_border_bottom(FormatBorder::Thin)
}

fn build_checkbox() -> Format {
    Format::new()
        .set_font_size(9.0)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
}

fn build_footnote() -> Format {
    Format::new()
        .set_italic()
        .set_font_size(6.5)
        .set_align(FormatAlign::Left)
        .set_align(FormatAlign::VerticalCenter)
}

fn build_table_header() -> Format {
    Format::new()
        .set_bold()
        .set_font_color(Color::RGB(0x000000))
        .set_background_color(GRAY_HEADER)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
        .set_text_wrap()
        .set_font_size(8.0)
}

fn build_table_cell_left() -> Format {
    Format::new()
        .set_font_size(8.5)
        .set_align(FormatAlign::Left)
        .set_align(FormatAlign::VerticalCenter)
        .set_border(FormatBorder::Thin)
        .set_text_wrap()
}

fn build_table_cell_center() -> Format {
    build_table_cell_left().set_align(FormatAlign::Center)
}

fn build_sig_label() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(8.5)
        .set_align(FormatAlign::Left)
        .set_align(FormatAlign::VerticalCenter)
}

fn build_sig_name() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(8.5)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_border_bottom(FormatBorder::Thin)
}

fn build_sig_caption() -> Format {
    Format::new()
        .set_font_size(7.5)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
}
