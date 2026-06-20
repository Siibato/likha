//! T2 pre-written tiered student answers for demo seeding.

use super::super::TermAnswers;

pub fn demo_answers_t2() -> TermAnswers {
    TermAnswers {
        exam_essay_1: [
            // Tier 0: Excellent
            "Protein synthesis is a fundamental biological process that involves three key molecules: DNA, mRNA, and tRNA. DNA stores the genetic blueprint in the nucleus. During transcription, an enzyme called RNA polymerase reads a gene on the DNA template and synthesizes a complementary strand of messenger RNA (mRNA). This mRNA then exits the nucleus and travels to a ribosome in the cytoplasm. At the ribosome, translation occurs: transfer RNA (tRNA) molecules, each carrying a specific amino acid, recognize codons on the mRNA through their anticodons. The ribosome catalyzes peptide bond formation between adjacent amino acids, building a polypeptide chain that folds into a functional protein. Errors in this process, such as mutations in DNA or mistranslations, can produce nonfunctional proteins, leading to genetic disorders like sickle cell anemia or cystic fibrosis. This demonstrates the critical importance of accuracy in the flow of genetic information from DNA to protein.".into(),
            // Tier 1: Good
            "DNA stores genetic information in the nucleus. It is copied into mRNA during transcription. The mRNA goes to the ribosome where tRNA brings amino acids. These amino acids are joined to make proteins. If there is a mutation in the DNA, the protein might not work properly, causing diseases like sickle cell anemia. This shows why the process must be accurate.".into(),
            // Tier 2: Satisfactory
            "DNA makes mRNA, which goes to the ribosome. tRNA brings amino acids to make proteins. Errors can cause problems like sickle cell disease.".into(),
            // Tier 3: Developing
            "DNA makes protein. mRNA copies DNA. tRNA helps build protein. Errors cause sickness.".into(),
        ],
        exam_essay_2: [
            // Tier 0: Excellent
            "Natural selection is the process by which organisms with traits better suited to their environment tend to survive and reproduce more successfully than those without such traits. Over many generations, this leads to adaptation, where a population becomes increasingly well-suited to its environment. A specific example from the Philippines is the development of antibiotic resistance in bacteria. When antibiotics are widely used, susceptible bacteria are killed, but rare resistant variants survive and multiply. Over time, the resistant population dominates, making the antibiotic less effective. Another example is the adaptation of Philippine eagle populations to forest habitats, where traits like large wings for maneuvering through dense canopy and strong talons for catching prey have been favored. These examples illustrate how environmental pressures drive evolutionary change and demonstrate the practical importance of understanding natural selection in medicine and conservation.".into(),
            // Tier 1: Good
            "Natural selection means organisms with helpful traits survive and reproduce more. In the Philippines, antibiotic resistance in bacteria is an example. When people use antibiotics, some bacteria survive because they are resistant. These bacteria multiply and spread. Another example is the Philippine eagle, which has adapted to live in forests. Understanding natural selection helps in medicine and protecting animals.".into(),
            // Tier 2: Satisfactory
            "Natural selection is when animals with good traits survive better. In the Philippines, bacteria become resistant to antibiotics. The Philippine eagle also adapted to forests.".into(),
            // Tier 3: Developing
            "Natural selection helps animals survive. Bacteria in Philippines become strong against medicine. Eagles adapted to trees.".into(),
        ],
        assignment_1: [
            // Tier 0: Excellent
            "DNA, or deoxyribonucleic acid, is the molecule that stores all the genetic information needed for an organism to develop, survive, and reproduce. Its double-helix structure, composed of nucleotides with sugar-phosphate backbones and nitrogenous bases, allows it to replicate accurately before cell division. DNA carries hereditary information from parents to offspring through gametes during reproduction. For example, eye color in humans is determined by genes on chromosomes. A person with brown-eye alleles (dominant) and blue-eye alleles (recessive) will have brown eyes because the dominant allele masks the recessive one. This example shows how DNA sequences directly influence observable traits and how genetic information is transmitted across generations, forming the basis of heredity.".into(),
            // Tier 1: Good
            "DNA stores genetic information and has a double-helix shape. It passes traits from parents to children. For example, eye color is controlled by genes. Brown eyes are dominant over blue eyes. If someone has one brown and one blue allele, they will have brown eyes. This shows how DNA controls traits.".into(),
            // Tier 2: Satisfactory
            "DNA carries genetic information. It is shaped like a double helix. Eye color is an example of a DNA trait. Brown eyes are dominant. DNA passes traits to offspring.".into(),
            // Tier 3: Developing
            "DNA carries traits. It has a double helix. Eye color comes from DNA. Brown is stronger than blue.".into(),
        ],
        assignment_2: [
            // Tier 0: Excellent
            "(1) The Law of Segregation states that each organism has two alleles for each trait, but when gametes are formed, these alleles separate so that each gamete receives only one allele. (2) The Law of Independent Assortment states that alleles for different traits are inherited independently of one another during gamete formation, assuming the genes are on different chromosomes. (3) A real-life example of dominant and recessive inheritance in humans is earlobe attachment. Free earlobes (dominant) hang below the point of attachment to the head, while attached earlobes (recessive) connect directly to the head. If one parent is homozygous dominant (EE) and the other is homozygous recessive (ee), all children will be heterozygous (Ee) and have free earlobes. If both parents are heterozygous (Ee), there is a 25% chance of a child having attached earlobes.".into(),
            // Tier 1: Good
            "(1) The Law of Segregation says alleles separate during gamete formation. (2) The Law of Independent Assortment says different traits are inherited separately. (3) Earlobe attachment is an example: free earlobes are dominant and attached are recessive. If both parents are Ee, their child has a 25% chance of attached earlobes.".into(),
            // Tier 2: Satisfactory
            "(1) Segregation means alleles separate. (2) Independent assortment means traits are inherited separately. (3) Free earlobes are dominant, attached are recessive.".into(),
            // Tier 3: Developing
            "(1) Segregation separates alleles. (2) Independent assortment separates traits. (3) Free earlobes are stronger trait.".into(),
        ],
    }
}
