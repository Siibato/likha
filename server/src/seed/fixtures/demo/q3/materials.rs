//! Q3 learning modules for demo seeding: Chemistry.

use crate::seed::specs::MaterialSpec;
use crate::seed::tools::SeedContext;
use super::super::{cid, mid};

pub fn demo_materials_q3(ctx: &SeedContext) -> Vec<MaterialSpec> {
    vec![
        MaterialSpec {
            id: mid("q3_mod1"), class_id: cid("sci10"),
            title: "Module 1: Chemical Bonding".into(),
            description: Some("Covers ionic, covalent, and metallic bonds, electronegativity, and properties of compounds.".into()),
            content_text: Some(
                "Chemical bonding is the force that holds atoms together in molecules and compounds. There are three main types of chemical bonds: ionic, covalent, and metallic. Ionic bonds form between metals and non-metals when electrons are transferred from one atom to another, creating positively and negatively charged ions that attract each other. For example, sodium chloride (table salt) is an ionic compound formed when sodium donates an electron to chlorine. Covalent bonds form when atoms share electron pairs, typically between non-metal atoms. Water (H2O) is a covalent compound where oxygen shares electrons with two hydrogen atoms. Metallic bonds occur between metal atoms, where electrons are delocalized and free to move throughout the structure, giving metals their characteristic properties like electrical conductivity and malleability. Electronegativity is a measure of an atom's ability to attract electrons in a bond. When electronegativity differences are large, ionic bonds tend to form; when differences are small, covalent bonds result."
                    .into(),
            ),
            order_index: 0, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("q3_mod2"), class_id: cid("sci10"),
            title: "Module 2: Chemical Reactions and Equations".into(),
            description: Some("Covers types of reactions, balancing equations, reaction rates, and the law of conservation of mass.".into()),
            content_text: Some(
                "A chemical reaction is a process in which substances called reactants are converted into different substances called products. Chemical reactions are described by chemical equations, which must be balanced to satisfy the law of conservation of mass: matter cannot be created or destroyed, only rearranged. The main types of chemical reactions include synthesis (A + B -> AB), decomposition (AB -> A + B), single replacement (A + BC -> AC + B), double replacement (AB + CD -> AD + CB), and combustion (fuel + O2 -> CO2 + H2O). Factors that affect reaction rates include temperature, concentration, surface area, and the presence of catalysts. A catalyst is a substance that increases the rate of a reaction without being consumed. Enzymes are biological catalysts that speed up chemical reactions in living organisms. Understanding chemical reactions is essential for fields ranging from medicine and agriculture to materials science and environmental protection."
                    .into(),
            ),
            order_index: 1, created_at: ctx.now(),
        },
    ]
}
