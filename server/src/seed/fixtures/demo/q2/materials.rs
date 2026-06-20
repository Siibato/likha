//! Q2 learning modules for demo seeding: Genetics & Heredity.

use crate::seed::specs::MaterialSpec;
use crate::seed::tools::SeedContext;
use super::super::{cid, mid};

pub fn demo_materials_q2(ctx: &SeedContext) -> Vec<MaterialSpec> {
    vec![
        MaterialSpec {
            id: mid("q2_mod1"), class_id: cid("sci10"),
            title: "Module 1: DNA and Genes".into(),
            description: Some("Covers DNA structure, replication, genes, chromosomes, and the central dogma of molecular biology.".into()),
            content_text: Some(
                "Deoxyribonucleic acid (DNA) is the molecule that carries genetic instructions for the development, functioning, growth, and reproduction of all known organisms. DNA is a long polymer made from repeating units called nucleotides. Each nucleotide consists of a sugar, a phosphate group, and a nitrogenous base. The four bases are adenine (A), thymine (T), guanine (G), and cytosine (C). The structure of DNA is a double helix, discovered by Watson and Crick in 1953, with two strands connected by hydrogen bonds between complementary base pairs: A pairs with T, and G pairs with C. A gene is a segment of DNA that codes for a specific protein. Humans have approximately 20,000 to 25,000 genes. The process of protein synthesis involves transcription, where DNA is copied into mRNA, and translation, where ribosomes use mRNA to assemble amino acids into proteins."
                    .into(),
            ),
            order_index: 0, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("q2_mod2"), class_id: cid("sci10"),
            title: "Module 2: Mendelian Genetics and Evolution".into(),
            description: Some("Covers Mendel's laws, inheritance patterns, natural selection, and evidence for evolution.".into()),
            content_text: Some(
                "Gregor Mendel, an Austrian monk, is considered the father of modern genetics. Through experiments with pea plants in the mid-1800s, Mendel discovered two fundamental laws: the Law of Segregation, which states that each organism carries two alleles for each trait but passes only one to each offspring, and the Law of Independent Assortment, which states that alleles for different traits are passed independently of one another. Mendel's work was largely ignored during his lifetime but became foundational after its rediscovery in 1900. Evolution is the process by which populations of organisms change over generations. Charles Darwin proposed natural selection as the mechanism driving evolution: individuals with traits better suited to their environment are more likely to survive and reproduce, passing those advantageous traits to offspring. Evidence for evolution includes the fossil record, homologous structures, vestigial organs, DNA sequence similarities among species, and observed instances of adaptation in modern populations."
                    .into(),
            ),
            order_index: 1, created_at: ctx.now(),
        },
    ]
}
