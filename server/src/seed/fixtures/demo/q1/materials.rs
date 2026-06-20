//! Q1 learning modules for demo seeding: Plate Tectonics.

use crate::seed::specs::MaterialSpec;
use crate::seed::tools::SeedContext;
use super::super::{cid, mid};

pub fn demo_materials_q1(ctx: &SeedContext) -> Vec<MaterialSpec> {
    vec![
        MaterialSpec {
            id: mid("q1_mod1"), class_id: cid("sci10"),
            title: "Module 1: The Earth's Interior".into(),
            description: Some("Covers crust, mantle, outer core, inner core, seismic waves, and how scientists study Earth's layers.".into()),
            content_text: Some(
                "The Earth is composed of four main layers: the crust, mantle, outer core, and inner core. \
                The crust is the thin, solid outermost layer where we live. It is made of solid rock and is divided into continental and oceanic crust. \
                Beneath the crust lies the mantle, the thickest layer of the Earth. The mantle is made of semi-solid rock that can flow slowly over geological time. \
                Scientists study Earth's interior by analyzing seismic waves produced by earthquakes. These waves change speed and direction as they pass through different materials. \
                The outer core is a layer of liquid iron and nickel that lies beneath the mantle. The movement of this liquid metal generates Earth's magnetic field. \
                At the very center is the inner core, a solid sphere composed mainly of iron and nickel. Despite extremely high temperatures, the inner core remains solid due to the immense pressure from the layers above."
                    .into(),
            ),
            order_index: 0, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("q1_mod2"), class_id: cid("sci10"),
            title: "Module 2: Plate Tectonics".into(),
            description: Some("Covers plate boundaries (divergent, convergent, transform), landforms, Philippine Ring of Fire, earthquake and volcano formation.".into()),
            content_text: Some(
                "Plate tectonics is the scientific theory that explains how major landforms are created as a result of Earth's subterranean movements. \
                The Earth's lithosphere is broken into large pieces called tectonic plates. These plates float on the semi-fluid asthenosphere and move slowly over time. \
                There are three main types of plate boundaries. At divergent boundaries, plates move away from each other, creating mid-ocean ridges and rift valleys. \
                At convergent boundaries, plates collide. When oceanic and continental plates converge, the denser oceanic plate subducts beneath the continental plate, creating deep ocean trenches and volcanic mountain ranges. \
                At transform boundaries, plates slide past each other horizontally. The Philippines sits along the Pacific Ring of Fire, a horseshoe-shaped belt around the Pacific Ocean where about 75% of the world's volcanoes are located and where earthquakes are frequent. This is because the Philippine archipelago is located at the convergence of several tectonic plates, making it one of the most geologically active places on Earth."
                    .into(),
            ),
            order_index: 1, created_at: ctx.now(),
        },
    ]
}
