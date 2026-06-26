//! T2 assessments for demo-2: 2 subjects × 3 assessments each (6 total).

use super::super::{aid, build_questions, cid, compid, tid};
use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn demo2_assessments_t2(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(15);
    let now = ctx.now();
    let mut assessments = Vec::with_capacity(6);

    // ─── Science 10: Genetics & Heredity ───────────────────────────────────────
    let sci_comps = &[
        compid("sci_t2_comp_0"),
        compid("sci_t2_comp_1"),
        compid("sci_t2_comp_2"),
        compid("sci_t2_comp_3"),
    ];

    let sci_quiz1_qs = build_questions("sci_t2_quiz1",
        &[("What is the basic unit of heredity?", &["Cell", "Gene", "Chromosome", "DNA"], 1, "easy", "remembering"),
          ("Who is considered the father of genetics?", &["Darwin", "Mendel", "Watson", "Crick"], 1, "easy", "remembering"),
          ("What is the physical appearance of an organism called?", &["Genotype", "Phenotype", "Allele", "Trait"], 1, "easy", "remembering"),
          ("Which molecule carries genetic information?", &["Protein", "RNA", "DNA", "Lipid"], 2, "easy", "remembering"),
          ("What are the different forms of a gene called?", &["Chromosomes", "Alleles", "Traits", "Genotypes"], 1, "medium", "remembering")],
        &[("What is DNA?", "Deoxyribonucleic acid", "easy", "remembering"),
          ("What is a chromosome?", "DNA structure", "easy", "remembering"),
          ("What is heredity?", "Passing of traits", "easy", "remembering"),
          ("What is a dominant trait?", "Dominant trait", "easy", "remembering"),
          ("What is a recessive trait?", "Recessive trait", "easy", "remembering")],
        &[],
        sci_comps,
    );

    let sci_quiz2_qs = build_questions("sci_t2_quiz2",
        &[("What is the process of protein synthesis called?", &["Replication", "Transcription", "Translation", "Mutation"], 2, "medium", "understanding"),
          ("Which base pairs with adenine in DNA?", &["Thymine", "Guanine", "Cytosine", "Uracil"], 0, "easy", "remembering"),
          ("What is the shape of DNA?", &["Linear", "Circular", "Double helix", "Triple helix"], 2, "easy", "remembering"),
          ("What organelle is the site of protein synthesis?", &["Nucleus", "Ribosome", "Mitochondria", "Golgi"], 1, "easy", "remembering"),
          ("What is a change in DNA sequence called?", &["Variation", "Mutation", "Adaptation", "Evolution"], 1, "medium", "understanding")],
        &[("What is transcription?", "Transcription", "easy", "remembering"),
          ("What is translation?", "Translation", "easy", "remembering"),
          ("What is a codon?", "Codon", "easy", "remembering"),
          ("What is an anticodon?", "Anticodon", "easy", "remembering"),
          ("What is RNA?", "Ribonucleic acid", "easy", "remembering")],
        &[],
        sci_comps,
    );

    let sci_exam_qs = build_questions("sci_t2_exam",
        &[("What did Mendel study in his experiments?", &["Humans", "Pea plants", "Fruit flies", "Mice"], 1, "easy", "remembering"),
          ("What is Mendel's first law?", &["Law of Segregation", "Law of Independent Assortment", "Law of Dominance", "Law of Heredity"], 0, "medium", "understanding"),
          ("What is the genotype of a homozygous dominant individual?", &["AA", "Aa", "aa", "AA or Aa"], 0, "medium", "applying"),
          ("What is the probability of two heterozygous parents having a homozygous recessive child?", &["0%", "25%", "50%", "75%"], 1, "medium", "applying"),
          ("What is natural selection?", &["Random change", "Survival of fittest", "Genetic drift", "Mutation"], 1, "easy", "understanding"),
          ("What structure makes up DNA?", &["Nucleotides", "Amino acids", "Proteins", "Lipids"], 0, "easy", "remembering"),
          ("What is the role of mRNA in protein synthesis?", &["Carries DNA info", "Makes proteins", "Provides energy", "Stores DNA"], 0, "medium", "understanding"),
          ("What is the difference between DNA and RNA?", &["Sugar and base", "Only sugar", "Only base", "No difference"], 0, "difficult", "analyzing"),
          ("What causes genetic variation?", &["Mutation only", "Mutation and recombination", "Environment only", "No variation"], 1, "medium", "understanding"),
          ("What is the result of a frameshift mutation?", &["No change", "One amino acid change", "All downstream changes", "Protein deletion"], 2, "difficult", "analyzing")],
        &[("What is homozygous?", "Homozygous", "easy", "remembering"),
          ("What is heterozygous?", "Heterozygous", "easy", "remembering"),
          ("What is a Punnett square?", "Punnett square", "easy", "remembering"),
          ("What is evolution?", "Evolution", "easy", "remembering"),
          ("What is adaptation?", "Adaptation", "easy", "remembering")],
        &[("Explain how Mendel's laws apply to human inheritance. Give an example of a trait that follows Mendelian patterns and explain how it is passed from parents to offspring.", 5, "difficult", "applying"),
          ("Describe the process of protein synthesis from DNA to functional protein. Include the roles of transcription, translation, mRNA, tRNA, and ribosomes in your explanation.", 5, "difficult", "analyzing")],
        sci_comps,
    );

    assessments.push(AssessmentSpec { id: aid("sci_t2_quiz1"), class_id: cid("sci10"), title: "T2 Quiz 1: Introduction to Genetics".into(), description: Some("10-item quiz on basic genetics concepts.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("sci10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: sci_quiz1_qs });
    assessments.push(AssessmentSpec { id: aid("sci_t2_quiz2"), class_id: cid("sci10"), title: "T2 Quiz 2: DNA & Protein Synthesis".into(), description: Some("10-item quiz on DNA structure and protein synthesis.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("sci10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: sci_quiz2_qs });
    assessments.push(AssessmentSpec { id: aid("sci_t2_exam"), class_id: cid("sci10"), title: "T2 Term Exam: Genetics & Heredity".into(), description: Some("25-item term assessment on genetics and heredity.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("sci10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: sci_exam_qs });

//     // ─── English 10: World Literature ───────────────────────────────────────────
//     let eng_comps = &[compid("eng_t2_comp_0"), compid("eng_t2_comp_1"), compid("eng_t2_comp_2"), compid("eng_t2_comp_3")];
// 
//     let eng_quiz1_qs = build_questions("eng_t2_quiz1",
//         &[("What is a 21st century literary genre?", &["Epic", "Flash fiction", "Sonnet", "Haiku"], 1, "medium", "remembering"),
//           ("What is speculative fiction?", &["Realistic stories", "Science fiction and fantasy", "Historical fiction", "Biography"], 1, "medium", "understanding"),
//           ("What is chick lit?", &["Horror", "Women's contemporary fiction", "Mystery", "Science fiction"], 1, "medium", "remembering"),
//           ("What is graphic literature?", &["Text only", "Comics and graphic novels", "Audio books", "Poetry"], 1, "easy", "remembering"),
//           ("What is hyperpoetry?", &["Traditional poetry", "Digital poetry", "Epic poetry", "Lyric poetry"], 1, "medium", "remembering")],
//         &[("What is flash fiction?", "Flash fiction", "easy", "remembering"),
//           ("What is speculative fiction?", "Speculative fiction", "easy", "remembering"),
//           ("What is chick lit?", "Chick lit", "easy", "remembering"),
//           ("What is graphic novel?", "Graphic novel", "easy", "remembering"),
//           ("What is hyperpoetry?", "Hyperpoetry", "easy", "remembering")],
//         &[],
//         eng_comps,
//     );
// 
//     let eng_quiz2_qs = build_questions("eng_t2_quiz2",
//         &[("What is the relationship between text and context?", &["No relationship", "Context shapes meaning", "Text is independent", "Context is irrelevant"], 1, "medium", "understanding"),
//           ("What is intertextuality?", &["No text connection", "Text referencing other texts", "Independent texts", "Same author only"], 1, "difficult", "understanding"),
//           ("What is reader-response criticism?", &["Author-focused", "Reader-focused", "Text-focused", "Historical"], 1, "medium", "understanding"),
//           ("What is the role of the reader in literature?", &["Passive", "Active creator of meaning", "Irrelevant", "Observer only"], 1, "medium", "evaluating"),
//           ("What is cultural context?", &["No importance", "Important for meaning", "Always the same", "Universal only"], 1, "easy", "understanding")],
//         &[("What is context?", "Context", "easy", "remembering"),
//           ("What is intertextuality?", "Intertextuality", "easy", "remembering"),
//           ("What is reader-response?", "Reader-response", "easy", "remembering"),
//           ("What is cultural context?", "Cultural context", "easy", "remembering"),
//           ("What is historical context?", "Historical context", "easy", "remembering")],
//         &[],
//         eng_comps,
//     );
// 
//     let eng_exam_qs = build_questions("eng_t2_exam",
//         &[("What is a characteristic of 21st century literature?", &["Traditional only", "Diverse genres", "No change", "Print only"], 1, "easy", "remembering"),
//           ("What is the purpose of literature?", &["Entertainment only", "Mirror of life", "No purpose", "Education only"], 1, "medium", "evaluating"),
//           ("What is the relationship between literature and society?", &["No relationship", "Literature reflects society", "Society follows literature", "Independent"], 1, "medium", "analyzing"),
//           ("What is the role of the author?", &["Irrelevant", "Creates text", "Only reader matters", "No role"], 1, "medium", "understanding"),
//           ("What is world literature?", &["One country only", "Literature from all cultures", "English only", "Classic only"], 1, "easy", "remembering"),
//           ("What is the difference between traditional and 21st century literature?", &["No difference", "Format and medium", "Same content", "Only language"], 1, "medium", "analyzing"),
//           ("What is the importance of studying world literature?", &["No importance", "Cultural understanding", "Waste of time", "Only for majors"], 1, "medium", "evaluating"),
//           ("What is the role of technology in 21st century literature?", &["No role", "Digital formats", "Print only", "Negative impact"], 1, "medium", "analyzing"),
//           ("What is global literature?", &["Local only", "Transnational", "Regional", "National"], 1, "medium", "remembering"),
//           ("What is the impact of globalization on literature?", &["No impact", "Cross-cultural exchange", "Less diversity", "Only English"], 1, "difficult", "evaluating")],
//         &[("What is 21st century literature?", "21st century literature", "easy", "remembering"),
//           ("What is world literature?", "World literature", "easy", "remembering"),
//           ("What is globalization?", "Globalization", "easy", "remembering"),
//           ("What is cultural exchange?", "Cultural exchange", "easy", "remembering"),
//           ("What is diversity in literature?", "Diversity", "easy", "remembering")],
//         &[("Analyze how a 21st century literary work reflects contemporary global issues. Use specific examples from a work you have studied to support your analysis.", 5, "difficult", "evaluating"),
//           ("Compare a traditional literary work with a 21st century work. How do they differ in form, content, and approach to universal themes?", 5, "difficult", "analyzing")],
//         eng_comps,
//     );
// 
//     assessments.push(AssessmentSpec { id: aid("eng_t2_quiz1"), class_id: cid("eng10"), title: "T2 Quiz 1: 21st Century Literary Genres".into(), description: Some("10-item quiz on contemporary literary genres.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("eng10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: eng_quiz1_qs });
//     assessments.push(AssessmentSpec { id: aid("eng_t2_quiz2"), class_id: cid("eng10"), title: "T2 Quiz 2: Text and Context".into(), description: Some("10-item quiz on literary analysis and context.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("eng10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: eng_quiz2_qs });
//     assessments.push(AssessmentSpec { id: aid("eng_t2_exam"), class_id: cid("eng10"), title: "T2 Term Exam: World Literature".into(), description: Some("25-item term assessment on world literature.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("eng10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: eng_exam_qs });
// 
    // ─── Math 10: Quadratic Functions ────────────────────────────────────────────
    let math_comps = &[compid("math_t2_comp_0"), compid("math_t2_comp_1"), compid("math_t2_comp_2"), compid("math_t2_comp_3")];

    let math_quiz1_qs = build_questions("math_t2_quiz1",
        &[("What is the standard form of a quadratic function?", &["y = mx + b", "y = ax² + bx + c", "y = a/x", "y = √x"], 1, "easy", "remembering"),
          ("What is the graph of a quadratic function called?", &["Line", "Parabola", "Circle", "Ellipse"], 1, "easy", "remembering"),
          ("What determines if a parabola opens up or down?", &["b value", "c value", "a value", "x value"], 2, "easy", "remembering"),
          ("What is the vertex of a parabola?", &["Maximum or minimum point", "X-intercept", "Y-intercept", "Origin"], 0, "medium", "understanding"),
          ("What is the axis of symmetry?", &["Vertical line through vertex", "Horizontal line", "X-axis", "Y-axis"], 0, "medium", "understanding")],
        &[("What is a quadratic function?", "Quadratic function", "easy", "remembering"),
          ("What is a parabola?", "Parabola", "easy", "remembering"),
          ("What is the vertex?", "Vertex", "easy", "remembering"),
          ("What is the axis of symmetry?", "Axis of symmetry", "easy", "remembering"),
          ("What is the discriminant?", "Discriminant", "easy", "remembering")],
        &[],
        math_comps,
    );

    let math_quiz2_qs = build_questions("math_t2_quiz2",
        &[("What method solves quadratic equations by completing the square?", &["Factoring", "Quadratic formula", "Completing the square", "Graphing"], 2, "easy", "remembering"),
          ("What is the quadratic formula?", &["x = -b ± √(b²-4ac)/2a", "x = b ± √(b²-4ac)/2a", "x = -b ± √(b²+4ac)/2a", "x = b ± √(b²+4ac)/2a"], 0, "medium", "remembering"),
          ("What does the discriminant tell us?", &["Number of solutions", "Y-intercept", "X-intercept", "Vertex"], 0, "medium", "understanding"),
          ("If discriminant > 0, how many solutions?", &["0", "1", "2", "Infinite"], 2, "medium", "applying"),
          ("If discriminant = 0, how many solutions?", &["0", "1", "2", "Infinite"], 1, "medium", "applying")],
        &[("What is factoring?", "Factoring", "easy", "remembering"),
          ("What is the quadratic formula?", "Quadratic formula", "easy", "remembering"),
          ("What is completing the square?", "Completing the square", "easy", "remembering"),
          ("What is the discriminant?", "Discriminant", "easy", "remembering"),
          ("What are real solutions?", "Real solutions", "easy", "remembering")],
        &[],
        math_comps,
    );

    let math_exam_qs = build_questions("math_t2_exam",
        &[("What is the vertex form of a quadratic function?", &["y = ax² + bx + c", "y = a(x-h)² + k", "y = mx + b", "y = a/x"], 1, "medium", "remembering"),
          ("What is the effect of 'a' on the parabola?", &["Direction and width", "Only direction", "Only width", "No effect"], 0, "medium", "understanding"),
          ("What is the effect of 'h' in vertex form?", &["Horizontal shift", "Vertical shift", "Width", "Direction"], 0, "medium", "understanding"),
          ("What is the effect of 'k' in vertex form?", &["Horizontal shift", "Vertical shift", "Width", "Direction"], 1, "medium", "understanding"),
          ("How do you find the vertex from standard form?", &["Read directly", "Use formula", "Graph only", "Cannot find"], 1, "medium", "applying"),
          ("What is the relationship between the vertex and the axis of symmetry?", &["No relationship", "Vertex lies on axis", "Perpendicular", "Parallel"], 1, "easy", "understanding"),
          ("What is the x-coordinate of the vertex?", &["-b/2a", "b/2a", "-b/a", "b/a"], 0, "medium", "applying"),
          ("When is factoring the best method?", &["Always", "When easily factorable", "Never", "Only for integers"], 1, "medium", "evaluating"),
          ("What is the advantage of the quadratic formula?", &["Works for all", "Only some", "No advantage", "Too complex"], 0, "medium", "evaluating"),
          ("What is the disadvantage of graphing?", &["Precise", "Approximate", "Always works", "No disadvantage"], 1, "medium", "evaluating")],
        &[("What is vertex form?", "Vertex form", "easy", "remembering"),
          ("What is standard form?", "Standard form", "easy", "remembering"),
          ("What is the vertex formula?", "Vertex formula", "easy", "remembering"),
          ("What are the methods for solving quadratics?", "Solving methods", "easy", "remembering"),
          ("What is the discriminant formula?", "Discriminant formula", "easy", "remembering")],
        &[("Solve the quadratic equation x² - 5x + 6 = 0 using factoring. Show your work and verify your solutions.", 5, "difficult", "applying"),
          ("A ball is thrown upward with an initial velocity of 20 m/s from a height of 5 meters. The height h(t) = -5t² + 20t + 5. Find the maximum height and when it occurs. Explain your method.", 5, "difficult", "applying")],
        math_comps,
    );

    assessments.push(AssessmentSpec { id: aid("math_t2_quiz1"), class_id: cid("math10"), title: "T2 Quiz 1: Quadratic Functions".into(), description: Some("10-item quiz on quadratic functions and parabolas.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("math10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: math_quiz1_qs });
    assessments.push(AssessmentSpec { id: aid("math_t2_quiz2"), class_id: cid("math10"), title: "T2 Quiz 2: Solving Quadratic Equations".into(), description: Some("10-item quiz on solving quadratic equations.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("math10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: math_quiz2_qs });
    assessments.push(AssessmentSpec { id: aid("math_t2_exam"), class_id: cid("math10"), title: "T2 Term Exam: Quadratic Functions".into(), description: Some("25-item term assessment on quadratic functions.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("math10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: math_exam_qs });

//     // ─── AP 10: Revolution & American Period ────────────────────────────────────
//     let ap_comps = &[compid("ap_t2_comp_0"), compid("ap_t2_comp_1"), compid("ap_t2_comp_2"), compid("ap_t2_comp_3")];
// 
//     let ap_quiz1_qs = build_questions("ap_t2_quiz1",
//         &[("What caused the Philippine Revolution?", &["Spanish oppression", "American invasion", "Japanese occupation", "Internal conflict"], 0, "easy", "remembering"),
//           ("Who led the Katipunan?", &["Rizal", "Bonifacio", "Mabini", "Aguinaldo"], 1, "easy", "remembering"),
//           ("What was the Cry of Pugad Lawin?", &["Start of revolution", "End of revolution", "Spanish victory", "American arrival"], 0, "medium", "remembering"),
//           ("What was the KKK?", &["Social club", "Revolutionary society", "Spanish group", "American organization"], 1, "easy", "remembering"),
//           ("Who was the first president of the Philippines?", &["Bonifacio", "Rizal", "Aguinaldo", "Mabini"], 2, "easy", "remembering")],
//         &[("What was the Katipunan?", "Katipunan", "easy", "remembering"),
//           ("What was the Cry of Balintawak?", "Cry of Balintawak", "easy", "remembering"),
//           ("What was the Tejeros Convention?", "Tejeros Convention", "easy", "remembering"),
//           ("What was the Pact of Biak-na-Bato?", "Pact of Biak-na-Bato", "easy", "remembering"),
//           ("What was the revolutionary government?", "Revolutionary government", "easy", "remembering")],
//         &[],
//         ap_comps,
//     );
// 
//     let ap_quiz2_qs = build_questions("ap_t2_quiz2",
//         &[("What ended the Spanish-American War?", &["Treaty of Paris", "Treaty of Versailles", "Treaty of Manila", "No treaty"], 0, "medium", "remembering"),
//           ("What did the Treaty of Paris do?", &["Gave Philippines to US", "Gave Philippines to Spain", "Philippines independent", "No change"], 0, "medium", "understanding"),
//           ("What was the Philippine-American War?", &["Spanish vs US", "Philippines vs US", "Civil war", "World war"], 1, "easy", "remembering"),
//           ("What was the policy of attraction?", &["Military force", "Education and reform", "Isolation", "Trade only"], 1, "medium", "understanding"),
//           ("What was the Thomasites?", &["Soldiers", "Teachers", "Doctors", "Engineers"], 1, "medium", "remembering")],
//         &[("What was the Treaty of Paris?", "Treaty of Paris", "easy", "remembering"),
//           ("What was the Philippine-American War?", "Philippine-American War", "easy", "remembering"),
//           ("What was the policy of attraction?", "Policy of attraction", "easy", "remembering"),
//           ("What was the public school system?", "Public school system", "easy", "remembering"),
//           ("What was the Jones Law?", "Jones Law", "easy", "remembering")],
//         &[],
//         ap_comps,
//     );
// 
//     let ap_exam_qs = build_questions("ap_t2_exam",
//         &[("What was the main cause of the revolution?", &["Taxation", "Oppression and abuses", "Religion", "Trade"], 1, "easy", "understanding"),
//           ("What was the role of the propaganda movement?", &["Armed struggle", "Peaceful reform", "No role", "Spanish support"], 1, "medium", "understanding"),
//           ("What was the conflict between Bonifacio and Aguinaldo?", &["No conflict", "Leadership dispute", "Ideological", "Personal only"], 1, "medium", "analyzing"),
//           ("What was the result of the Pact of Biak-na-Bato?", &["End of revolution", "Temporary truce", "Spanish victory", "Independence"], 1, "medium", "understanding"),
//           ("What was American rule characterized by?", &["Freedom only", "Education and control", "No control", "Total freedom"], 1, "medium", "evaluating"),
//           ("What was the impact of American education?", &["No impact", "Modernization", "Decline", "Mixed"], 1, "difficult", "evaluating"),
//           ("What was the Jones Law?", &["Independence", "Promise of independence", "No change", "Spanish law"], 1, "medium", "remembering"),
//           ("What was the Tydings-McDuffie Act?", &["Independence promise", "Trade agreement", "Military aid", "No significance"], 0, "medium", "remembering"),
//           ("What was the Commonwealth period?", &["Spanish rule", "American transition", "Japanese occupation", "Independence"], 1, "medium", "understanding"),
//           ("What was the impact of American colonization?", &["Only positive", "Only negative", "Mixed effects", "No impact"], 2, "difficult", "evaluating")],
//         &[("What was the propaganda movement?", "Propaganda movement", "easy", "remembering"),
//           ("What was the Katipunan?", "Katipunan", "easy", "remembering"),
//           ("What was the revolutionary government?", "Revolutionary government", "easy", "remembering"),
//           ("What was the Malolos Congress?", "Malolos Congress", "easy", "remembering"),
//           ("What was the Commonwealth?", "Commonwealth", "easy", "remembering")],
//         &[("Analyze the causes and consequences of the Philippine Revolution. Discuss the key events and figures that shaped this period.", 5, "difficult", "evaluating"),
//           ("Evaluate the impact of American colonial rule on Philippine society, education, and government. Discuss both positive and negative effects.", 5, "difficult", "evaluating")],
//         ap_comps,
//     );
// 
//     assessments.push(AssessmentSpec { id: aid("ap_t2_quiz1"), class_id: cid("ap10"), title: "T2 Quiz 1: The Philippine Revolution".into(), description: Some("10-item quiz on the Philippine Revolution.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("ap10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: ap_quiz1_qs });
//     assessments.push(AssessmentSpec { id: aid("ap_t2_quiz2"), class_id: cid("ap10"), title: "T2 Quiz 2: The American Period".into(), description: Some("10-item quiz on the American colonial period.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("ap10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: ap_quiz2_qs });
//     assessments.push(AssessmentSpec { id: aid("ap_t2_exam"), class_id: cid("ap10"), title: "T2 Term Exam: Revolution & American Period".into(), description: Some("25-item term assessment on the revolution and American period.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("ap10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: ap_exam_qs });
// 
//     // ─── Filipino 10: Tula at Dula ───────────────────────────────────────────────
//     let fil_comps = &[compid("fil_t2_comp_0"), compid("fil_t2_comp_1"), compid("fil_t2_comp_2"), compid("fil_t2_comp_3")];
// 
//     let fil_quiz1_qs = build_questions("fil_t2_quiz1",
//         &[("Ano ang tawag sa maikling tula na may 7 pantig?", &["Haiku", "Tanaga", "Soneto", "Diona"], 1, "medium", "remembering"),
//           ("Ano ang tawag sa tula na may 14 na linya?", &["Tanaga", "Soneto", "Haiku", "Diona"], 1, "medium", "remembering"),
//           ("Ano ang sukat ng tula?", &["Lengguwahe", "Tugma at sukat", "Tema", "Sentimento"], 1, "easy", "remembering"),
//           ("Ano ang tugma?", &["Magkatulad na tunog", "Magkaiba", "Walang kahulugan", "Tambalan"], 0, "easy", "remembering"),
//           ("Ano ang tayutay?", &["Wika", "Retorika", "Gamit ng salita", "Lengguwahe"], 2, "medium", "understanding")],
//         &[("Ano ang tanaga?", "Tanaga", "easy", "remembering"),
//           ("Ano ang soneto?", "Soneto", "easy", "remembering"),
//           ("Ano ang haiku?", "Haiku", "easy", "remembering"),
//           ("Ano ang diona?", "Diona", "easy", "remembering"),
//           ("Ano ang sukat?", "Sukat", "easy", "remembering")],
//         &[],
//         fil_comps,
//     );
// 
//     let fil_quiz2_qs = build_questions("fil_t2_quiz2",
//         &[("Ano ang dula?", &["Tula", "Dula", "Kuwento", "Sanaysay"], 1, "easy", "remembering"),
//           ("Ano ang tauhan sa dula?", &["Nagtatanghal", "Mga karakter", "Manonood", "Direktor"], 1, "easy", "remembering"),
//           ("Ano ang dialogo?", &["Monologo", "Usapan", "Aksyon", "Kanta"], 1, "easy", "remembering"),
//           ("Ano ang stage direction?", &["Direksyon", "Tagubilin sa pag-arte", "Plot", "Tema"], 1, "medium", "remembering"),
//           ("Ano ang uri ng dula?", &["Tragedya, Komedya", "Tula lang", "Kuwento", "Sanaysay"], 0, "medium", "remembering")],
//         &[("Ano ang tragedya?", "Tragedya", "easy", "remembering"),
//           ("Ano ang komedya?", "Komedya", "easy", "remembering"),
//           ("Ano ang melodrama?", "Melodrama", "easy", "remembering"),
//           ("Ano ang farce?", "Farce", "easy", "remembering"),
//           ("Ano ang dialogo?", "Dialogo", "easy", "remembering")],
//         &[],
//         fil_comps,
//     );
// 
//     let fil_exam_qs = build_questions("fil_t2_exam",
//         &[("Ano ang elemento ng tula?", &["Tema", "Lahat ng nabanggit", "Wala", "Plot"], 1, "easy", "remembering"),
//           ("Ano ang elemento ng dula?", &["Tauhan, dialogo, aksyon", "Lahat ng nabanggit", "Wala", "Tema"], 0, "easy", "remembering"),
//           ("Ano ang papel ng direktor?", &["Walang papel", "Nagdidirekta", "Nanonood", "Nagsusulat"], 1, "medium", "understanding"),
//           ("Ano ang papel ng aktor?", &["Walang papel", "Nagtatanghal", "Nanonood", "Nagsusulat"], 1, "easy", "remembering"),
//           ("Ano ang pagkakaiba ng tula at dula?", &["Walang pagkakaiba", "Tula isinasayaw, dula binabasa", "Tula binabasa, dula isinasayaw", " pareho"], 2, "medium", "analyzing"),
//           ("Ano ang tayutay na gumagamit ng 'parang'?", &["Simili", "Metapora", "Personipikasyon", "Hiperbola"], 0, "medium", "understanding"),
//           ("Ano ang tayutay na pagbibigay ng buhay sa bagay?", &["Simili", "Metapora", "Personipikasyon", "Hiperbola"], 2, "medium", "understanding"),
//           ("Ano ang tayutay na pagpapalaki?", &["Simili", "Metapora", "Personipikasyon", "Hiperbola"], 3, "medium", "understanding"),
//           ("Ano ang tayutay na paghahambing?", &["Simili", "Metapora", "Personipikasyon", "Hiperbola"], 0, "easy", "remembering"),
//           ("Ano ang tayutay na direktang paghahalintulad?", &["Simili", "Metapora", "Personipikasyon", "Hiperbola"], 1, "medium", "understanding")],
//         &[("Ano ang elemento ng tula?", "Elemento", "easy", "remembering"),
//           ("Ano ang elemento ng dula?", "Elemento", "easy", "remembering"),
//           ("Ano ang direktor?", "Direktor", "easy", "remembering"),
//           ("Ano ang aktor?", "Aktor", "easy", "remembering"),
//           ("Ano ang manonood?", "Manonood", "easy", "remembering")],
//         &[("Suriin ang gamit ng mga tayutay sa isang tula. Paano nakatulong ang mga ito sa pagpapahayag ng mensahe ng tula?", 5, "difficult", "evaluating"),
//           ("Ihambing ang isang tula at isang dula. Ano ang pagkakatulad at pagkakaiba ng mga ito sa pagpapahayag ng tema?", 5, "difficult", "evaluating")],
//         fil_comps,
//     );
// 
//     assessments.push(AssessmentSpec { id: aid("fil_t2_quiz1"), class_id: cid("fil10"), title: "T2 Quiz 1: Mga Anyo ng Tula".into(), description: Some("10-item quiz on forms of poetry.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("fil10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: fil_quiz1_qs });
//     assessments.push(AssessmentSpec { id: aid("fil_t2_quiz2"), class_id: cid("fil10"), title: "T2 Quiz 2: Mga Elemento ng Dula".into(), description: Some("10-item quiz on elements of drama.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("fil10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: fil_quiz2_qs });
//     assessments.push(AssessmentSpec { id: aid("fil_t2_exam"), class_id: cid("fil10"), title: "T2 Term Exam: Tula at Dula".into(), description: Some("25-item term assessment on poetry and drama.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("fil10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: fil_exam_qs });
// 
//     // ─── TLE 10: Cookery ─────────────────────────────────────────────────────────
//     let tle_comps = &[compid("tle_t2_comp_0"), compid("tle_t2_comp_1"), compid("tle_t2_comp_2"), compid("tle_t2_comp_3")];
// 
//     let tle_quiz1_qs = build_questions("tle_t2_quiz1",
//         &[("What is a chef's knife used for?", &["Baking", "General cutting", "Frying", "Boiling"], 1, "easy", "remembering"),
//           ("What is a cutting board used for?", &["Cooking", "Cutting surface", "Serving", "Storage"], 1, "easy", "remembering"),
//           ("What is Mise en place?", &["Cooking method", "Preparation", "Serving", "Cleaning"], 1, "medium", "remembering"),
//           ("What is a measuring cup used for?", &["Cutting", "Measuring ingredients", "Cooking", "Serving"], 1, "easy", "remembering"),
//           ("What is a mixing bowl used for?", &["Cutting", "Mixing ingredients", "Cooking", "Serving"], 1, "easy", "remembering")],
//         &[("What is a chef's knife?", "Chef's knife", "easy", "remembering"),
//           ("What is a cutting board?", "Cutting board", "easy", "remembering"),
//           ("What is Mise en place?", "Mise en place", "easy", "remembering"),
//           ("What is a measuring cup?", "Measuring cup", "easy", "remembering"),
//           ("What is a mixing bowl?", "Mixing bowl", "easy", "remembering")],
//         &[],
//         tle_comps,
//     );
// 
//     let tle_quiz2_qs = build_questions("tle_t2_quiz2",
//         &[("What is egg cookery?", &["Cooking eggs", "Cooking meat", "Cooking vegetables", "Baking"], 0, "easy", "remembering"),
//           ("What is a hard-boiled egg?", &["Raw", "Cooked in shell", "Fried", "Scrambled"], 1, "easy", "remembering"),
//           ("What is a poached egg?", &["Fried", "Cooked in water", "Boiled in shell", "Scrambled"], 1, "medium", "remembering"),
//           ("What is an omelet?", &["Fried egg", "Beaten egg cooked", "Boiled egg", "Raw egg"], 1, "easy", "remembering"),
//           ("What is food safety?", &["No importance", "Preventing illness", "Only for restaurants", "Optional"], 1, "medium", "understanding")],
//         &[("What is egg cookery?", "Egg cookery", "easy", "remembering"),
//           ("What is a hard-boiled egg?", "Hard-boiled egg", "easy", "remembering"),
//           ("What is a poached egg?", "Poached egg", "easy", "remembering"),
//           ("What is an omelet?", "Omelet", "easy", "remembering"),
//           ("What is food safety?", "Food safety", "easy", "remembering")],
//         &[],
//         tle_comps,
//     );
// 
//     let tle_exam_qs = build_questions("tle_t2_exam",
//         &[("What is the importance of knife skills?", &["No importance", "Efficiency and safety", "Only for chefs", "Optional"], 1, "medium", "evaluating"),
//           ("What is the proper way to hold a knife?", &["Loose grip", "Firm grip", "One finger", "No grip"], 1, "medium", "applying"),
//           ("What is the difference between chopping and dicing?", &["No difference", "Size of pieces", "Tool used", "Time"], 1, "medium", "understanding"),
//           ("What is the proper temperature for cooking eggs?", &["Any temperature", "Medium heat", "High heat only", "Low heat only"], 1, "medium", "applying"),
//           ("What is cross-contamination?", &["No concern", "Mixing raw and cooked", "Proper technique", "Cooking method"], 1, "medium", "understanding"),
//           ("What is the danger zone for food?", &["No danger", "4-60°C", "Below 0°C", "Above 100°C"], 1, "medium", "remembering"),
//           ("What is proper hand washing?", &["No importance", "20 seconds with soap", "Water only", "Optional"], 1, "medium", "applying"),
//           ("What is the purpose of aprons?", &["Fashion", "Protection", "No purpose", "Decoration"], 1, "easy", "understanding"),
//           ("What is the importance of clean workspace?", &["No importance", "Prevents contamination", "Optional", "Only for inspection"], 1, "medium", "evaluating"),
//           ("What is the proper storage of eggs?", &["Anywhere", "Refrigerated", "Freezer", "Room temperature"], 1, "medium", "applying")],
//         &[("What is knife safety?", "Knife safety", "easy", "remembering"),
//           ("What is food sanitation?", "Food sanitation", "easy", "remembering"),
//           ("What is proper food handling?", "Proper food handling", "easy", "remembering"),
//           ("What is kitchen safety?", "Kitchen safety", "easy", "remembering"),
//           ("What is food storage?", "Food storage", "easy", "remembering")],
//         &[("Describe the step-by-step process of preparing a vegetable omelet. Include knife skills, cooking techniques, and safety precautions.", 5, "difficult", "applying"),
//           ("Explain the importance of food safety in egg cookery. What are the risks of improper handling and how can they be prevented?", 5, "difficult", "evaluating")],
//         tle_comps,
//     );
// 
//     assessments.push(AssessmentSpec { id: aid("tle_t2_quiz1"), class_id: cid("tle10"), title: "T2 Quiz 1: Kitchen Tools & Equipment".into(), description: Some("10-item quiz on kitchen tools and equipment.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("tle10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: tle_quiz1_qs });
//     assessments.push(AssessmentSpec { id: aid("tle_t2_quiz2"), class_id: cid("tle10"), title: "T2 Quiz 2: Egg Cookery".into(), description: Some("10-item quiz on egg cookery methods.".into()), time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1), show_results_immediately: true, total_points: 10, component: "written_work".into(), tos_id: tid("tle10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: tle_quiz2_qs });
//     assessments.push(AssessmentSpec { id: aid("tle_t2_exam"), class_id: cid("tle10"), title: "T2 Term Exam: Cookery".into(), description: Some("25-item term assessment on cookery.".into()), time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2), show_results_immediately: true, total_points: 25, component: "term_assessment".into(), tos_id: tid("tle10_tos_t2"), created_at: created, deleted_at: None, is_published: true, results_released: true, term_number: 2, questions: tle_exam_qs });
// 
    assessments
}
