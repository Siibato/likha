use printpdf::*;

use crate::modules::document_export::helpers::pdf_engine::PdfEngine;

// ═════════════════════════════════════════════════════════════════════════════
// PAGE DIMENSIONS
// ═════════════════════════════════════════════════════════════════════════════

/// Letter landscape: 11" × 8.5" in mm
pub const PAGE_W: f32 = 279.4;
pub const PAGE_H: f32 = 215.9;

/// Outer page margin (all sides)
pub const MARGIN: f32 = 12.0;

/// Content area bounds
pub const CONTENT_TOP: f32 = PAGE_H - MARGIN;
pub const CONTENT_BOTTOM: f32 = MARGIN;
pub const CONTENT_LEFT: f32 = MARGIN;
pub const CONTENT_RIGHT: f32 = PAGE_W - MARGIN;
pub const CONTENT_WIDTH: f32 = CONTENT_RIGHT - CONTENT_LEFT;
pub const CONTENT_HEIGHT: f32 = CONTENT_TOP - CONTENT_BOTTOM;

// ═════════════════════════════════════════════════════════════════════════════
// CENTER SPLIT
// ═════════════════════════════════════════════════════════════════════════════

/// Page center line
pub const MID: f32 = PAGE_W / 2.0;

/// Gap between left and right columns
pub const CENTER_GAP: f32 = 4.0;

/// Left column bounds
pub const LEFT_COL_LEFT: f32 = CONTENT_LEFT;
pub const LEFT_COL_RIGHT: f32 = MID - CENTER_GAP / 2.0;
pub const LEFT_COL_WIDTH: f32 = LEFT_COL_RIGHT - LEFT_COL_LEFT;
pub const LEFT_COL_CENTER: f32 = LEFT_COL_LEFT + LEFT_COL_WIDTH / 2.0;

/// Right column bounds
pub const RIGHT_COL_LEFT: f32 = MID + CENTER_GAP / 2.0;
pub const RIGHT_COL_RIGHT: f32 = CONTENT_RIGHT;
pub const RIGHT_COL_WIDTH: f32 = RIGHT_COL_RIGHT - RIGHT_COL_LEFT;
pub const RIGHT_COL_CENTER: f32 = RIGHT_COL_LEFT + RIGHT_COL_WIDTH / 2.0;

// ═════════════════════════════════════════════════════════════════════════════
// RIGHT COLUMN INNER CONTENT (DepEd header area)
// ═════════════════════════════════════════════════════════════════════════════

/// Inner margin inside the right column
pub const RIGHT_INNER_MARGIN_LEFT: f32 = 14.0;
pub const RIGHT_INNER_MARGIN_RIGHT: f32 = 12.0;

/// Content area within right column
pub const RIGHT_CONTENT_LEFT: f32 = RIGHT_COL_LEFT + RIGHT_INNER_MARGIN_LEFT;
pub const RIGHT_CONTENT_RIGHT: f32 = RIGHT_COL_RIGHT - RIGHT_INNER_MARGIN_RIGHT;
pub const RIGHT_CONTENT_WIDTH: f32 = RIGHT_CONTENT_RIGHT - RIGHT_CONTENT_LEFT;
pub const RIGHT_CONTENT_CENTER: f32 = RIGHT_CONTENT_LEFT + RIGHT_CONTENT_WIDTH / 2.0;

// ═════════════════════════════════════════════════════════════════════════════
// FONT MEASUREMENT
// ═════════════════════════════════════════════════════════════════════════════

/// Approximate character width factor for Helvetica (width / font_size). Only used as fallback
pub const CHAR_WIDTH_FACTOR: f32 = 0.42;

/// Approximate bold character width factor (slightly wider). Only used as fallback
pub const CHAR_WIDTH_FACTOR_BOLD: f32 = 0.44;

/// Line height multiplier (line spacing / font_size)
pub const LINE_HEIGHT_FACTOR: f32 = 0.45;

/// Wrapped text chars-per-line estimation factor
pub const WRAP_CHAR_FACTOR: f32 = 0.17;

/// Calibration multiplier to correct AFM unit underestimation vs actual render width
pub const TEXT_WIDTH_CALIBRATION: f32 = 0.35;

// ═════════════════════════════════════════════════════════════════════════════
// FONT SIZES
// ═════════════════════════════════════════════════════════════════════════════

pub const FONT_SIZE_XS: f32 = 6.0;
pub const FONT_SIZE_SMALL: f32 = 7.0;
pub const FONT_SIZE_NORMAL: f32 = 8.0;
pub const FONT_SIZE_MEDIUM: f32 = 9.0;
pub const FONT_SIZE_LARGE: f32 = 10.0;
pub const FONT_SIZE_HEADER: f32 = 11.0;
pub const FONT_SIZE_TITLE: f32 = 11.7;
pub const FONT_SIZE_META: f32 = 7.7;

// ═════════════════════════════════════════════════════════════════════════════
// SPACING
// ═════════════════════════════════════════════════════════════════════════════

pub const GAP_TIGHT: f32 = 1.5;
pub const GAP_SMALL: f32 = 3.5;
pub const GAP_NORMAL: f32 = 5.0;
pub const GAP_MEDIUM: f32 = 7.0;
pub const GAP_LARGE: f32 = 9.0;
pub const GAP_XL: f32 = 12.0;
pub const GAP_XXL: f32 = 14.0;

// ═════════════════════════════════════════════════════════════════════════════
// TABLE CONSTANTS
// ═════════════════════════════════════════════════════════════════════════════

pub const TABLE_HEADER_HEIGHT: f32 = 12.0;
pub const TABLE_ROW_HEIGHT: f32 = 12.0;
pub const TABLE_TERM_HEADER_HEIGHT: f32 = 10.0;
pub const CORE_VALUES_ROW_HEIGHT: f32 = 12.0;
pub const CORE_VALUE_LABEL_TOP_PADDING: f32 = 6.0;

// ═════════════════════════════════════════════════════════════════════════════
// BEHAVIOR / CORE VALUES
// ═════════════════════════════════════════════════════════════════════════════

pub const BEHAVIOR_TEXT_PADDING_X: f32 = 1.5;
pub const BEHAVIOR_TEXT_PADDING_TOP: f32 = 4.0;
pub const BEHAVIOR_TEXT_PADDING_RIGHT: f32 = -2.0;
pub const BEHAVIOR_FONT_SIZE: f32 = 8.0;

// ═════════════════════════════════════════════════════════════════════════════
// META / HEADER
// ═════════════════════════════════════════════════════════════════════════════

pub const HEADER_META_FONT_SIZE: f32 = 7.7;
pub const HEADER_META_LINE_GAP: f32 = 4.0;
pub const HEADER_META_CHAR_FACTOR: f32 = 0.18;
pub const HEADER_META_LABEL_PADDING: f32 = 0.1;

// ═════════════════════════════════════════════════════════════════════════════
// TEXT WIDTH CALCULATION
// ═════════════════════════════════════════════════════════════════════════════

fn helvetica_units_regular(ch: char) -> f32 {
    match ch {
        ' ' => 278.0,
        '!' => 278.0,
        '"' => 355.0,
        '#' => 556.0,
        '$' => 556.0,
        '%' => 889.0,
        '&' => 667.0,
        '\'' => 238.0,
        '(' | ')' => 333.0,
        '*' => 389.0,
        '+' => 584.0,
        ',' | '.' => 278.0,
        '-' => 333.0,
        '/' => 278.0,
        '0'..='9' => 556.0,
        ':' | ';' => 278.0,
        '<' | '>' => 584.0,
        '=' => 584.0,
        '?' => 556.0,
        '@' => 1015.0,
        'A' => 667.0,
        'B' => 667.0,
        'C' => 722.0,
        'D' => 722.0,
        'E' => 667.0,
        'F' => 611.0,
        'G' => 778.0,
        'H' => 722.0,
        'I' => 278.0,
        'J' => 556.0,
        'K' => 667.0,
        'L' => 556.0,
        'M' => 833.0,
        'N' => 722.0,
        'O' => 778.0,
        'P' => 667.0,
        'Q' => 778.0,
        'R' => 722.0,
        'S' => 667.0,
        'T' => 611.0,
        'U' => 722.0,
        'V' => 667.0,
        'W' => 944.0,
        'X' => 667.0,
        'Y' => 667.0,
        'Z' => 611.0,
        '[' | ']' => 278.0,
        '^' => 469.0,
        '_' => 556.0,
        '`' => 333.0,
        'a' => 556.0,
        'b' => 556.0,
        'c' => 500.0,
        'd' => 556.0,
        'e' => 556.0,
        'f' => 278.0,
        'g' => 556.0,
        'h' => 556.0,
        'i' => 222.0,
        'j' => 222.0,
        'k' => 500.0,
        'l' => 222.0,
        'm' => 833.0,
        'n' => 556.0,
        'o' => 556.0,
        'p' => 556.0,
        'q' => 556.0,
        'r' => 333.0,
        's' => 500.0,
        't' => 278.0,
        'u' => 556.0,
        'v' => 500.0,
        'w' => 722.0,
        'x' => 500.0,
        'y' => 500.0,
        'z' => 500.0,
        '{' | '}' => 334.0,
        '|' => 260.0,
        '~' => 584.0,
        '\n' | '\r' => 0.0,
        _ => 600.0,
    }
}

fn helvetica_units_bold(ch: char) -> f32 {
    helvetica_units_regular(ch) * 1.03
}

fn precise_text_width(text: &str, font_size: f32, bold: bool) -> f32 {
    let scale = font_size / 1000.0;
    let raw: f32 = text
        .chars()
        .map(|ch| {
            let units = if bold {
                helvetica_units_bold(ch)
            } else {
                helvetica_units_regular(ch)
            };
            (units * scale).max(0.0)
        })
        .sum();
    raw * TEXT_WIDTH_CALIBRATION
}

/// Calculate approximate text width for regular text.
pub fn text_width(text: &str, font_size: f32) -> f32 {
    let width = precise_text_width(text, font_size, false);
    if width > 0.0 {
        width
    } else {
        text.len() as f32 * font_size * CHAR_WIDTH_FACTOR
    }
}

/// Calculate approximate text width for bold text.
pub fn text_width_bold(text: &str, font_size: f32) -> f32 {
    let width = precise_text_width(text, font_size, true);
    if width > 0.0 {
        width
    } else {
        text.len() as f32 * font_size * CHAR_WIDTH_FACTOR_BOLD
    }
}

/// Calculate X position to center `text` inside a container.
pub fn center_x(text: &str, font_size: f32, container_left: f32, container_width: f32) -> f32 {
    container_left + container_width / 2.0 - text_width(text, font_size) / 2.0
}

/// Center text within the right column's inner content area.
pub fn center_x_in_right_content(text: &str, font_size: f32) -> f32 {
    center_x(text, font_size, RIGHT_CONTENT_LEFT, RIGHT_CONTENT_WIDTH)
}

/// Center text within the full right column.
pub fn center_x_in_right_col(text: &str, font_size: f32) -> f32 {
    center_x(text, font_size, RIGHT_COL_LEFT, RIGHT_COL_WIDTH)
}

/// Center text within the left column.
pub fn center_x_in_left_col(text: &str, font_size: f32) -> f32 {
    center_x(text, font_size, LEFT_COL_LEFT, LEFT_COL_WIDTH)
}

/// Calculate X position to right-align `text` ending at `container_right`.
pub fn right_align_x(text: &str, font_size: f32, container_right: f32) -> f32 {
    container_right - text_width(text, font_size)
}

/// Calculate line height for a given font size.
pub fn line_height(font_size: f32) -> f32 {
    font_size * LINE_HEIGHT_FACTOR
}

// ═════════════════════════════════════════════════════════════════════════════
// DRAWING HELPERS
// ═════════════════════════════════════════════════════════════════════════════

/// Draw a vertical line (stroke only).
pub fn draw_vertical_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y_bottom: f32,
    y_top: f32,
    thickness: f32,
) {
    engine.draw_rect(
        layer,
        Mm(x),
        Mm(y_bottom),
        Mm(thickness),
        Mm(y_top - y_bottom),
        None,
        true,
    );
}

/// Draw a horizontal line (stroke only).
pub fn draw_horizontal_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    width: f32,
    thickness: f32,
) {
    engine.draw_rect(layer, Mm(x), Mm(y), Mm(width), Mm(thickness), None, true);
}

/// Draw the center split line from top to bottom of the content area.
pub fn draw_center_split_line(engine: &PdfEngine, layer: &PdfLayerReference, thickness: f32) {
    draw_vertical_line(engine, layer, MID, CONTENT_BOTTOM, CONTENT_TOP, thickness);
}

/// Draw an underline below text.
pub fn draw_underline(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    width: f32,
    thickness: f32,
) {
    draw_horizontal_line(engine, layer, x, y, width, thickness);
}

/// Draw a label followed by an underlined value field.
pub fn draw_field_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    label: &str,
    value: &str,
    x: f32,
    y: f32,
    total_w: f32,
    font_size: f32,
    bold_label: bool,
) {
    let label_w = if bold_label {
        text_width_bold(label, font_size) + HEADER_META_LABEL_PADDING
    } else {
        text_width(label, font_size) + HEADER_META_LABEL_PADDING
    };
    engine.draw_text(layer, label, font_size, Mm(x), Mm(y), bold_label);
    let line_x = x + label_w;
    let line_w = total_w - label_w + 5.0;
    if line_w > 0.0 {
        draw_underline(engine, layer, line_x, y - 1.0, line_w, 0.15);
    }
    if !value.is_empty() {
        engine.draw_text(layer, value, font_size, Mm(line_x + 1.0), Mm(y), false);
    }
}

/// Draw centered text inside a container.
pub fn draw_centered_text(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    font_size: f32,
    container_left: f32,
    container_width: f32,
    y: f32,
    bold: bool,
) {
    let x = center_x(text, font_size, container_left, container_width);
    engine.draw_text(layer, text, font_size, Mm(x), Mm(y), bold);
}

/// Draw centered text inside the right column's inner content area.
pub fn draw_centered_text_in_right_content(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    font_size: f32,
    y: f32,
    bold: bool,
) {
    draw_centered_text(
        engine,
        layer,
        text,
        font_size,
        RIGHT_CONTENT_LEFT,
        RIGHT_CONTENT_WIDTH,
        y,
        bold,
    );
}

/// Draw centered text across the full right column (edge-to-edge of the page split).
pub fn draw_centered_text_in_right_col(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    font_size: f32,
    y: f32,
    bold: bool,
) {
    draw_centered_text(
        engine,
        layer,
        text,
        font_size,
        RIGHT_COL_LEFT,
        RIGHT_COL_WIDTH,
        y,
        bold,
    );
}

/// Draw wrapped text within a max width. Returns the Y position after the last line.
pub fn draw_wrapped_text(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    text: &str,
    x: f32,
    y: f32,
    max_width: f32,
    font_size: f32,
) -> f32 {
    let chars_per_line = (max_width / (font_size * WRAP_CHAR_FACTOR)).max(1.0) as usize;
    let mut current_y = y;
    let lh = line_height(font_size);
    let words: Vec<&str> = text.split_whitespace().collect();
    let mut line = String::new();

    for word in words {
        if !line.is_empty() && line.len() + word.len() + 1 > chars_per_line {
            engine.draw_text(layer, &line, font_size, Mm(x), Mm(current_y), false);
            current_y -= lh;
            line = word.to_string();
        } else {
            if !line.is_empty() {
                line.push(' ');
            }
            line.push_str(word);
        }
    }
    if !line.is_empty() {
        engine.draw_text(layer, &line, font_size, Mm(x), Mm(current_y), false);
        current_y -= lh;
    }
    current_y
}

/// Draw a signature block: name centered above a line, title centered below.
pub fn draw_sig_block(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    w: f32,
    name: &str,
    title: &str,
    name_font_size: f32,
    title_font_size: f32,
) {
    if !name.is_empty() {
        let name_w = text_width(name, name_font_size);
        engine.draw_text(
            layer,
            name,
            name_font_size,
            Mm(x + (w - name_w).max(0.0) / 2.0),
            Mm(y),
            false,
        );
    }
    draw_underline(engine, layer, x, y - 1.5, w, 0.15);
    let title_w = text_width(title, title_font_size);
    engine.draw_text(
        layer,
        title,
        title_font_size,
        Mm(x + (w - title_w).max(0.0) / 2.0),
        Mm(y - 6.0),
        false,
    );
}
