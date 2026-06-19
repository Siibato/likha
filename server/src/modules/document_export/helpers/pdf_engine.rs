use std::io::Cursor;

use image_crate::codecs::png::PngDecoder;
use printpdf::*;
use printpdf::path::PaintMode;

pub struct PdfEngine {
    pub doc: PdfDocumentReference,
    pub font_regular: IndirectFontRef,
    pub font_bold: IndirectFontRef,
    pub first_page: PdfPageIndex,
    pub first_layer: PdfLayerIndex,
}

impl PdfEngine {
    pub fn new(title: &str) -> Result<Self, Error> {
        let (doc, page1, layer1) =
            PdfDocument::new(title, Mm(297.0), Mm(210.0), "Layer 1");
        let font_regular = doc.add_builtin_font(BuiltinFont::Helvetica)?;
        let font_bold = doc.add_builtin_font(BuiltinFont::HelveticaBold)?;
        Ok(Self {
            doc,
            font_regular,
            font_bold,
            first_page: page1,
            first_layer: layer1,
        })
    }

    pub fn add_page(&self, width: Mm, height: Mm) -> (PdfPageIndex, PdfLayerIndex) {
        self.doc.add_page(width, height, "Layer 1")
    }

    pub fn get_layer(&self, page: PdfPageIndex, layer: PdfLayerIndex) -> PdfLayerReference {
        self.doc.get_page(page).get_layer(layer)
    }

    pub fn save(self) -> Result<Vec<u8>, Error> {
        self.doc.save_to_bytes()
    }

    pub fn draw_text(
        &self,
        layer: &PdfLayerReference,
        text: &str,
        font_size: f32,
        x: Mm,
        y: Mm,
        bold: bool,
    ) {
        let font = if bold { &self.font_bold } else { &self.font_regular };
        layer.set_fill_color(black());
        layer.use_text(text, font_size, x, y, font);
    }

    pub fn draw_rect(
        &self,
        layer: &PdfLayerReference,
        x: Mm,
        y: Mm,
        w: Mm,
        h: Mm,
        fill: Option<Color>,
        stroke: bool,
    ) {
        let mode = match (fill.is_some(), stroke) {
            (true, true) => PaintMode::FillStroke,
            (true, false) => PaintMode::Fill,
            (false, true) => PaintMode::Stroke,
            (false, false) => return,
        };
        if let Some(c) = fill {
            layer.set_fill_color(c);
        }
        let rect = Rect::new(x, y, x + w, y + h).with_mode(mode);
        layer.add_rect(rect);
    }

    pub fn load_png(data: &[u8]) -> Result<Image, Box<dyn std::error::Error>> {
        use image_crate::{DynamicImage, ImageEncoder, GenericImageView};
        use image_crate::codecs::png::PngEncoder;
        use image_crate::ColorType;

        let dynamic = image_crate::load_from_memory_with_format(
            data,
            image_crate::ImageFormat::Png,
        )?;

        let flattened: DynamicImage = if dynamic.color().has_alpha() {
            let rgba = dynamic.to_rgba8();
            let (w, h) = rgba.dimensions();
            let mut rgb = image_crate::RgbImage::new(w, h);
            for (x, y, px) in rgba.enumerate_pixels() {
                let a = px[3] as f32 / 255.0;
                let r = (px[0] as f32 * a + 255.0 * (1.0 - a)) as u8;
                let g = (px[1] as f32 * a + 255.0 * (1.0 - a)) as u8;
                let b = (px[2] as f32 * a + 255.0 * (1.0 - a)) as u8;
                rgb.put_pixel(x, y, image_crate::Rgb([r, g, b]));
            }
            DynamicImage::ImageRgb8(rgb)
        } else {
            dynamic
        };

        let mut png_out = Vec::new();
        let (w, h) = flattened.dimensions();
        PngEncoder::new(&mut png_out).write_image(
            flattened.to_rgb8().as_raw(),
            w, h,
            ColorType::Rgb8.into(),
        )?;

        let decoder = PngDecoder::new(Cursor::new(&png_out))?;
        Ok(Image::try_from(decoder)?)
    }
}

pub fn black() -> Color {
    Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None))
}

pub fn grey300() -> Color {
    Color::Rgb(Rgb::new(0.82, 0.82, 0.82, None))
}

pub fn yellow() -> Color {
    Color::Rgb(Rgb::new(1.0, 1.0, 0.6, None))
}
