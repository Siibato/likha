//! T2 learning modules for demo-2: 2 subjects × 2 modules each (4 total).

use super::super::{cid, mid};
use crate::seed::specs::MaterialSpec;
use crate::seed::tools::SeedContext;

pub fn demo2_materials_t2(ctx: &SeedContext) -> Vec<MaterialSpec> {
    let mut materials = Vec::with_capacity(4);

    // Science 10: Genetics & Heredity
    materials.push(MaterialSpec {
        id: mid("sci_t2_mod1"),
        class_id: cid("sci10"),
        title: "Module 1: DNA Structure and Function".into(),
        description: Some("Covers DNA structure, nucleotides, base pairing, double helix, and chromosome organization.".into()),
        content_text: Some(
            "DNA (deoxyribonucleic acid) is the molecule that carries genetic information for all living organisms. \
            DNA is composed of nucleotides, each containing a sugar (deoxyribose), a phosphate group, and a nitrogenous base. \
            The four bases are adenine (A), thymine (T), guanine (G), and cytosine (C). Adenine always pairs with thymine, and guanine always pairs with cytosine. \
            DNA has a double helix structure, like a twisted ladder, with the sugar-phosphate backbone forming the sides and the base pairs forming the rungs. \
            DNA is organized into structures called chromosomes, which are found in the nucleus of eukaryotic cells. \
            Humans have 23 pairs of chromosomes, for a total of 46. Each chromosome contains many genes, which are segments of DNA that code for specific proteins."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("sci_t2_mod2"),
        class_id: cid("sci10"),
        title: "Module 2: Protein Synthesis and Inheritance".into(),
        description: Some("Covers transcription, translation, Mendel's laws, and patterns of inheritance.".into()),
        content_text: Some(
            "Protein synthesis is the process by which cells make proteins based on the instructions in DNA. \
            It occurs in two main stages: transcription and translation. In transcription, DNA is copied into mRNA (messenger RNA) in the nucleus. \
            The mRNA then travels to the ribosome, where translation occurs. During translation, the ribosome reads the mRNA code in groups of three bases called codons. \
            Each codon specifies a particular amino acid. tRNA (transfer RNA) molecules bring the appropriate amino acids to the ribosome, which links them together to form a protein. \
            Gregor Mendel, through his experiments with pea plants, discovered the fundamental laws of inheritance. His first law, the Law of Segregation, states that organisms have two alleles for each trait, which separate during gamete formation. \
            His second law, the Law of Independent Assortment, states that alleles for different traits are inherited independently. These laws form the foundation of modern genetics."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // English 10: World Literature (disconnected from seed)
    // materials.push(MaterialSpec {
    //     id: mid("eng_t2_mod1"),
    //     class_id: cid("eng10"),
    //     title: "Module 1: 21st Century Literary Genres".into(),
    //     description: Some("Covers contemporary genres like flash fiction, speculative fiction, chick lit, graphic literature, and hyperpoetry.".into()),
    //     content_text: Some(
    //         "21st century literature has embraced diverse forms and formats beyond traditional novels and poetry. \
    //         Flash fiction tells complete stories in very few words, often under 1,000 words, challenging writers to convey meaning concisely. \
    //         Speculative fiction encompasses science fiction, fantasy, and horror, exploring imagined worlds and possibilities. \
    //         Chick lit focuses on contemporary women's issues and relationships, often with humor and wit. \
    //         Graphic literature combines visual art with narrative, including graphic novels and comics that tackle serious themes. \
    //         Hyperpoetry is digital poetry that uses technology to create interactive, multimedia literary experiences. \
    //         These new forms reflect the changing ways people consume and create stories in the digital age."
    //             .into(),
    //     ),
    //     order_index: 0,
    //     created_at: ctx.now(),
    // });
    // materials.push(MaterialSpec {
    //     id: mid("eng_t2_mod2"),
    //     class_id: cid("eng10"),
    //     title: "Module 2: Text and Context in Literature".into(),
    //     description: Some("Covers the relationship between literary texts and their cultural, historical, and social contexts.".into()),
    //     content_text: Some(
    //         "Understanding literature requires considering both the text itself and its context. The text includes the words, structure, and literary devices used by the author. \
    //         Context includes the historical period, cultural background, social conditions, and author's personal experiences that influenced the work. \
    //         Intertextuality refers to the relationship between texts—how one text references, responds to, or transforms another text. \
    //         Reader-response criticism emphasizes that meaning is created through the interaction between reader and text, not inherent in the text alone. \
    //         Cultural context shapes how readers interpret themes and symbols. For example, understanding Philippine colonial history is essential for fully appreciating novels like Noli Me Tangere. \
    //         By studying both text and context, readers gain deeper insight into literature's meaning and significance across different times and cultures."
    //             .into(),
    //     ),
    //     order_index: 1,
    //     created_at: ctx.now(),
    // });

    // Math 10: Quadratic Functions
    materials.push(MaterialSpec {
        id: mid("math_t2_mod1"),
        class_id: cid("math10"),
        title: "Module 1: Quadratic Functions and Their Graphs".into(),
        description: Some("Covers standard form, vertex form, graphing parabolas, and identifying key features.".into()),
        content_text: Some(
            "A quadratic function is a function of the form f(x) = ax² + bx + c, where a ≠ 0. The graph of a quadratic function is a parabola. \
            If a > 0, the parabola opens upward and has a minimum point. If a < 0, it opens downward and has a maximum point. \
            The vertex is the highest or lowest point of the parabola. In standard form, the x-coordinate of the vertex is -b/2a. \
            Vertex form, f(x) = a(x-h)² + k, makes the vertex (h, k) immediately visible. The value of a determines the width and direction of the parabola. \
            The axis of symmetry is the vertical line x = h that passes through the vertex, dividing the parabola into two mirror images. \
            The x-intercepts (roots) can be found by factoring, using the quadratic formula, or completing the square. The y-intercept is found by evaluating f(0) = c."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("math_t2_mod2"),
        class_id: cid("math10"),
        title: "Module 2: Solving Quadratic Equations".into(),
        description: Some("Covers factoring, quadratic formula, completing the square, and applications.".into()),
        content_text: Some(
            "Quadratic equations can be solved using several methods. Factoring works when the equation can be written as (x-p)(x-q) = 0, giving solutions x = p and x = q. \
            The quadratic formula, x = (-b ± √(b²-4ac)) / 2a, works for all quadratic equations. The expression under the square root, b²-4ac, is called the discriminant. \
            If the discriminant is positive, there are two real solutions. If it is zero, there is one real solution (a repeated root). If it is negative, there are no real solutions. \
            Completing the square transforms the equation into vertex form, which is useful for graphing and finding the vertex. \
            Quadratic equations model many real-world situations, including projectile motion, area problems, and optimization. \
            Choosing the best method depends on the specific equation: factoring for simple equations, the quadratic formula for general cases, and completing the square when the vertex is needed."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // AP 10: Revolution & American Period (disconnected from seed)
    // materials.push(MaterialSpec {
    //     id: mid("ap_t2_mod1"),
    //     class_id: cid("ap10"),
    //     title: "Module 1: The Philippine Revolution".into(),
    //     description: Some("Covers causes, key events, figures, and outcomes of the 1896 Philippine Revolution.".into()),
    //     content_text: Some(
    //         "The Philippine Revolution (1896-1898) was a struggle for independence from Spanish colonial rule. It was fueled by centuries of Spanish oppression, abuses, and the desire for self-determination. \
    //         The Propaganda Movement, led by Jose Rizal, Marcelo del Pilar, and Graciano Lopez Jaena, advocated for peaceful reforms through writing and education. \
    //         When peaceful efforts failed, Andres Bonifacio founded the Katipunan, a secret revolutionary society that aimed for armed independence. \
    //         The Cry of Pugad Lawin (or Balintawak) in August 1896 marked the official start of the revolution. The Katipunan waged guerrilla warfare against Spanish forces. \
    //         Internal conflicts arose, particularly between Bonifacio and Emilio Aguinaldo over leadership. The Tejeros Convention led to Aguinaldo's assumption of leadership and Bonifacio's eventual execution. \
    //         The revolution continued until the Pact of Biak-na-Bato in 1897, which established a temporary truce and led to Aguinaldo's exile in Hong Kong."
    //             .into(),
    //     ),
    //     order_index: 0,
    //     created_at: ctx.now(),
    // });
    // materials.push(MaterialSpec {
    //     id: mid("ap_t2_mod2"),
    //     class_id: cid("ap10"),
    //     title: "Module 2: The American Colonial Period".into(),
    //     description: Some("Covers the Spanish-American War, American occupation, education reforms, and path to independence.".into()),
    //     content_text: Some(
    //         "The Spanish-American War in 1898 brought the United States into the Philippines. The Treaty of Paris transferred the Philippines from Spain to the United States for $20 million. \
    //         Filipinos, who had been fighting for independence, resisted American rule, leading to the Philippine-American War (1899-1902). \
    //         American colonial policy emphasized 'benevolent assimilation' through education and public health. The Thomasites were American teachers who established the public school system, introducing English as the medium of instruction. \
    //         The policy of attraction aimed to win Filipino loyalty through reforms and development. The Jones Law (1916) promised eventual independence and established a Philippine legislature. \
    //         The Commonwealth period (1935-1946) was a ten-year transition to independence, with Manuel Quezon as the first president. The Tydings-McDuffie Act (1934) set the date for independence. \
    //         American rule modernized Philippine infrastructure, education, and government, but also maintained economic and political control, shaping Philippine society in lasting ways."
    //             .into(),
    //     ),
    //     order_index: 1,
    //     created_at: ctx.now(),
    // });

    // Filipino 10: Tula at Dula (disconnected from seed)
    // materials.push(MaterialSpec {
    //     id: mid("fil_t2_mod1"),
    //     class_id: cid("fil10"),
    //     title: "Module 1: Mga Anyo ng Tula".into(),
    //     description: Some("Tinatalakay ang mga anyo ng tula tulad ng tanaga, soneto, haiku, at diona.".into()),
    //     content_text: Some(
    //         "Ang tula ay isang anyo ng panitikang nagpapahayag ng damdamin at ideya sa pamamagitan ng rhythm at imagery. \
    //         Ang tanaga ay isang maikling tula na may 7 pantig bawat taludtod at may sukat na AAAA. Ito ay nagmula sa tradisyong Pilipino. \
    //         Ang soneto ay isang tula na may 14 na linya na may isang partikular na rhyme scheme at meter. Ito ay nagmula sa Italya ngunit ginamit din sa Pilipinas. \
    //         Ang haiku ay isang Hapones na tula na may 5-7-5 pantig. Ito ay simple ngunit malalim ang kahulugan. \
    //         Ang diona ay isang tradisyonal na tula na may tatlong taludtod bawat stanza. \
    //         Ang mga anyong ito ng tula ay nagpapakita ng iba't ibang paraan ng pagpapahayag at nagpapanatili ng kultura at tradisyon."
    //             .into(),
    //     ),
    //     order_index: 0,
    //     created_at: ctx.now(),
    // });
    // materials.push(MaterialSpec {
    //     id: mid("fil_t2_mod2"),
    //     class_id: cid("fil10"),
    //     title: "Module 2: Mga Elemento ng Dula".into(),
    //     description: Some("Tinatalakay ang mga elemento ng dula: tauhan, dialogo, aksyon, at stage direction.".into()),
    //     content_text: Some(
    //         "Ang dula ay isang anyo ng panitikang isinasayaw o ginagampan sa entablado. Ito ay nagkakaroon ng tauhan, dialogo, at aksyon. \
    //         Ang tauhan sa dula ay ang mga karakter na ginagampan ng mga aktor. Bawat tauhan ay may sariling personalidad at motibasyon. \
    //         Ang dialogo ang usapan sa pagitan ng mga tauhan. Ito ang nagpapakita ng relasyon at conflict sa pagitan ng mga karakter. \
    //         Ang aksyon ang mga pangyayari at kilos sa dula. Ito ang nagdudulot sa pag-unlad ng plot. \
    //         Ang stage direction o tagubilin sa pag-arte ay mga tala na nagtuturo sa mga aktor kung paano kilosin ang kanilang mga parte. \
    //         Ang mga uri ng dula ay kasama ang tragedya (tragedy), komedya (comedy), melodrama, at farce. Ang bawat uri ay may iba't ibang tono at layunin."
    //             .into(),
    //     ),
    //     order_index: 1,
    //     created_at: ctx.now(),
    // });

    // TLE 10: Cookery (disconnected from seed)
    // materials.push(MaterialSpec {
    //     id: mid("tle_t2_mod1"),
    //     class_id: cid("tle10"),
    //     title: "Module 1: Kitchen Tools and Equipment".into(),
    //     description: Some("Covers kitchen tools, equipment, knife skills, and Mise en place.".into()),
    //     content_text: Some(
    //         "Proper kitchen tools and equipment are essential for efficient and safe food preparation. Basic tools include chef's knife, paring knife, cutting boards, measuring cups, mixing bowls, and various utensils. \
    //         Knife skills are fundamental for any cook. The proper grip involves holding the knife handle firmly with the index finger guiding the blade. The claw grip protects fingers while cutting. \
    //         Basic knife cuts include julienne (thin strips), dice (cubes), chop (irregular pieces), and mince (very small pieces). Consistent cutting ensures even cooking. \
    //         Mise en place (French for 'putting in place') is the practice of organizing and arranging ingredients before cooking. This includes measuring, chopping, and placing ingredients in small bowls or containers. \
    //         Proper knife maintenance includes regular sharpening and honing, storing knives safely, and using the right knife for each task. \
    //         Kitchen safety includes keeping work areas clean, using cutting boards to prevent cross-contamination, and handling hot items with proper protection."
    //             .into(),
    //     ),
    //     order_index: 0,
    //     created_at: ctx.now(),
    // });
    // materials.push(MaterialSpec {
    //     id: mid("tle_t2_mod2"),
    //     class_id: cid("tle10"),
    //     title: "Module 2: Egg Cookery and Food Safety".into(),
    //     description: Some("Covers egg preparation methods, food safety principles, and sanitation.".into()),
    //     content_text: Some(
    //         "Eggs are versatile ingredients used in many dishes. Egg cookery includes various preparation methods: hard-boiled (cooked in shell), soft-boiled, poached (cooked in water without shell), fried (sunny-side up or over-easy), scrambled (beaten and cooked), and made into omelets. \
    //         Each method requires different techniques and timing. For example, poaching requires gentle water at a simmer, while omelets need proper pan temperature and folding technique. \
    //         Food safety is critical in egg cookery. Eggs can carry Salmonella, so proper handling and cooking are essential. The danger zone (4°C to 60°C) is the temperature range where bacteria grow most rapidly. \
    //         Cross-contamination occurs when harmful bacteria transfer from one food to another, often through cutting boards, utensils, or hands. Use separate cutting boards for eggs and other foods. \
    //         Proper hand washing (20 seconds with soap) before and after handling food prevents the spread of bacteria. \
    //         Proper food storage includes refrigerating eggs promptly, using them before expiration dates, and storing cooked foods separately from raw foods."
    //             .into(),
    //     ),
    //     order_index: 1,
    //     created_at: ctx.now(),
    // });

    materials
}
