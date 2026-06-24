//! T3 assessments for demo-2: 6 subjects × 3 assessments each (18 total).

use super::super::{aid, build_questions, cid, compid, tid};
use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn demo2_assessments_t3(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(10);
    let now = ctx.now();
    let mut assessments = Vec::with_capacity(18);

    // ─── Science 10: Chemistry ───────────────────────────────────────────────
    let sci_comps = &[compid("sci_t3_comp_0"), compid("sci_t3_comp_1"), compid("sci_t3_comp_2"), compid("sci_t3_comp_3")];

    let sci_quiz1_qs = build_questions("sci_t3_quiz1",
        &[("What type of bond involves sharing electrons?", &["Ionic", "Covalent", "Metallic", "Hydrogen"], 1, "easy", "remembering"),
          ("What type of bond involves transferring electrons?", &["Ionic", "Covalent", "Metallic", "Hydrogen"], 0, "easy", "remembering"),
          ("What is a molecule?", &["Smallest unit of matter", "Two or more atoms bonded", "Charged particle", "Electron cloud"], 1, "easy", "remembering"),
          ("What is the chemical formula for water?", &["HO", "H2O", "H2O2", "OH"], 1, "easy", "remembering"),
          ("What type of bond holds NaCl together?", &["Covalent", "Ionic", "Metallic", "Hydrogen"], 1, "medium", "understanding")],
        &[("What is a chemical bond?", "Chemical bond", "easy", "remembering"),
          ("What is an ionic bond?", "Ionic bond", "easy", "remembering"),
          ("What is a covalent bond?", "Covalent bond", "easy", "remembering"),
          ("What is a metallic bond?", "Metallic bond", "easy", "remembering"),
          ("What is a compound?", "Compound", "easy", "remembering")],
        &[],
        sci_comps,
    );

    let sci_quiz2_qs = build_questions("sci_t3_quiz2",
        &[("What is a chemical reaction?", &["No change", "Rearrangement of atoms", "Physical change", "Nuclear change"], 1, "easy", "understanding"),
          ("What are the products of a reaction?", &["Starting materials", "Substances formed", "Catalysts", "Energy"], 1, "easy", "remembering"),
          ("What is a balanced equation?", &["Equal numbers of atoms", "Equal mass", "Equal energy", "Equal volume"], 0, "medium", "understanding"),
          ("What type of reaction releases energy?", &["Endothermic", "Exothermic", "Synthesis", "Decomposition"], 1, "medium", "understanding"),
          ("What is a catalyst?", &["Reactant", "Product", "Speeds up reaction", "Slows reaction"], 2, "medium", "remembering")],
        &[("What is a reactant?", "Reactant", "easy", "remembering"),
          ("What is a product?", "Product", "easy", "remembering"),
          ("What is synthesis?", "Synthesis", "easy", "remembering"),
          ("What is decomposition?", "Decomposition", "easy", "remembering"),
          ("What is replacement?", "Replacement", "easy", "remembering")],
        &[],
        sci_comps,
    );

    let sci_exam_qs = build_questions("sci_t3_exam",
        &[("What holds atoms together in a molecule?", &["Gravity", "Chemical bonds", "Magnetism", "Nuclear force"], 1, "easy", "remembering"),
          ("Which type of bond is strongest?", &["Ionic", "Covalent", "Metallic", "Hydrogen"], 1, "medium", "analyzing"),
          ("What happens in a chemical reaction?", &["Atoms created", "Atoms rearranged", "Atoms destroyed", "No change"], 1, "easy", "understanding"),
          ("What is the law of conservation of mass?", &["Mass can change", "Mass is conserved", "Mass is created", "Mass disappears"], 1, "medium", "understanding"),
          ("What type of reaction is A + B → AB?", &["Decomposition", "Synthesis", "Replacement", "Combustion"], 1, "easy", "remembering"),
          ("What type of reaction is AB → A + B?", &["Synthesis", "Decomposition", "Replacement", "Combustion"], 1, "easy", "remembering"),
          ("What type of reaction is AB + C → AC + B?", &["Synthesis", "Decomposition", "Single replacement", "Double replacement"], 2, "medium", "applying"),
          ("What type of reaction is AB + CD → AD + CB?", &["Synthesis", "Decomposition", "Single replacement", "Double replacement"], 3, "medium", "applying"),
          ("What is combustion?", &["Reaction with oxygen", "Reaction with water", "Reaction with acid", "No reaction"], 0, "medium", "remembering"),
          ("How do chemical reactions relate to everyday phenomena?", &["No relation", "Explain many processes", "Only in labs", "Only theoretical"], 1, "difficult", "evaluating")],
        &[("What is a chemical equation?", "Chemical equation", "easy", "remembering"),
          ("What is balancing?", "Balancing", "easy", "remembering"),
          ("What is conservation of mass?", "Conservation of mass", "easy", "remembering"),
          ("What is energy change?", "Energy change", "easy", "remembering"),
          ("What is reaction rate?", "Reaction rate", "easy", "remembering")],
        &[("Explain how atoms form chemical bonds and why different types of bonds form between different elements. Use specific examples.", 5, "difficult", "analyzing"),
          ("Describe the different types of chemical reactions and give an example of each. Explain how these reactions are relevant to everyday life.", 5, "difficult", "applying")],
        sci_comps,
    );

    assessments.push(AssessmentSpec { id: aid("sci_t3_quiz1"), class_id: cid("sci10"), title: "T3 Quiz 1: Chemical Bonding".into(), description: Some("10-item quiz on chemical bonds.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("sci10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: sci_quiz1_qs });
    assessments.push(AssessmentSpec { id: aid("sci_t3_quiz2"), class_id: cid("sci10"), title: "T3 Quiz 2: Chemical Reactions".into(), description: Some("10-item quiz on chemical reactions.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("sci10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: sci_quiz2_qs });
    assessments.push(AssessmentSpec { id: aid("sci_t3_exam"), class_id: cid("sci10"), title: "T3 Term Exam: Chemistry".into(), description: Some("25-item term assessment on chemistry.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("sci10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: sci_exam_qs });

    // ─── English 10: Academic Writing ───────────────────────────────────────────
    let eng_comps = &[compid("eng_t3_comp_0"), compid("eng_t3_comp_1"), compid("eng_t3_comp_2"), compid("eng_t3_comp_3")];

    let eng_quiz1_qs = build_questions("eng_t3_quiz1",
        &[("What is academic writing?", &["Casual writing", "Formal scholarly writing", "Creative writing", "Personal writing"], 1, "easy", "remembering"),
          ("What is a thesis statement?", &["Supporting detail", "Main argument", "Conclusion", "Background"], 1, "easy", "remembering"),
          ("What is the purpose of an introduction?", &["Summarize", "Introduce topic and thesis", "Conclude", "Provide evidence"], 1, "easy", "remembering"),
          ("What is a body paragraph?", &["Introduction", "Supporting evidence", "Conclusion", "Title"], 1, "easy", "remembering"),
          ("What is a conclusion?", &["New argument", "Summary and restatement", "Introduction", "Evidence"], 1, "medium", "understanding")],
        &[("What is a claim?", "Claim", "easy", "remembering"),
          ("What is evidence?", "Evidence", "easy", "remembering"),
          ("What is analysis?", "Analysis", "easy", "remembering"),
          ("What is citation?", "Citation", "easy", "remembering"),
          ("What is plagiarism?", "Plagiarism", "easy", "remembering")],
        &[],
        eng_comps,
    );

    let eng_quiz2_qs = build_questions("eng_t3_quiz2",
        &[("What is a claim of fact?", &["Opinion", "Verifiable statement", "Question", "Story"], 1, "medium", "understanding"),
          ("What is a claim of value?", &["Verifiable", "Judgment", "Question", "Story"], 1, "medium", "understanding"),
          ("What is a claim of policy?", &["Judgment", "Call to action", "Question", "Story"], 1, "medium", "understanding"),
          ("What is APA citation style?", &["Author-date", "Numbered", "Footnote", "No citation"], 0, "medium", "remembering"),
          ("What is MLA citation style?", &["Author-date", "Author-page", "Numbered", "Footnote"], 1, "medium", "remembering")],
        &[("What is position paper?", "Position paper", "easy", "remembering"),
          ("What is argumentative essay?", "Argumentative essay", "easy", "remembering"),
          ("What is research paper?", "Research paper", "easy", "remembering"),
          ("What is in-text citation?", "In-text citation", "easy", "remembering"),
          ("What is works cited?", "Works cited", "easy", "remembering")],
        &[],
        eng_comps,
    );

    let eng_exam_qs = build_questions("eng_t3_exam",
        &[("What is the structure of an academic essay?", &["No structure", "Introduction, body, conclusion", "Only body", "Only conclusion"], 1, "easy", "remembering"),
          ("What should a thesis statement do?", &["Be vague", "Be clear and arguable", "Be a question", "Be a story"], 1, "medium", "evaluating"),
          ("What is the purpose of evidence?", &["Fill space", "Support claims", "Entertain", "Confuse"], 1, "easy", "understanding"),
          ("What is analysis in academic writing?", &["Summary", "Interpretation of evidence", "New topic", "Opinion only"], 1, "medium", "understanding"),
          ("What is the purpose of citation?", &["Show off", "Credit sources", "Fill space", "No purpose"], 1, "easy", "understanding"),
          ("What is plagiarism?", &["Proper citation", "Using others' work without credit", "Original work", "Paraphrasing"], 1, "medium", "understanding"),
          ("What is the difference between APA and MLA?", &["No difference", "Discipline and format", "Same format", "Neither exists"], 1, "medium", "analyzing"),
          ("What is a position paper?", &["Story", "Argument on an issue", "Summary", "Question"], 1, "easy", "remembering"),
          ("What is the role of counterarguments?", &["Ignore", "Address opposing views", "Repeat thesis", "No role"], 1, "medium", "evaluating"),
          ("Why is academic writing important?", &["No importance", "Critical thinking and communication", "Only for grades", "Only for scholars"], 1, "difficult", "evaluating")],
        &[("What is academic writing?", "Academic writing", "easy", "remembering"),
          ("What is essay structure?", "Essay structure", "easy", "remembering"),
          ("What is argumentation?", "Argumentation", "easy", "remembering"),
          ("What is research?", "Research", "easy", "remembering"),
          ("What is academic integrity?", "Academic integrity", "easy", "remembering")],
        &[("Write a position paper on a current issue affecting your community. Include a clear thesis, supporting evidence, and counterarguments.", 5, "difficult", "applying"),
          ("Explain the importance of proper citation in academic writing. Discuss the consequences of plagiarism and how to avoid it.", 5, "difficult", "evaluating")],
        eng_comps,
    );

    assessments.push(AssessmentSpec { id: aid("eng_t3_quiz1"), class_id: cid("eng10"), title: "T3 Quiz 1: Features of Academic Writing".into(), description: Some("10-item quiz on academic writing features.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("eng10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: eng_quiz1_qs });
    assessments.push(AssessmentSpec { id: aid("eng_t3_quiz2"), class_id: cid("eng10"), title: "T3 Quiz 2: Claims and Citations".into(), description: Some("10-item quiz on claims and citation styles.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("eng10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: eng_quiz2_qs });
    assessments.push(AssessmentSpec { id: aid("eng_t3_exam"), class_id: cid("eng10"), title: "T3 Term Exam: Academic Writing".into(), description: Some("25-item term assessment on academic writing.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("eng10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: eng_exam_qs });

    // ─── Math 10: Geometry ────────────────────────────────────────────────────
    let math_comps = &[compid("math_t3_comp_0"), compid("math_t3_comp_1"), compid("math_t3_comp_2"), compid("math_t3_comp_3")];

    let math_quiz1_qs = build_questions("math_t3_quiz1",
        &[("What is a geometric sequence?", &["Constant difference", "Constant ratio", "Random", "No pattern"], 1, "easy", "remembering"),
          ("What is the common ratio in 2, 6, 18, 54?", &["2", "3", "4", "6"], 1, "easy", "applying"),
          ("What is the next term in 3, 9, 27, 81?", &["162", "243", "108", "54"], 1, "easy", "applying"),
          ("What is the formula for the nth term?", &["an = a1 + (n-1)d", "an = a1 × r^(n-1)", "an = n + 1", "an = n²"], 1, "medium", "remembering"),
          ("What is the sum of a geometric series?", &["No formula", "Sn = a1(1-r^n)/(1-r)", "Sn = n/2(a1+an)", "Sn = n²"], 1, "medium", "remembering")],
        &[("What is arithmetic sequence?", "Arithmetic sequence", "easy", "remembering"),
          ("What is geometric sequence?", "Geometric sequence", "easy", "remembering"),
          ("What is common difference?", "Common difference", "easy", "remembering"),
          ("What is common ratio?", "Common ratio", "easy", "remembering"),
          ("What is series?", "Series", "easy", "remembering")],
        &[],
        math_comps,
    );

    let math_quiz2_qs = build_questions("math_t3_quiz2",
        &[("What is the sum of 2 + 4 + 8 + 16 + 32?", &["62", "64", "60", "66"], 0, "medium", "applying"),
          ("What is the 5th term of 5, 15, 45, 135?", &["405", "540", "270", "810"], 0, "medium", "applying"),
          ("What is the sum of the first 5 terms of 3, 6, 12, 24, 48?", &["93", "96", "90", "99"], 0, "medium", "applying"),
          ("What happens if |r| > 1?", &["Converges", "Diverges", "No effect", "Oscillates"], 1, "medium", "understanding"),
          ("What happens if |r| < 1?", &["Converges", "Diverges", "No effect", "Oscillates"], 0, "medium", "understanding")],
        &[("What is convergence?", "Convergence", "easy", "remembering"),
          ("What is divergence?", "Divergence", "easy", "remembering"),
          ("What is infinite series?", "Infinite series", "easy", "remembering"),
          ("What is finite series?", "Finite series", "easy", "remembering"),
          ("What is application?", "Application", "easy", "remembering")],
        &[],
        math_comps,
    );

    let math_exam_qs = build_questions("math_t3_exam",
        &[("What is the difference between arithmetic and geometric?", &["No difference", "Addition vs multiplication", "Same", "Random"], 1, "easy", "understanding"),
          ("What is the nth term formula for arithmetic?", &["an = a1 + (n-1)d", "an = a1 × r^(n-1)", "an = n + 1", "an = n²"], 0, "medium", "remembering"),
          ("What is the sum formula for arithmetic?", &["Sn = n/2(a1+an)", "Sn = a1(1-r^n)/(1-r)", "Sn = n²", "Sn = n"], 0, "medium", "remembering"),
          ("When does a geometric series converge?", &["Always", "Never", "|r| < 1", "|r| > 1"], 2, "medium", "understanding"),
          ("What is a real-world application of geometric sequences?", &["No application", "Population growth", "Only math", "Only science"], 1, "medium", "applying"),
          ("What is compound interest?", &["Simple interest", "Geometric growth", "Arithmetic growth", "No interest"], 1, "medium", "understanding"),
          ("What is the sum of infinite geometric series when |r| < 1?", &["No sum", "S = a1/(1-r)", "S = a1 × r", "S = a1 + r"], 1, "difficult", "remembering"),
          ("What is the difference between series and sequence?", &["No difference", "List vs sum", "Same", "Random"], 1, "medium", "understanding"),
          ("What is the role of r in geometric sequence?", &["No role", "Growth factor", "Starting value", "Number of terms"], 1, "medium", "understanding"),
          ("How are geometric sequences used in finance?", &["Not used", "Compound interest", "Simple interest", "Only loans"], 1, "difficult", "applying")],
        &[("What is sequence?", "Sequence", "easy", "remembering"),
          ("What is series?", "Series", "easy", "remembering"),
          ("What is pattern?", "Pattern", "easy", "remembering"),
          ("What is growth?", "Growth", "easy", "remembering"),
          ("What is decay?", "Decay", "easy", "remembering")],
        &[("Solve: Find the sum of the first 10 terms of the geometric sequence 2, 6, 18, 54, ... Show your work.", 5, "difficult", "applying"),
         ("A bacteria culture doubles every hour. If it starts with 100 bacteria, how many will there be after 6 hours? Explain your method.", 5, "difficult", "applying")],
        math_comps,
    );

    assessments.push(AssessmentSpec { id: aid("math_t3_quiz1"), class_id: cid("math10"), title: "T3 Quiz 1: Geometric Sequences".into(), description: Some("10-item quiz on geometric sequences.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("math10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: math_quiz1_qs });
    assessments.push(AssessmentSpec { id: aid("math_t3_quiz2"), class_id: cid("math10"), title: "T3 Quiz 2: Series and Applications".into(), description: Some("10-item quiz on series and applications.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("math10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: math_quiz2_qs });
    assessments.push(AssessmentSpec { id: aid("math_t3_exam"), class_id: cid("math10"), title: "T3 Term Exam: Geometry".into(), description: Some("25-item term assessment on geometric sequences.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("math10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: math_exam_qs });

    // ─── AP 10: Contemporary PH History ────────────────────────────────────
    let ap_comps = &[compid("ap_t3_comp_0"), compid("ap_t3_comp_1"), compid("ap_t3_comp_2"), compid("ap_t3_comp_3")];

    let ap_quiz1_qs = build_questions("ap_t3_quiz1",
        &[("What led to independence in 1946?", &["Spanish withdrawal", "American grant", "Japanese defeat", "Revolution"], 1, "easy", "remembering"),
          ("What was the Third Republic?", &["Spanish period", "American period", "Post-independence", "Japanese period"], 2, "medium", "remembering"),
          ("What was Martial Law?", &["Democratic rule", "Military dictatorship", "Spanish rule", "American rule"], 1, "easy", "remembering"),
          ("When was Martial Law declared?", &["1965", "1972", "1986", "1946"], 1, "medium", "remembering"),
          ("What was the People Power Revolution?", &["1986 uprising", "1896 revolution", "1946 independence", "2001 uprising"], 0, "easy", "remembering")],
        &[("What was independence?", "Independence", "easy", "remembering"),
          ("What was the Third Republic?", "Third Republic", "easy", "remembering"),
          ("What was Martial Law?", "Martial Law", "easy", "remembering"),
          ("What was People Power?", "People Power", "easy", "remembering"),
          ("What was EDSA?", "EDSA", "easy", "remembering")],
        &[],
        ap_comps,
    );

    let ap_quiz2_qs = build_questions("ap_t3_quiz2",
        &[("What are contemporary issues in the Philippines?", &["No issues", "Poverty, corruption, environment", "Only politics", "Only economy"], 1, "medium", "understanding"),
          ("What is the role of youth in nation-building?", &["No role", "Active participation", "Only students", "Only workers"], 1, "medium", "evaluating"),
          ("What is globalization's impact?", &["No impact", "Economic growth and challenges", "Only positive", "Only negative"], 1, "medium", "evaluating"),
          ("What is the importance of history?", &["No importance", "Understanding present", "Only for exams", "Only for scholars"], 1, "medium", "evaluating"),
          ("What is civic responsibility?", &["No responsibility", "Active citizenship", "Only voting", "Only paying taxes"], 1, "medium", "understanding")],
        &[("What is nation-building?", "Nation-building", "easy", "remembering"),
          ("What is globalization?", "Globalization", "easy", "remembering"),
          ("What is civic duty?", "Civic duty", "easy", "remembering"),
          ("What is social responsibility?", "Social responsibility", "easy", "remembering"),
          ("What is environmental awareness?", "Environmental awareness", "easy", "remembering")],
        &[],
        ap_comps,
    );

    let ap_exam_qs = build_questions("ap_t3_exam",
        &[("What was the significance of 1946 independence?", &["No significance", "End of American rule", "Spanish rule", "Japanese rule"], 1, "easy", "understanding"),
          ("What characterized the Third Republic?", &["Dictatorship", "Democratic government", "Colonial rule", "Anarchy"], 1, "medium", "understanding"),
          ("What were the effects of Martial Law?", &["No effects", "Human rights abuses, economic control", "Only economic growth", "Only peace"], 1, "medium", "evaluating"),
          ("What was the 1986 People Power Revolution?", &["Violent coup", "Peaceful uprising", "Foreign invasion", "Civil war"], 1, "easy", "remembering"),
          ("What are contemporary challenges?", &["No challenges", "Corruption, poverty, environment", "Only politics", "Only economy"], 1, "medium", "evaluating"),
          ("What is the role of history in understanding the present?", &["No role", "Explains current issues", "Only for knowledge", "Only for scholars"], 1, "difficult", "evaluating"),
          ("What is the importance of civic engagement?", &["No importance", "Democracy requires participation", "Only for politicians", "Only for adults"], 1, "medium", "evaluating"),
          ("What is the impact of globalization on the Philippines?", &["No impact", "Economic growth and cultural change", "Only economic", "Only cultural"], 1, "medium", "analyzing"),
          ("What is the role of youth in addressing contemporary issues?", &["No role", "Innovation and activism", "Only students", "Only future leaders"], 1, "difficult", "evaluating"),
          ("How can history guide future decisions?", &["No guidance", "Lessons from past", "Only for mistakes", "Only for celebration"], 1, "difficult", "evaluating")],
        &[("What is contemporary history?", "Contemporary history", "easy", "remembering"),
          ("What is democratic governance?", "Democratic governance", "easy", "remembering"),
          ("What is human rights?", "Human rights", "easy", "remembering"),
          ("What is social justice?", "Social justice", "easy", "remembering"),
          ("What is sustainable development?", "Sustainable development", "easy", "remembering")],
        &[("Analyze the impact of Martial Law on Philippine society and democracy. Discuss both the immediate effects and long-term consequences.", 5, "difficult", "evaluating"),
          ("Evaluate contemporary Philippine issues such as poverty, corruption, and environmental degradation. Propose solutions based on historical lessons.", 5, "difficult", "evaluating")],
        ap_comps,
    );

    assessments.push(AssessmentSpec { id: aid("ap_t3_quiz1"), class_id: cid("ap10"), title: "T3 Quiz 1: Independence to Martial Law".into(), description: Some("10-item quiz on post-independence history.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("ap10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: ap_quiz1_qs });
    assessments.push(AssessmentSpec { id: aid("ap_t3_quiz2"), class_id: cid("ap10"), title: "T3 Quiz 2: Contemporary Issues".into(), description: Some("10-item quiz on contemporary issues.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("ap10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: ap_quiz2_qs });
    assessments.push(AssessmentSpec { id: aid("ap_t3_exam"), class_id: cid("ap10"), title: "T3 Term Exam: Contemporary PH History".into(), description: Some("25-item term assessment on contemporary history.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("ap10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: ap_exam_qs });

    // ─── Filipino 10: Sanaysay at Komunikasyon ───────────────────────────────────────
    let fil_comps = &[compid("fil_t3_comp_0"), compid("fil_t3_comp_1"), compid("fil_t3_comp_2"), compid("fil_t3_comp_3")];

    let fil_quiz1_qs = build_questions("fil_t3_quiz1",
        &[("Ano ang sanaysay?", &["Tula", "Maikling kwento", "Akademikong sulatin", "Dula"], 2, "medium", "remembering"),
          ("Ano ang thesis statement?", &["Pangunahing argumento", "Konklusyon", "Ebidensya", "Intro"], 0, "medium", "remembering"),
          ("Ano ang introduction?", &["Panimula sa paksa", "Konklusyon", "Katawan", "Pamagat"], 0, "easy", "remembering"),
          ("Ano ang body paragraph?", &["Panimula", "Katawan", "Konklusyon", "Pamagat"], 1, "easy", "remembering"),
          ("Ano ang conclusion?", &["Panimula", "Katawan", "Konklusyon", "Pamagat"], 2, "medium", "remembering")],
        &[("What is claim?", "Claim", "easy", "remembering"),
          ("What is evidence?", "Evidence", "easy", "remembering"),
          ("What is analysis?", "Analysis", "easy", "remembering"),
          ("What is citation?", "Citation", "easy", "remembering"),
          ("What is academic writing?", "Academic writing", "easy", "remembering")],
        &[],
        fil_comps,
    );

    let fil_quiz2_qs = build_questions("fil_t3_quiz2",
        &[("Ano ang claim of fact?", &["Opinyon", "Verifiable statement", "Tanong", "Kwento"], 1, "medium", "understanding"),
          ("Ano ang claim of value?", &["Verifiable", "Judgment", "Tanong", "Kwento"], 1, "medium", "understanding"),
          ("Ano ang claim of policy?", &["Judgment", "Call to action", "Tanong", "Kwento"], 1, "medium", "understanding"),
          ("Ano ang wastong komunikasyon?", &["Walang paksa", "Malin at maayos", "Maikli lang", "Mahaba lang"], 1, "medium", "evaluating"),
          ("Ano ang kahalagahan ng akademikong pagsulat?", &["Walang kahalagahan", "Critical thinking", "Mga grado lang", "Para sa scholars lang"], 1, "medium", "evaluating")],
        &[("What is position paper?", "Position paper", "easy", "remembering"),
          ("What is argumentative essay?", "Argumentative essay", "easy", "remembering"),
          ("What is research?", "Research", "easy", "remembering"),
          ("What is proper communication?", "Proper communication", "easy", "remembering"),
          ("What is academic integrity?", "Academic integrity", "easy", "remembering")],
        &[],
        fil_comps,
    );

    let fil_exam_qs = build_questions("fil_t3_exam",
        &[("Ano ang istraktura ng sanaysay?", &["Walang istraktura", "Intro, body, conclusion", "Body lang", "Conclusion lang"], 1, "easy", "remembering"),
          ("Ano ang dapat gawin ng thesis statement?", &["Vague", "Malin at arguable", "Tanong", "Kwento"], 1, "medium", "evaluating"),
          ("Ano ang papel ng ebidensya?", &["Fill space", "Support claims", "Entertain", "Confuse"], 1, "easy", "understanding"),
          ("Ano ang analysis sa akademikong pagsulat?", &["Summary", "Interpretation", "New topic", "Opinion only"], 1, "medium", "understanding"),
          ("Ano ang papel ng citation?", &["Show off", "Credit sources", "Fill space", "No purpose"], 1, "easy", "understanding"),
          ("Ano ang plagiarism?", &["Proper citation", "Using others' work without credit", "Original work", "Paraphrasing"], 1, "medium", "understanding"),
          ("Ano ang position paper?", &["Kwento", "Argument on issue", "Summary", "Tanong"], 1, "easy", "remembering"),
          ("Ano ang papel ng counterarguments?", &["Ignore", "Address opposing views", "Repeat thesis", "No role"], 1, "medium", "evaluating"),
          ("Bakit mahalaga ang wastong komunikasyon?", &["Hindi important", "Effective understanding", "Grades lang", "Scholars lang"], 1, "difficult", "evaluating"),
          ("Ano ang kahalagahan ng akademikong integridad?", &["No importance", "Honesty and credibility", "Grades only", "Scholars only"], 1, "difficult", "evaluating")],
        &[("What is academic writing?", "Academic writing", "easy", "remembering"),
          ("What is essay structure?", "Essay structure", "easy", "remembering"),
          ("What is argumentation?", "Argumentation", "easy", "remembering"),
          ("What is research?", "Research", "easy", "remembering"),
          ("What is academic integrity?", "Academic integrity", "easy", "remembering")],
        &[("Sulat ang isang position paper tungkol sa isang isyu sa iyong komunidad. Maglagay ng malin na thesis, ebidensya, at counterarguments.", 5, "difficult", "applying"),
          ("Ipaliwanag ang kahalagahan ng wastong komunikasyon at akademikong integridad. Tukuyin ang mga konsekwensya ng plagiarism at paano iwasan ito.", 5, "difficult", "evaluating")],
        fil_comps,
    );

    assessments.push(AssessmentSpec { id: aid("fil_t3_quiz1"), class_id: cid("fil10"), title: "T3 Quiz 1: Mga Elemento ng Sanaysay".into(), description: Some("10-item quiz on essay elements.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("fil10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: fil_quiz1_qs });
    assessments.push(AssessmentSpec { id: aid("fil_t3_quiz2"), class_id: cid("fil10"), title: "T3 Quiz 2: Claims at Komunikasyon".into(), description: Some("10-item quiz on claims and communication.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("fil10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: fil_quiz2_qs });
    assessments.push(AssessmentSpec { id: aid("fil_t3_exam"), class_id: cid("fil10"), title: "T3 Term Exam: Sanaysay at Komunikasyon".into(), description: Some("25-item term assessment on academic writing.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("fil10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: fil_exam_qs });

    // ─── TLE 10: Entrepreneurship ─────────────────────────────────────────────────
    let tle_comps = &[compid("tle_t3_comp_0"), compid("tle_t3_comp_1"), compid("tle_t3_comp_2"), compid("tle_t3_comp_3")];

    let tle_quiz1_qs = build_questions("tle_t3_quiz1",
        &[("What is entrepreneurship?", &["Working for others", "Starting a business", "No job", "Only studying"], 1, "easy", "remembering"),
          ("What is a business opportunity?", &["No opportunity", "Market need", "Only money", "Only idea"], 1, "medium", "understanding"),
          ("What is a business plan?", &["No plan", "Roadmap for business", "Only budget", "Only marketing"], 1, "medium", "remembering"),
          ("What is capital?", &["No money", "Money to start", "Only profit", "Only loss"], 1, "easy", "remembering"),
          ("What is profit?", &["Loss", "Revenue minus cost", "Only revenue", "Only cost"], 1, "medium", "understanding")],
        &[("What is business?", "Business", "easy", "remembering"),
          ("What is market?", "Market", "easy", "remembering"),
          ("What is product?", "Product", "easy", "remembering"),
          ("What is service?", "Service", "easy", "remembering"),
          ("What is customer?", "Customer", "easy", "remembering")],
        &[],
        tle_comps,
    );

    let tle_quiz2_qs = build_questions("tle_t3_quiz2",
        &[("What is bookkeeping?", &["No record", "Recording financial transactions", "Only spending", "Only earning"], 1, "medium", "remembering"),
          ("What is marketing?", &["No selling", "Promoting products", "Only buying", "Only pricing"], 1, "medium", "understanding"),
          ("What is a target market?", &["Everyone", "Specific customer group", "No market", "Only friends"], 1, "medium", "understanding"),
          ("What is pricing strategy?", &["No strategy", "Setting prices", "Only low prices", "Only high prices"], 1, "medium", "understanding"),
          ("What is customer service?", &["No service", "Helping customers", "Only selling", "Only buying"], 1, "easy", "understanding")],
        &[("What is income?", "Income", "easy", "remembering"),
          ("What is expense?", "Expense", "easy", "remembering"),
          ("What is profit?", "Profit", "easy", "remembering"),
          ("What is loss?", "Loss", "easy", "remembering"),
          ("What is balance sheet?", "Balance sheet", "easy", "remembering")],
        &[],
        tle_comps,
    );

    let tle_exam_qs = build_questions("tle_t3_exam",
        &[("What is the first step in starting a business?", &["No step", "Identify opportunity", "Hire staff", "Buy building"], 1, "medium", "applying"),
          ("What is the purpose of a business plan?", &["No purpose", "Guide operations and attract funding", "Only for banks", "Only for government"], 1, "medium", "understanding"),
          ("What is SWOT analysis?", &["No analysis", "Strengths, Weaknesses, Opportunities, Threats", "Only strengths", "Only weaknesses"], 1, "medium", "remembering"),
          ("What is the role of marketing?", &["No role", "Attract and retain customers", "Only advertising", "Only pricing"], 1, "medium", "understanding"),
          ("What is financial management?", &["No management", "Managing money", "Only spending", "Only earning"], 1, "medium", "understanding"),
          ("What is the importance of customer service?", &["No importance", "Customer satisfaction and loyalty", "Only for complaints", "Only for sales"], 1, "medium", "evaluating"),
          ("What is the difference between product and service?", &["No difference", "Tangible vs intangible", "Same thing", "Only money"], 1, "medium", "analyzing"),
          ("What is the role of innovation in business?", &["No role", "Competitive advantage", "Only for tech", "Only for startups"], 1, "medium", "evaluating"),
          ("What is the importance of ethics in business?", &["No importance", "Trust and reputation", "Only for laws", "Only for profits"], 1, "difficult", "evaluating"),
          ("How does entrepreneurship contribute to the economy?", &["No contribution", "Jobs and growth", "Only taxes", "Only spending"], 1, "difficult", "evaluating")],
        &[("What is entrepreneurship?", "Entrepreneurship", "easy", "remembering"),
          ("What is business plan?", "Business plan", "easy", "remembering"),
          ("What is financial management?", "Financial management", "easy", "remembering"),
          ("What is marketing?", "Marketing", "easy", "remembering"),
          ("What is business ethics?", "Business ethics", "easy", "remembering")],
        &[("Develop a simple business plan for a small business idea in your community. Include the business concept, target market, and basic financial projections.", 5, "difficult", "applying"),
          ("Explain the importance of bookkeeping and financial management for small businesses. What are the risks of poor financial management?", 5, "difficult", "evaluating")],
        tle_comps,
    );

    assessments.push(AssessmentSpec { id: aid("tle_t3_quiz1"), class_id: cid("tle10"), title: "T3 Quiz 1: Business Opportunities".into(), description: Some("10-item quiz on business opportunities.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("tle10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: tle_quiz1_qs });
    assessments.push(AssessmentSpec { id: aid("tle_t3_quiz2"), class_id: cid("tle10"), title: "T3 Quiz 2: Business Operations".into(), description: Some("10-item quiz on business operations.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("tle10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: tle_quiz2_qs });
    assessments.push(AssessmentSpec { id: aid("tle_t3_exam"), class_id: cid("tle10"), title: "T3 Term Exam: Entrepreneurship".into(), description: Some("25-item term assessment on entrepreneurship.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("tle10_tos_t3"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 3, questions: tle_exam_qs });

    assessments
}
