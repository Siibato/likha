//! Demo-2 competencies: 4 per term for 6 subjects (72 total).

use super::super::{compid, tid};
use crate::seed::specs::CompetencySpec;

pub fn demo2_competencies() -> Vec<CompetencySpec> {
    let mut comps = Vec::with_capacity(72);

    // Science 10 - T1: Plate Tectonics
    comps.push(CompetencySpec { id: compid("sci_t1_comp_0"), tos_id: tid("sci10_tos_t1"), code: Some("S9ES-Ia-1".into()), text: "Describe the internal structure of the Earth".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("sci_t1_comp_1"), tos_id: tid("sci10_tos_t1"), code: Some("S9ES-Ib-2".into()), text: "Explain the theory of plate tectonics".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("sci_t1_comp_2"), tos_id: tid("sci10_tos_t1"), code: Some("S9ES-Ic-3".into()), text: "Describe how earthquakes and volcanoes occur".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("sci_t1_comp_3"), tos_id: tid("sci10_tos_t1"), code: Some("S9ES-Id-4".into()), text: "Analyze the relationship between plate boundaries and geological hazards in the Philippines".into(), time_units_taught: 5, order: 3 });

    // Science 10 - T2: Genetics & Heredity
    comps.push(CompetencySpec { id: compid("sci_t2_comp_0"), tos_id: tid("sci10_tos_t2"), code: Some("S9LT-IIa-1".into()), text: "Describe the structure and function of DNA".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("sci_t2_comp_1"), tos_id: tid("sci10_tos_t2"), code: Some("S9LT-IIb-2".into()), text: "Explain the process of protein synthesis".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("sci_t2_comp_2"), tos_id: tid("sci10_tos_t2"), code: Some("S9LT-IIc-3".into()), text: "Apply Mendel's laws to predict inheritance patterns".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("sci_t2_comp_3"), tos_id: tid("sci10_tos_t2"), code: Some("S9LT-IId-4".into()), text: "Explain the role of natural selection in evolution".into(), time_units_taught: 5, order: 3 });

    // Science 10 - T3: Chemistry
    comps.push(CompetencySpec { id: compid("sci_t3_comp_0"), tos_id: tid("sci10_tos_t3"), code: Some("S9MT-IIIa-1".into()), text: "Explain how atoms form chemical bonds".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("sci_t3_comp_1"), tos_id: tid("sci10_tos_t3"), code: Some("S9MT-IIIb-2".into()), text: "Classify chemical reactions by type".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("sci_t3_comp_2"), tos_id: tid("sci10_tos_t3"), code: Some("S9MT-IIIc-3".into()), text: "Balance chemical equations".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("sci_t3_comp_3"), tos_id: tid("sci10_tos_t3"), code: Some("S9MT-IIId-4".into()), text: "Relate chemical reactions to everyday phenomena".into(), time_units_taught: 5, order: 3 });

    // English 10 - T1: Philippine Literature
    comps.push(CompetencySpec { id: compid("eng_t1_comp_0"), tos_id: tid("eng10_tos_t1"), code: Some("EN10LC-Ia-1".into()), text: "Analyze literary texts as expressions of individual or communal values".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("eng_t1_comp_1"), tos_id: tid("eng10_tos_t1"), code: Some("EN10LC-Ib-2".into()), text: "Explain how the elements specific to a selection build its theme".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("eng_t1_comp_2"), tos_id: tid("eng10_tos_t1"), code: Some("EN10LC-Ic-3".into()), text: "Differentiate literary forms from other forms of writing".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("eng_t1_comp_3"), tos_id: tid("eng10_tos_t1"), code: Some("EN10LC-Id-4".into()), text: "Produce a creative representation of a literary text".into(), time_units_taught: 5, order: 3 });

    // English 10 - T2: World Literature
    comps.push(CompetencySpec { id: compid("eng_t2_comp_0"), tos_id: tid("eng10_tos_t2"), code: Some("EN10LT-IIa-1".into()), text: "Compare and contrast the various 21st century literary genres".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("eng_t2_comp_1"), tos_id: tid("eng10_tos_t2"), code: Some("EN10LT-IIb-2".into()), text: "Analyze the relationship between text and context".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("eng_t2_comp_2"), tos_id: tid("eng10_tos_t2"), code: Some("EN10LT-IIc-3".into()), text: "Evaluate literature as a mirror of life".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("eng_t2_comp_3"), tos_id: tid("eng10_tos_t2"), code: Some("EN10LT-IId-4".into()), text: "Produce a creative critique of a literary work".into(), time_units_taught: 5, order: 3 });

    // English 10 - T3: Academic Writing
    comps.push(CompetencySpec { id: compid("eng_t3_comp_0"), tos_id: tid("eng10_tos_t3"), code: Some("EN10WC-IIIa-1".into()), text: "Identify the features of academic writing".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("eng_t3_comp_1"), tos_id: tid("eng10_tos_t3"), code: Some("EN10WC-IIIb-2".into()), text: "Formulate claims of fact, policy, and value".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("eng_t3_comp_2"), tos_id: tid("eng10_tos_t3"), code: Some("EN10WC-IIIc-3".into()), text: "Write a position paper on a current issue".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("eng_t3_comp_3"), tos_id: tid("eng10_tos_t3"), code: Some("EN10WC-IIId-4".into()), text: "Revise written outputs using appropriate citation styles".into(), time_units_taught: 5, order: 3 });

    // Math 10 - T1: Linear Equations & Inequalities
    comps.push(CompetencySpec { id: compid("math_t1_comp_0"), tos_id: tid("math10_tos_t1"), code: Some("M10AL-Ia-1".into()), text: "Illustrate linear equations in two variables".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("math_t1_comp_1"), tos_id: tid("math10_tos_t1"), code: Some("M10AL-Ib-2".into()), text: "Graph linear equations in two variables".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("math_t1_comp_2"), tos_id: tid("math10_tos_t1"), code: Some("M10AL-Ic-3".into()), text: "Solve systems of linear equations in two variables".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("math_t1_comp_3"), tos_id: tid("math10_tos_t1"), code: Some("M10AL-Id-4".into()), text: "Solve problems involving systems of linear equations".into(), time_units_taught: 5, order: 3 });

    // Math 10 - T2: Quadratic Functions
    comps.push(CompetencySpec { id: compid("math_t2_comp_0"), tos_id: tid("math10_tos_t2"), code: Some("M10AL-IIa-1".into()), text: "Represent quadratic functions using equations, tables, and graphs".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("math_t2_comp_1"), tos_id: tid("math10_tos_t2"), code: Some("M10AL-IIb-2".into()), text: "Analyze the effects of parameters on quadratic functions".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("math_t2_comp_2"), tos_id: tid("math10_tos_t2"), code: Some("M10AL-IIc-3".into()), text: "Solve quadratic equations by factoring".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("math_t2_comp_3"), tos_id: tid("math10_tos_t2"), code: Some("M10AL-IId-4".into()), text: "Solve quadratic equations using the quadratic formula".into(), time_units_taught: 5, order: 3 });

    // Math 10 - T3: Geometry
    comps.push(CompetencySpec { id: compid("math_t3_comp_0"), tos_id: tid("math10_tos_t3"), code: Some("M10GE-IIIa-1".into()), text: "Describe a geometric sequence".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("math_t3_comp_1"), tos_id: tid("math10_tos_t3"), code: Some("M10GE-IIIb-2".into()), text: "Illustrate geometric sequences".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("math_t3_comp_2"), tos_id: tid("math10_tos_t3"), code: Some("M10GE-IIIc-3".into()), text: "Find the nth term of a geometric sequence".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("math_t3_comp_3"), tos_id: tid("math10_tos_t3"), code: Some("M10GE-IIId-4".into()), text: "Solve problems involving geometric sequences".into(), time_units_taught: 5, order: 3 });

    // AP 10 - T1: Pre-colonial to Spanish Period
    comps.push(CompetencySpec { id: compid("ap_t1_comp_0"), tos_id: tid("ap10_tos_t1"), code: Some("AP10H-Ia-1".into()), text: "Analyze the geographical location of the Philippines".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("ap_t1_comp_1"), tos_id: tid("ap10_tos_t1"), code: Some("AP10H-Ib-2".into()), text: "Describe the pre-colonial Philippine society".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("ap_t1_comp_2"), tos_id: tid("ap10_tos_t1"), code: Some("AP10H-Ic-3".into()), text: "Analyze the impact of Spanish colonization".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("ap_t1_comp_3"), tos_id: tid("ap10_tos_t1"), code: Some("AP10H-Id-4".into()), text: "Evaluate the effects of Spanish colonial policies".into(), time_units_taught: 5, order: 3 });

    // AP 10 - T2: Revolution & American Period
    comps.push(CompetencySpec { id: compid("ap_t2_comp_0"), tos_id: tid("ap10_tos_t2"), code: Some("AP10H-IIa-1".into()), text: "Explain the causes of the Philippine Revolution".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("ap_t2_comp_1"), tos_id: tid("ap10_tos_t2"), code: Some("AP10H-IIb-2".into()), text: "Analyze the key events of the revolution".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("ap_t2_comp_2"), tos_id: tid("ap10_tos_t2"), code: Some("AP10H-IIc-3".into()), text: "Describe the American colonial period".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("ap_t2_comp_3"), tos_id: tid("ap10_tos_t2"), code: Some("AP10H-IId-4".into()), text: "Evaluate the impact of American colonial policies".into(), time_units_taught: 5, order: 3 });

    // AP 10 - T3: Contemporary PH History
    comps.push(CompetencySpec { id: compid("ap_t3_comp_0"), tos_id: tid("ap10_tos_t3"), code: Some("AP10H-IIIa-1".into()), text: "Analyze the events leading to independence".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("ap_t3_comp_1"), tos_id: tid("ap10_tos_t3"), code: Some("AP10H-IIIb-2".into()), text: "Describe the Third Republic period".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("ap_t3_comp_2"), tos_id: tid("ap10_tos_t3"), code: Some("AP10H-IIIc-3".into()), text: "Analyze the Martial Law period".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("ap_t3_comp_3"), tos_id: tid("ap10_tos_t3"), code: Some("AP10H-IIId-4".into()), text: "Evaluate contemporary Philippine issues".into(), time_units_taught: 5, order: 3 });

    // Filipino 10 - T1: Maikling Kuwento
    comps.push(CompetencySpec { id: compid("fil_t1_comp_0"), tos_id: tid("fil10_tos_t1"), code: Some("F10LT-Ia-1".into()), text: "Suriin ang mga elemento ng maikling kwento".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("fil_t1_comp_1"), tos_id: tid("fil10_tos_t1"), code: Some("F10LT-Ib-2".into()), text: "Ipaliwanag ang papel ng mga tauhan sa pagbuo ng tema".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("fil_t1_comp_2"), tos_id: tid("fil10_tos_t1"), code: Some("F10LT-Ic-3".into()), text: "Tukuyin ang uri ng panitikan ayon sa anyo".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("fil_t1_comp_3"), tos_id: tid("fil10_tos_t1"), code: Some("F10LT-Id-4".into()), text: "Gumawa ng pananaliksik tungkol sa maikling kwento".into(), time_units_taught: 5, order: 3 });

    // Filipino 10 - T2: Tula at Dula
    comps.push(CompetencySpec { id: compid("fil_t2_comp_0"), tos_id: tid("fil10_tos_t2"), code: Some("F10LT-IIa-1".into()), text: "Suriin ang mga elemento ng tula".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("fil_t2_comp_1"), tos_id: tid("fil10_tos_t2"), code: Some("F10LT-IIb-2".into()), text: "Ipaliwanag ang gamit ng mga tayutay".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("fil_t2_comp_2"), tos_id: tid("fil10_tos_t2"), code: Some("F10LT-IIc-3".into()), text: "Suriin ang mga elemento ng dula".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("fil_t2_comp_3"), tos_id: tid("fil10_tos_t2"), code: Some("F10LT-IId-4".into()), text: "Gumawa ng kritikal na pagsusuri ng dula".into(), time_units_taught: 5, order: 3 });

    // Filipino 10 - T3: Sanaysay at Komunikasyon
    comps.push(CompetencySpec { id: compid("fil_t3_comp_0"), tos_id: tid("fil10_tos_t3"), code: Some("F10WC-IIIa-1".into()), text: "Tukuyin ang mga katangian ng sanaysay".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("fil_t3_comp_1"), tos_id: tid("fil10_tos_t3"), code: Some("F10WC-IIIb-2".into()), text: "Gumawa ng sanaysay na nagpapahayag ng pananaw".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("fil_t3_comp_2"), tos_id: tid("fil10_tos_t3"), code: Some("F10WC-IIIc-3".into()), text: "Isagawa ang tamang paggamit ng wika sa komunikasyon".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("fil_t3_comp_3"), tos_id: tid("fil10_tos_t3"), code: Some("F10WC-IIId-4".into()), text: "Pagsulat ng akademikong sanaysay".into(), time_units_taught: 5, order: 3 });

    // TLE 10 - T1: Computer Hardware Servicing
    comps.push(CompetencySpec { id: compid("tle_t1_comp_0"), tos_id: tid("tle10_tos_t1"), code: Some("TLE10CSS-Ia-1".into()), text: "Identify computer components and their functions".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("tle_t1_comp_1"), tos_id: tid("tle10_tos_t1"), code: Some("TLE10CSS-Ib-2".into()), text: "Demonstrate proper use of tools in computer servicing".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("tle_t1_comp_2"), tos_id: tid("tle10_tos_t1"), code: Some("TLE10CSS-Ic-3".into()), text: "Perform basic computer assembly and disassembly".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("tle_t1_comp_3"), tos_id: tid("tle10_tos_t1"), code: Some("TLE10CSS-Id-4".into()), text: "Apply safety procedures in computer servicing".into(), time_units_taught: 5, order: 3 });

    // TLE 10 - T2: Cookery
    comps.push(CompetencySpec { id: compid("tle_t2_comp_0"), tos_id: tid("tle10_tos_t2"), code: Some("TLE10CK-IIa-1".into()), text: "Identify kitchen tools and equipment".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("tle_t2_comp_1"), tos_id: tid("tle10_tos_t2"), code: Some("TLE10CK-IIb-2".into()), text: "Demonstrate proper food preparation techniques".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("tle_t2_comp_2"), tos_id: tid("tle10_tos_t2"), code: Some("TLE10CK-IIc-3".into()), text: "Prepare egg and cereal dishes".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("tle_t2_comp_3"), tos_id: tid("tle10_tos_t2"), code: Some("TLE10CK-IId-4".into()), text: "Apply safety and sanitation in food preparation".into(), time_units_taught: 5, order: 3 });

    // TLE 10 - T3: Entrepreneurship
    comps.push(CompetencySpec { id: compid("tle_t3_comp_0"), tos_id: tid("tle10_tos_t3"), code: Some("TLE10ES-IIIa-1".into()), text: "Identify business opportunities in the community".into(), time_units_taught: 5, order: 0 });
    comps.push(CompetencySpec { id: compid("tle_t3_comp_1"), tos_id: tid("tle10_tos_t3"), code: Some("TLE10ES-IIIb-2".into()), text: "Develop a simple business plan".into(), time_units_taught: 5, order: 1 });
    comps.push(CompetencySpec { id: compid("tle_t3_comp_2"), tos_id: tid("tle10_tos_t3"), code: Some("TLE10ES-IIIc-3".into()), text: "Demonstrate basic bookkeeping skills".into(), time_units_taught: 5, order: 2 });
    comps.push(CompetencySpec { id: compid("tle_t3_comp_3"), tos_id: tid("tle10_tos_t3"), code: Some("TLE10ES-IIId-4".into()), text: "Apply marketing strategies for small businesses".into(), time_units_taught: 5, order: 3 });

    comps
}
