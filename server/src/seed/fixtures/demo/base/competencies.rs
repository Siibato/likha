//! Demo competencies for Science 10 (4 per term).

use crate::seed::specs::CompetencySpec;
use super::super::{tid, compid};

pub fn demo_competencies() -> Vec<CompetencySpec> {
    vec![
        // T1 - Plate Tectonics
        CompetencySpec { id: compid("s10t1_comp_0"), tos_id: tid("sci10_tos_t1"), code: Some("S9ES-Ia-1".into()), text: "Describe the internal structure of the Earth".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s10t1_comp_1"), tos_id: tid("sci10_tos_t1"), code: Some("S9ES-Ib-2".into()), text: "Explain the theory of plate tectonics".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s10t1_comp_2"), tos_id: tid("sci10_tos_t1"), code: Some("S9ES-Ic-3".into()), text: "Describe how earthquakes and volcanoes occur".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s10t1_comp_3"), tos_id: tid("sci10_tos_t1"), code: Some("S9ES-Id-4".into()), text: "Analyze the relationship between plate boundaries and geological hazards in the Philippines".into(), time_units_taught: 5, order: 3 },
        // T2 - Genetics & Heredity
        CompetencySpec { id: compid("s10t2_comp_0"), tos_id: tid("sci10_tos_t2"), code: Some("S9LT-IIa-1".into()), text: "Describe the structure and function of DNA".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s10t2_comp_1"), tos_id: tid("sci10_tos_t2"), code: Some("S9LT-IIb-2".into()), text: "Explain the process of protein synthesis".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s10t2_comp_2"), tos_id: tid("sci10_tos_t2"), code: Some("S9LT-IIc-3".into()), text: "Apply Mendel's laws to predict inheritance patterns".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s10t2_comp_3"), tos_id: tid("sci10_tos_t2"), code: Some("S9LT-IId-4".into()), text: "Explain the role of natural selection in evolution".into(), time_units_taught: 5, order: 3 },
        // T3 - Chemistry
        CompetencySpec { id: compid("s10t3_comp_0"), tos_id: tid("sci10_tos_t3"), code: Some("S9MT-IIIa-1".into()), text: "Explain how atoms form chemical bonds".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s10t3_comp_1"), tos_id: tid("sci10_tos_t3"), code: Some("S9MT-IIIb-2".into()), text: "Classify chemical reactions by type".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s10t3_comp_2"), tos_id: tid("sci10_tos_t3"), code: Some("S9MT-IIIc-3".into()), text: "Balance chemical equations".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s10t3_comp_3"), tos_id: tid("sci10_tos_t3"), code: Some("S9MT-IIId-4".into()), text: "Relate chemical reactions to everyday phenomena".into(), time_units_taught: 5, order: 3 },
        // T4 - Physics
        CompetencySpec { id: compid("s10t4_comp_0"), tos_id: tid("sci10_tos_t4"), code: Some("S9FM-IVa-1".into()), text: "Describe the relationship between force and motion".into(), time_units_taught: 5, order: 0 },
        CompetencySpec { id: compid("s10t4_comp_1"), tos_id: tid("sci10_tos_t4"), code: Some("S9FM-IVb-2".into()), text: "Calculate speed, velocity, and acceleration".into(), time_units_taught: 5, order: 1 },
        CompetencySpec { id: compid("s10t4_comp_2"), tos_id: tid("sci10_tos_t4"), code: Some("S9FM-IVc-3".into()), text: "Explain the relationship between work, energy, and power".into(), time_units_taught: 5, order: 2 },
        CompetencySpec { id: compid("s10t4_comp_3"), tos_id: tid("sci10_tos_t4"), code: Some("S9FM-IVd-4".into()), text: "Describe how simple machines make work easier".into(), time_units_taught: 5, order: 3 },
    ]
}
