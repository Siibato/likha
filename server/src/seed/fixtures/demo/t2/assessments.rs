//! T2 assessments for demo seeding: Genetics & Heredity.

use super::super::{aid, build_questions, cid, compid, tid};
use crate::seed::specs::*;
use crate::seed::tools::SeedContext;

pub fn demo_assessments_t2(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(20);
    let now = ctx.now();
    let comps = &[
        compid("s10t2_comp_0"),
        compid("s10t2_comp_1"),
        compid("s10t2_comp_2"),
        compid("s10t2_comp_3"),
    ];

    let quiz1_qs = build_questions(
        "t2_quiz1",
        &[
            (
                "What does DNA stand for?",
                &[
                    "Deoxyribonucleic acid",
                    "Dinucleotide amino acid",
                    "Double helix nucleic acid",
                    "Deoxyribose amino acid",
                ],
                0,
                "easy",
                "remembering",
            ),
            (
                "Which nitrogenous base pairs with adenine in DNA?",
                &["Cytosine", "Guanine", "Thymine", "Uracil"],
                2,
                "easy",
                "remembering",
            ),
            (
                "What is the function of mRNA?",
                &[
                    "Store genetic information",
                    "Carry amino acids",
                    "Carry genetic code to ribosomes",
                    "Build cell walls",
                ],
                2,
                "medium",
                "understanding",
            ),
            (
                "Where does protein synthesis occur in the cell?",
                &["Nucleus", "Ribosome", "Mitochondria", "Golgi apparatus"],
                1,
                "easy",
                "remembering",
            ),
            (
                "Which process produces genetically identical cells?",
                &["Meiosis", "Mitosis", "Fertilization", "Crossing over"],
                1,
                "medium",
                "understanding",
            ),
        ],
        &[
            (
                "What is the basic unit of heredity called?",
                "Gene",
                "easy",
                "remembering",
            ),
            (
                "What is the shape of the DNA molecule?",
                "Double helix",
                "easy",
                "remembering",
            ),
            (
                "What are the four nitrogenous bases in DNA?",
                "Adenine, thymine, guanine, cytosine",
                "easy",
                "remembering",
            ),
            (
                "What is the site of DNA replication in the cell?",
                "Nucleus",
                "easy",
                "remembering",
            ),
            (
                "What do you call a segment of DNA that codes for a specific protein?",
                "Gene",
                "easy",
                "remembering",
            ),
        ],
        &[],
        comps,
    );

    let quiz2_qs = build_questions("t2_quiz2",
        &[
            ("Who is known as the father of genetics?", &["Charles Darwin", "Gregor Mendel", "Louis Pasteur", "James Watson"], 1, "easy", "remembering"),
            ("What is the term for different forms of a gene?", &["Alleles", "Chromosomes", "Traits", "Phenotypes"], 0, "easy", "remembering"),
            ("If both parents are heterozygous (Aa), what is the probability their child is homozygous recessive (aa)?", &["0%", "25%", "50%", "75%"], 1, "medium", "applying"),
            ("What process increases genetic variation during meiosis?", &["Mitosis", "Crossing over", "Replication", "Translation"], 1, "medium", "understanding"),
            ("Which mechanism of evolution results from chance events changing allele frequencies?", &["Natural selection", "Genetic drift", "Gene flow", "Mutation"], 1, "difficult", "understanding"),
        ],
        &[
            ("What is the physical expression of a gene called?", "Phenotype", "easy", "remembering"),
            ("What is the genetic makeup of an organism called?", "Genotype", "easy", "remembering"),
            ("What term describes having two identical alleles for a trait?", "Homozygous", "easy", "remembering"),
            ("What term describes having two different alleles for a trait?", "Heterozygous", "easy", "remembering"),
            ("What process produces gametes with half the number of chromosomes?", "Meiosis", "easy", "remembering"),
        ],
        &[],
        comps,
    );

    let exam_qs = build_questions("t2_exam",
        &[
            ("Which base is found in RNA but NOT in DNA?", &["Adenine", "Thymine", "Uracil", "Guanine"], 2, "easy", "remembering"),
            ("What is the role of tRNA during translation?", &["Copy DNA", "Carry amino acids to ribosomes", "Break down proteins", "Replicate chromosomes"], 1, "medium", "understanding"),
            ("In a Punnett square, what do the boxes represent?", &["Genes", "Possible offspring genotypes", "Chromosomes", "Alleles only"], 1, "medium", "applying"),
            ("What did Mendel observe in the F2 generation of his pea plant experiments?", &["All plants were tall", "All plants were short", "A 3:1 ratio of traits", "No variation"], 2, "medium", "understanding"),
            ("Which of the following is an example of a dominant trait in humans?", &["Attached earlobes", "Free earlobes", "Blue eyes", "Straight hairline"], 1, "medium", "remembering"),
            ("What is the result of nondisjunction during meiosis?", &["Normal gametes", "Gametes with extra or missing chromosomes", "No gametes produced", "Identical gametes"], 1, "difficult", "analyzing"),
            ("Which evolutionary mechanism favors traits that improve survival and reproduction?", &["Genetic drift", "Natural selection", "Gene flow", "Bottleneck effect"], 1, "easy", "understanding"),
            ("What evidence supports the theory of evolution?", &["Fossil records", "Homologous structures", "DNA similarities", "All of the above"], 3, "medium", "understanding"),
            ("What is a mutation?", &["A change in DNA sequence", "A type of cell division", "A form of genetic drift", "A method of reproduction"], 0, "easy", "remembering"),
            ("Which structure is analogous to a bird's wing?", &["Human arm", "Whale flipper", "Bat wing", "Insect wing"], 3, "difficult", "analyzing"),
        ],
        &[
            ("What molecule carries genetic instructions from the nucleus to the ribosome?", "Messenger RNA", "easy", "remembering"),
            ("What term describes an allele that masks the expression of another allele?", "Dominant", "easy", "remembering"),
            ("What is the name of Mendel's law stating that alleles separate during gamete formation?", "Law of Segregation", "easy", "remembering"),
            ("What process introduces new genetic variations into a population?", "Mutation", "easy", "remembering"),
            ("What is the term for the preserved remains or traces of ancient organisms?", "Fossil", "easy", "remembering"),
        ],
        &[
            ("Explain the roles of DNA, mRNA, and tRNA in protein synthesis. Describe how genetic information flows from the nucleus to the ribosome and how errors in this process can affect an organism.", 5, "difficult", "evaluating"),
            ("Describe how natural selection leads to adaptation in a population. Provide a specific example from the Philippines, such as the development of antibiotic resistance in bacteria or the adaptation of native species to local conditions.", 5, "difficult", "evaluating"),
        ],
        comps,
    );

    vec![
        AssessmentSpec {
            id: aid("t2_quiz1"),
            class_id: cid("sci10"),
            title: "T2 Quiz 1: DNA, Genes, and Protein Synthesis".into(),
            description: Some("10-item quiz on DNA structure and protein synthesis.".into()),
            time_limit_minutes: 30,
            open_at: now - chrono::Duration::days(7),
            close_at: now - chrono::Duration::days(1),
            show_results_immediately: true,
            total_points: 10,
            component: "written_work".into(),
            tos_id: tid("sci10_tos_t2"),
            created_at: created,
            deleted_at: None,
            is_published: true,
            results_released: true,
            term_number: 2,
            questions: quiz1_qs,
        },
        AssessmentSpec {
            id: aid("t2_quiz2"),
            class_id: cid("sci10"),
            title: "T2 Quiz 2: Mendelian Genetics and Evolution".into(),
            description: Some("10-item quiz on inheritance patterns and evolution.".into()),
            time_limit_minutes: 30,
            open_at: now - chrono::Duration::days(5),
            close_at: now - chrono::Duration::days(1),
            show_results_immediately: true,
            total_points: 10,
            component: "written_work".into(),
            tos_id: tid("sci10_tos_t2"),
            created_at: created,
            deleted_at: None,
            is_published: true,
            results_released: true,
            term_number: 2,
            questions: quiz2_qs,
        },
        AssessmentSpec {
            id: aid("t2_exam"),
            class_id: cid("sci10"),
            title: "T2 Term Exam: Genetics and Heredity".into(),
            description: Some("25-item term assessment on DNA, genetics, and evolution.".into()),
            time_limit_minutes: 60,
            open_at: now - chrono::Duration::days(10),
            close_at: now - chrono::Duration::days(2),
            show_results_immediately: true,
            total_points: 25,
            component: "term_assessment".into(),
            tos_id: tid("sci10_tos_t2"),
            created_at: created,
            deleted_at: None,
            is_published: true,
            results_released: true,
            term_number: 2,
            questions: exam_qs,
        },
    ]
}
