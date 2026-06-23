use printpdf::*;

use crate::modules::document_export::helpers::pdf_engine::PdfEngine;
use crate::modules::grading::schema::Sf9Response;

use super::layout::*;

pub fn draw_page1_right(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    sf9: &Sf9Response,
    school_name: &str,
    region: &str,
    division: &str,
    district: &str,
    school_year: &str,
    school_head_name: &str,
    seal: Option<Image>,
) {
    let mut y = CONTENT_TOP - GAP_NORMAL;

    // ── DepEd Seal ──
    if let Some(img) = seal {
        let seal_x = RIGHT_CONTENT_LEFT - 6.0;
        let seal_y = CONTENT_TOP - 18.0;
        img.add_to_layer(
            layer.clone(),
            ImageTransform {
                translate_x: Some(Mm(seal_x)),
                translate_y: Some(Mm(seal_y)),
                scale_x: Some(0.18),
                scale_y: Some(0.18),
                ..Default::default()
            },
        );
    }

    // ── DepEd Header (centered in right content area) ──
    let line1 = "Republic of the Philippines";
    draw_centered_text_in_right_col(engine, layer, line1, FONT_SIZE_LARGE, y, false);
    y -= GAP_NORMAL;

    let line2 = "DEPARTMENT OF EDUCATION";
    draw_centered_text_in_right_col(engine, layer, line2, FONT_SIZE_HEADER, y, true);
    y -= GAP_LARGE;

    // ── School meta lines (now FONT_SIZE_LARGE, flush with RIGHT_CONTENT_LEFT) ──
    let indent = RIGHT_CONTENT_LEFT + 14.0;
    let meta_line_w = RIGHT_CONTENT_WIDTH;
    draw_labeled_header_line(engine, layer, "Region", region, indent, y, meta_line_w);
    y -= GAP_NORMAL;
    draw_labeled_header_line(engine, layer, "Division", division, indent, y, meta_line_w);
    if !district.is_empty() {
        y -= GAP_NORMAL;
        draw_labeled_header_line(engine, layer, "District", district, indent, y, meta_line_w);
    }
    y -= GAP_NORMAL;
    draw_labeled_header_line(engine, layer, "School", school_name, indent, y, meta_line_w);

    // ── Title ──
    y -= GAP_LARGE;
    draw_centered_text_in_right_col(
        engine,
        layer,
        "LEARNER'S PROGRESS REPORT CARD",
        FONT_SIZE_TITLE,
        y,
        true,
    );
    y -= GAP_SMALL;

    let sy_text = format!("School Year  {}", school_year);
    draw_centered_text_in_right_col(engine, layer, &sy_text, FONT_SIZE_LARGE, y, false);

    // ── Student info fields (all FONT_SIZE_LARGE, bold labels) ──
    y -= GAP_LARGE;
    draw_field_line(
        engine,
        layer,
        "Name:",
        &sf9.student_name,
        RIGHT_CONTENT_LEFT,
        y,
        RIGHT_CONTENT_WIDTH,
        FONT_SIZE_MEDIUM,
        true,
    );

    y -= GAP_NORMAL;
    let half_w = RIGHT_CONTENT_WIDTH / 2.0 - 8.0;
    draw_field_line(
        engine,
        layer,
        "Age:",
        &sf9.age.map(|a| a.to_string()).unwrap_or_default(),
        RIGHT_CONTENT_LEFT,
        y,
        half_w,
        FONT_SIZE_MEDIUM,
        true,
    );
    draw_field_line(
        engine,
        layer,
        "Sex:",
        sf9.sex.as_deref().unwrap_or(""),
        RIGHT_CONTENT_LEFT + half_w + 16.0,
        y,
        half_w,
        FONT_SIZE_MEDIUM,
        true,
    );

    y -= GAP_NORMAL;

    let gap = 8.0;
    let total = RIGHT_CONTENT_WIDTH;

    let usable = total - 2.0 * gap;
    let grade_w = usable * 0.15;
    let section_w = usable * 0.35;
    let lrn_w = usable * 0.50;

    let grade_x = RIGHT_CONTENT_LEFT;
    let section_x = grade_x + grade_w + gap;
    let lrn_x = section_x + section_w + gap;

    draw_field_line(
        engine,
        layer,
        "Grade:",
        sf9.grade_level.as_deref().unwrap_or(""),
        grade_x,
        y,
        grade_w,
        FONT_SIZE_MEDIUM,
        true,
    );
    draw_field_line(
        engine,
        layer,
        "Section:",
        sf9.section.as_deref().unwrap_or(""),
        section_x,
        y,
        section_w,
        FONT_SIZE_MEDIUM,
        true,
    );
    draw_field_line(
        engine,
        layer,
        "LRN:",
        sf9.lrn.as_deref().unwrap_or(""),
        lrn_x,
        y,
        lrn_w,
        FONT_SIZE_MEDIUM,
        true,
    );

    // Restore the breathing room the old box-drawing function used to give us for free
    y -= GAP_NORMAL;

    // ── Dear Parent ──
    y -= GAP_SMALL;
    engine.draw_text(
        layer,
        "Dear Parent,",
        FONT_SIZE_MEDIUM,
        Mm(RIGHT_CONTENT_LEFT),
        Mm(y),
        false,
    );
    y -= GAP_MEDIUM;
    let parent_letter = "This report card shows the ability and the progress your child has made in the different learning areas as well as his/her progress in core values.";
    y = draw_wrapped_text(
        engine,
        layer,
        parent_letter,
        RIGHT_CONTENT_LEFT,
        y,
        RIGHT_CONTENT_WIDTH + 17.0,
        FONT_SIZE_MEDIUM,
    ) - 2.0;

    y -= GAP_TIGHT;
    let parent_letter =
        "The school welcomes you should you desire to know more about your child's progress.";
    y = draw_wrapped_text(
        engine,
        layer,
        parent_letter,
        RIGHT_CONTENT_LEFT,
        y,
        RIGHT_CONTENT_WIDTH + 17.0,
        FONT_SIZE_MEDIUM,
    ) - 2.0;

    // ── Signatures ──
    y -= GAP_SMALL;
    let sig_w = RIGHT_CONTENT_WIDTH / 2.0 - 10.0;
    draw_sig_block(
        engine,
        layer,
        RIGHT_CONTENT_LEFT,
        y,
        sig_w,
        school_head_name,
        "Head Teacher/ Principal",
        FONT_SIZE_MEDIUM,
        FONT_SIZE_MEDIUM,
    );
    draw_sig_block(
        engine,
        layer,
        RIGHT_CONTENT_LEFT + sig_w + 20.0,
        y,
        sig_w,
        sf9.teacher_name.as_deref().unwrap_or(""),
        "Teacher",
        FONT_SIZE_MEDIUM,
        FONT_SIZE_MEDIUM,
    );

    // ── Certificate of Transfer ──
    y -= GAP_XXL;
    y -= GAP_SMALL;
    draw_centered_text_in_right_content(
        engine,
        layer,
        "Certificate of Transfer",
        FONT_SIZE_HEADER,
        y,
        true,
    );
    y -= GAP_MEDIUM;
    draw_field_line(
        engine,
        layer,
        "Admitted to Grade",
        "",
        RIGHT_CONTENT_LEFT,
        y,
        43.0,
        FONT_SIZE_MEDIUM,
        false,
    );
    draw_field_line(
        engine,
        layer,
        "Section",
        "",
        RIGHT_CONTENT_LEFT + 48.0,
        y,
        27.0,
        FONT_SIZE_MEDIUM,
        false,
    );
    draw_field_line(
        engine,
        layer,
        "Room",
        "",
        RIGHT_CONTENT_LEFT + 82.0,
        y,
        RIGHT_CONTENT_WIDTH - 85.0,
        FONT_SIZE_MEDIUM,
        false,
    );
    y -= GAP_NORMAL;
    draw_field_line(
        engine,
        layer,
        "Eligible for Admission to Grade",
        "",
        RIGHT_CONTENT_LEFT,
        y,
        RIGHT_CONTENT_WIDTH,
        FONT_SIZE_MEDIUM,
        false,
    );
    y -= GAP_MEDIUM;
    engine.draw_text(
        layer,
        "Approved:",
        FONT_SIZE_MEDIUM,
        Mm(RIGHT_CONTENT_LEFT),
        Mm(y),
        false,
    );
    y -= GAP_LARGE;
    let xfer_sig_w = RIGHT_CONTENT_WIDTH / 2.0 - 6.0;
    draw_sig_block(
        engine,
        layer,
        RIGHT_CONTENT_LEFT,
        y,
        xfer_sig_w,
        school_head_name,
        "Head Teacher/ Principal",
        FONT_SIZE_MEDIUM,
        FONT_SIZE_MEDIUM,
    );
    draw_sig_block(
        engine,
        layer,
        RIGHT_CONTENT_LEFT + xfer_sig_w + 12.0,
        y,
        xfer_sig_w,
        sf9.teacher_name.as_deref().unwrap_or(""),
        "Teacher",
        FONT_SIZE_MEDIUM,
        FONT_SIZE_MEDIUM,
    );

    // ── Cancellation of Eligibility to Transfer ──
    y -= GAP_XXL;
    draw_centered_text_in_right_content(
        engine,
        layer,
        "Cancellation of Eligibility to Transfer",
        FONT_SIZE_HEADER,
        y,
        true,
    );
    y -= GAP_MEDIUM;
    draw_field_line(
        engine,
        layer,
        "Admitted in",
        "",
        RIGHT_CONTENT_LEFT,
        y,
        RIGHT_CONTENT_WIDTH,
        FONT_SIZE_MEDIUM,
        false,
    );
    y -= GAP_NORMAL;
    draw_field_line(
        engine,
        layer,
        "Date:",
        "",
        RIGHT_CONTENT_LEFT,
        y,
        RIGHT_CONTENT_WIDTH / 2.0,
        FONT_SIZE_MEDIUM,
        false,
    );
    y -= GAP_LARGE;
    draw_sig_block(
        engine,
        layer,
        RIGHT_CONTENT_LEFT + RIGHT_CONTENT_WIDTH / 2.0,
        y,
        xfer_sig_w,
        "",
        "Principal",
        FONT_SIZE_MEDIUM,
        FONT_SIZE_MEDIUM,
    );
}

fn draw_labeled_header_line(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    label: &str,
    value: &str,
    x: f32,
    y: f32,
    total_w: f32,
) {
    let label_text = format!("{}:", label);
    let label_w = text_width_bold(&label_text, FONT_SIZE_NORMAL) + HEADER_META_LABEL_PADDING;
    engine.draw_text(layer, &label_text, FONT_SIZE_NORMAL, Mm(x), Mm(y), true);
    let value_x = x + label_w;
    let value_w = (total_w - label_w).max(10.0) - 14.0;
    super::layout::draw_underline(engine, layer, value_x, y - 1.5, value_w, 0.15);
    if !value.is_empty() {
        engine.draw_text(
            layer,
            value,
            FONT_SIZE_NORMAL,
            Mm(value_x + 2.0),
            Mm(y),
            false,
        );
    }
}

fn draw_lrn_boxes(
    engine: &PdfEngine,
    layer: &PdfLayerReference,
    x: f32,
    y: f32,
    total_w: f32,
    label: &str,
    lrn: &str,
) -> f32 {
    engine.draw_text(layer, label, FONT_SIZE_LARGE, Mm(x), Mm(y), true);
    let boxes = 12usize;
    let box_size = 7.0;
    let box_gap = 1.4;
    let boxes_width = boxes as f32 * box_size + (boxes - 1) as f32 * box_gap;
    let start_x = x + total_w - boxes_width;
    let box_y = y - 8.5;
    let chars: Vec<char> = lrn.chars().collect();
    for i in 0..boxes {
        let bx = start_x + i as f32 * (box_size + box_gap);
        engine.draw_rect(layer, Mm(bx), Mm(box_y), Mm(box_size), Mm(7.5), None, true);
        if let Some(ch) = chars.get(i) {
            engine.draw_text(
                layer,
                &ch.to_string(),
                FONT_SIZE_NORMAL,
                Mm(bx + 2.0),
                Mm(box_y + 2.5),
                false,
            );
        }
    }
    box_y - 2.5
}
