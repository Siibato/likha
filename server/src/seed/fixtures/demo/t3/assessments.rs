//! T3 assessments for demo seeding: Chemistry.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::super::{cid, tid, compid, aid, build_questions};

pub fn demo_assessments_t3(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(20);
    let now = ctx.now();
    let comps = &[compid("s10t3_comp_0"), compid("s10t3_comp_1"), compid("s10t3_comp_2"), compid("s10t3_comp_3")];

    let quiz1_qs = build_questions("t3_quiz1",
        &[
            ("What type of bond involves the sharing of electron pairs?", &["Ionic", "Covalent", "Metallic", "Hydrogen"], 1, "easy", "remembering"),
            ("Which element is most likely to form an ionic bond with sodium?", &["Carbon", "Oxygen", "Chlorine", "Neon"], 2, "medium", "understanding"),
            ("What is the name of the bond formed between a metal and a non-metal?", &["Covalent", "Ionic", "Metallic", "Van der Waals"], 1, "easy", "remembering"),
            ("How many electrons are shared in a triple covalent bond?", &["2", "4", "6", "8"], 2, "medium", "understanding"),
            ("Which type of bond is the strongest?", &["Hydrogen", "Ionic", "Covalent", "Metallic"], 2, "difficult", "analyzing"),
        ],
        &[
            ("What is the force that holds atoms together in a molecule?", "Chemical bond", "easy", "remembering"),
            ("What is an atom called when it gains or loses electrons?", "Ion", "easy", "remembering"),
            ("What type of bond holds metal atoms together in a solid?", "Metallic bond", "easy", "remembering"),
            ("What is the attraction between oppositely charged ions called?", "Ionic bond", "easy", "remembering"),
            ("What do you call a covalent bond where electrons are shared unequally?", "Polar covalent bond", "medium", "understanding"),
        ],
        &[],
        comps,
    );

    let quiz2_qs = build_questions("t3_quiz2",
        &[
            ("Which of the following is a sign that a chemical reaction has occurred?", &["Change in color", "Formation of gas", "Temperature change", "All of the above"], 3, "easy", "remembering"),
            ("What is the term for a substance that speeds up a chemical reaction without being consumed?", &["Reactant", "Product", "Catalyst", "Inhibitor"], 2, "easy", "remembering"),
            ("In a balanced chemical equation, what must be equal on both sides?", &["Number of molecules", "Number of atoms of each element", "Volume of gases", "Total mass only"], 1, "medium", "understanding"),
            ("What type of reaction occurs when a substance reacts with oxygen to produce heat and light?", &["Decomposition", "Synthesis", "Combustion", "Single replacement"], 2, "medium", "understanding"),
            ("Which factor does NOT affect the rate of a chemical reaction?", &["Temperature", "Concentration", "Color of reactants", "Surface area"], 2, "medium", "analyzing"),
        ],
        &[
            ("What is the starting material in a chemical reaction called?", "Reactant", "easy", "remembering"),
            ("What is the substance formed as a result of a chemical reaction?", "Product", "easy", "remembering"),
            ("What law states that mass is neither created nor destroyed in a chemical reaction?", "Law of conservation of mass", "easy", "remembering"),
            ("What is a reaction called when one element replaces another in a compound?", "Single replacement", "easy", "remembering"),
            ("What do you call a reaction that releases heat?", "Exothermic reaction", "easy", "remembering"),
        ],
        &[],
        comps,
    );

    let exam_qs = build_questions("t3_exam",
        &[
            ("Which group of elements is most likely to form ionic bonds?", &["Noble gases", "Halogens and alkali metals", "Transition metals only", "All metals"], 1, "medium", "understanding"),
            ("What is the electron configuration of a stable atom?", &["Partially filled outer shell", "Completely filled outer shell", "Any number of electrons", "Only two electrons total"], 1, "easy", "remembering"),
            ("In the equation 2H2 + O2 -> 2H2O, what is the coefficient of water?", &["1", "2", "3", "4"], 1, "easy", "remembering"),
            ("What happens to the activation energy when a catalyst is added?", &["It increases", "It decreases", "It stays the same", "It becomes zero"], 1, "medium", "understanding"),
            ("Which type of reaction is represented by AB -> A + B?", &["Synthesis", "Decomposition", "Single replacement", "Double replacement"], 1, "medium", "understanding"),
            ("What is the oxidation state of oxygen in most compounds?", &["-1", "-2", "+1", "+2"], 1, "difficult", "remembering"),
            ("Which bond type explains why diamond is so hard?", &["Ionic", "Covalent network", "Metallic", "Hydrogen"], 1, "difficult", "analyzing"),
            ("What is the product when an acid reacts with a base?", &["Salt and water", "Hydrogen gas", "Oxygen gas", "Carbon dioxide"], 0, "medium", "understanding"),
            ("Which element has the highest electronegativity?", &["Sodium", "Oxygen", "Fluorine", "Chlorine"], 2, "difficult", "remembering"),
            ("What does a chemical equation with a double arrow indicate?", &["The reaction is fast", "The reaction is slow", "The reaction is reversible", "The reaction is complete"], 2, "medium", "understanding"),
        ],
        &[
            ("What is a substance that donates hydrogen ions in a solution?", "Acid", "easy", "remembering"),
            ("What is the pH of a neutral solution at 25 degrees Celsius?", "7", "easy", "remembering"),
            ("What is the chemical formula for table salt?", "NaCl", "easy", "remembering"),
            ("What process uses electricity to break down a compound?", "Electrolysis", "medium", "understanding"),
            ("What is the name of the force that holds ions together in an ionic compound?", "Electrostatic attraction", "medium", "understanding"),
        ],
        &[
            ("Explain the difference between ionic and covalent bonding. Provide one real-world example for each type and describe how the properties of the resulting compounds relate to their bonding type.", 5, "difficult", "evaluating"),
            ("Describe the process of balancing chemical equations and why it is necessary. Use a specific example to show how coefficients are adjusted to satisfy the law of conservation of mass.", 5, "difficult", "evaluating"),
        ],
        comps,
    );

    vec![
        AssessmentSpec {
            id: aid("t3_quiz1"), class_id: cid("sci10"),
            title: "T3 Quiz 1: Chemical Bonding".into(),
            description: Some("10-item quiz on ionic, covalent, and metallic bonding.".into()),
            time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1),
            show_results_immediately: true, total_points: 10, component: "written_work".into(),
            tos_id: tid("sci10_tos_t3"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, term_number: 3,
            questions: quiz1_qs,
        },
        AssessmentSpec {
            id: aid("t3_quiz2"), class_id: cid("sci10"),
            title: "T3 Quiz 2: Chemical Reactions and Equations".into(),
            description: Some("10-item quiz on types of reactions and balancing equations.".into()),
            time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1),
            show_results_immediately: true, total_points: 10, component: "written_work".into(),
            tos_id: tid("sci10_tos_t3"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, term_number: 3,
            questions: quiz2_qs,
        },
        AssessmentSpec {
            id: aid("t3_exam"), class_id: cid("sci10"),
            title: "T3 Term Exam: Chemistry".into(),
            description: Some("25-item term assessment on chemical bonding, reactions, and equations.".into()),
            time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2),
            show_results_immediately: true, total_points: 25, component: "term_assessment".into(),
            tos_id: tid("sci10_tos_t3"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, term_number: 3,
            questions: exam_qs,
        },
    ]
}
