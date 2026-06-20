use rust_xlsxwriter::{Workbook, Worksheet, Format, FormatAlign, FormatBorder, Color};

pub struct ExcelEngine {
    pub workbook: Workbook,
}

impl ExcelEngine {
    pub fn new() -> Self {
        let mut workbook = Workbook::new();
        let sheet = workbook.add_worksheet();
        sheet.set_name("Class Record").ok();
        Self { workbook }
    }

    pub fn worksheet(&mut self) -> &mut Worksheet {
        self.workbook.worksheet_from_index(0).expect("worksheet exists")
    }

    pub fn save(mut self) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
        Ok(self.workbook.save_to_buffer()?)
    }
}

pub fn header_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(8)
        .set_align(FormatAlign::Center)
        .set_align(FormatAlign::VerticalCenter)
        .set_background_color(Color::RGB(0xD9D9D9))
        .set_border(FormatBorder::Thin)
}

pub fn data_fmt() -> Format {
    Format::new()
        .set_font_size(8)
        .set_align(FormatAlign::Center)
        .set_border(FormatBorder::Thin)
}

pub fn yellow_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(8)
        .set_align(FormatAlign::Center)
        .set_background_color(Color::RGB(0xFFFF99))
        .set_border(FormatBorder::Thin)
}

pub fn label_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(7)
}

pub fn underline_fmt() -> Format {
    Format::new()
        .set_font_size(8)
        .set_underline(rust_xlsxwriter::FormatUnderline::Single)
}

pub fn title_fmt() -> Format {
    Format::new()
        .set_bold()
        .set_font_size(16)
        .set_align(FormatAlign::Center)
}

pub fn subtitle_fmt() -> Format {
    Format::new()
        .set_font_size(8)
        .set_align(FormatAlign::Center)
}

pub fn bordered_data_fmt() -> Format {
    Format::new()
        .set_font_size(8)
        .set_align(FormatAlign::Center)
        .set_border(FormatBorder::Thin)
}
