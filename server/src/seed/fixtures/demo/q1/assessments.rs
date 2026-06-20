//! Q1 assessments for demo seeding: Plate Tectonics.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::super::{cid, tid, compid, aid, build_questions};

pub fn demo_assessments_q1(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(20);
    let now = ctx.now();
    let comps = &[compid("s10q1_comp_0"), compid("s10q1_comp_1"), compid("s10q1_comp_2"), compid("s10q1_comp_3")];

    let quiz1_qs = build_questions("q1_quiz1",
        &[
            ("Which layer of the Earth is primarily solid iron and nickel?", &["Crust", "Mantle", "Outer core", "Inner core"], 3, "easy", "remembering"),
            ("What type of boundary occurs when two plates move away from each other?", &["Convergent", "Divergent", "Transform", "Subduction"], 1, "easy", "remembering"),
            ("Which landform is typically created at a convergent plate boundary?", &["Rift valley", "Mountain range", "Mid-ocean ridge", "Trench only"], 1, "medium", "understanding"),
            ("What instrument is used to measure seismic waves?", &["Barometer", "Thermometer", "Seismograph", "Hygrometer"], 2, "easy", "remembering"),
            ("The Ring of Fire is associated with which type of plate boundary?", &["Divergent only", "Convergent", "Transform only", "All types equally"], 1, "medium", "understanding"),
        ],
        &[
            ("What is the outermost solid layer of the Earth called?", "Lithosphere", "easy", "remembering"),
            ("What process occurs when one tectonic plate moves under another?", "Subduction", "medium", "understanding"),
            ("What is the term for the rigid outer part of the Earth, consisting of the crust and upper mantle?", "Lithosphere", "easy", "remembering"),
            ("What scale is used to measure the energy released by an earthquake?", "Richter scale", "easy", "remembering"),
            ("What molten rock material is found beneath the Earth's surface?", "Magma", "easy", "remembering"),
        ],
        &[],
        comps,
    );

    let quiz2_qs = build_questions("q1_quiz2",
        &[
            ("Which of the following is NOT a type of plate boundary?", &["Convergent", "Divergent", "Transform", "Magnetic"], 3, "easy", "remembering"),
            ("What causes the high frequency of earthquakes in the Philippines?", &["It is located at the center of a plate", "It is near the Ring of Fire", "It has many volcanoes", "It is an island nation"], 1, "medium", "understanding"),
            ("What landform is created when two continental plates collide?", &["Ocean trench", "Mountain range", "Volcanic island", "Rift valley"], 1, "medium", "understanding"),
            ("Which layer of the Earth is composed mostly of silicate rocks?", &["Crust", "Inner core", "Outer core", "All layers"], 0, "easy", "remembering"),
            ("What happens at a transform boundary?", &["Plates move apart", "Plates slide past each other", "One plate sinks", "Mountains form"], 1, "easy", "remembering"),
        ],
        &[
            ("What is the name of the theory that explains the movement of Earth's plates?", "Plate tectonics", "easy", "remembering"),
            ("What do you call a volcano that is currently erupting or shows signs of activity?", "Active volcano", "easy", "remembering"),
            ("What is the region around the Pacific Ocean where many earthquakes and volcanoes occur?", "Ring of Fire", "easy", "remembering"),
            ("What is the layer of the Earth between the crust and the core?", "Mantle", "easy", "remembering"),
            ("What type of seismic wave travels through the interior of the Earth?", "Body wave", "medium", "understanding"),
        ],
        &[],
        comps,
    );

    let exam_qs = build_questions("q1_exam",
        &[
            ("Which layer of the Earth is the thinnest?", &["Crust", "Mantle", "Outer core", "Inner core"], 0, "easy", "remembering"),
            ("What is the primary force that drives plate tectonics?", &["Solar energy", "Convection currents in the mantle", "Earth's rotation", "Ocean tides"], 1, "medium", "understanding"),
            ("At which boundary does sea-floor spreading occur?", &["Convergent", "Divergent", "Transform", "Subduction"], 1, "easy", "remembering"),
            ("What type of volcano is Mount Pinatubo?", &["Shield", "Cinder cone", "Composite", "Caldera"], 2, "medium", "understanding"),
            ("Which of the following is evidence supporting plate tectonics?", &["Fossil distribution", "Shape of coastlines", "Magnetic striping", "All of the above"], 3, "medium", "understanding"),
            ("What is the approximate temperature of the Earth's inner core?", &["1,000 C", "2,500 C", "5,000 C", "10,000 C"], 2, "difficult", "remembering"),
            ("Which boundary is associated with the deepest earthquakes?", &["Divergent", "Transform", "Convergent subduction", "Hotspot"], 2, "difficult", "analyzing"),
            ("What causes volcanic arcs to form?", &["Sea-floor spreading", "Subduction and melting", "Transform motion", "Crustal thinning"], 1, "medium", "understanding"),
            ("Which Philippine fault is a transform boundary?", &["Manila Trench", "Philippine Fault", "East Luzon Trough", "Sulu Trench"], 1, "difficult", "remembering"),
            ("What happens to seismic waves as they pass through the outer core?", &["They speed up", "They slow down", "They disappear", "They bend toward the surface"], 1, "difficult", "analyzing"),
        ],
        &[
            ("What is the process by which mountains are formed at convergent boundaries?", "Orogeny", "medium", "understanding"),
            ("What term describes the supercontinent that existed millions of years ago?", "Pangaea", "easy", "remembering"),
            ("What do scientists study to learn about the Earth's interior?", "Seismic waves", "easy", "remembering"),
            ("What is the term for the point on the Earth's surface directly above where an earthquake starts?", "Epicenter", "easy", "remembering"),
            ("What type of rock forms from cooled magma beneath the surface?", "Igneous rock", "easy", "remembering"),
        ],
        &[
            ("Explain how the theory of plate tectonics accounts for the high frequency of earthquakes in the Philippines. Cite two specific geographical locations as evidence.", 5, "difficult", "evaluating"),
            ("Compare and contrast divergent and convergent plate boundaries. In your answer, describe the landforms produced by each and explain why the Philippines experiences more convergent activity.", 5, "difficult", "evaluating"),
        ],
        comps,
    );

    vec![
        AssessmentSpec {
            id: aid("q1_quiz1"), class_id: cid("sci10"),
            title: "Q1 Quiz 1: Earth's Structure & Plate Boundaries".into(),
            description: Some("10-item quiz on Earth's interior and basic plate tectonics.".into()),
            time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1),
            show_results_immediately: true, total_points: 10, component: "written_work".into(),
            tos_id: tid("sci10_tos_q1"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, term_number: 1,
            questions: quiz1_qs,
        },
        AssessmentSpec {
            id: aid("q1_quiz2"), class_id: cid("sci10"),
            title: "Q1 Quiz 2: Earthquakes & Volcanoes".into(),
            description: Some("10-item quiz on earthquakes, volcanoes, and the Ring of Fire.".into()),
            time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1),
            show_results_immediately: true, total_points: 10, component: "written_work".into(),
            tos_id: tid("sci10_tos_q1"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, term_number: 1,
            questions: quiz2_qs,
        },
        AssessmentSpec {
            id: aid("q1_exam"), class_id: cid("sci10"),
            title: "Q1 Quarter Exam: Earth & Space Science".into(),
            description: Some("25-item quarterly assessment on plate tectonics, earthquakes, and volcanoes.".into()),
            time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2),
            show_results_immediately: true, total_points: 25, component: "period_assessment".into(),
            tos_id: tid("sci10_tos_q1"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, term_number: 1,
            questions: exam_qs,
        },
    ]
}
