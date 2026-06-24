//! T2 pre-written tiered student answers for demo-2: 6 subjects.

use super::super::SubjectTermAnswers;

// ─── Science 10: Genetics & Heredity ─────────────────────────────────────────────

pub fn demo2_answers_sci_t2() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Mendel's laws and human inheritance
            [
                // Tier 0: Excellent
                "Mendel's laws apply to human inheritance in several observable traits. For example, eye color follows Mendelian patterns where brown eyes (dominant) typically override blue eyes (recessive). If both parents are heterozygous (Bb), there is a 25% chance their child will have blue eyes (bb). Another example is attached earlobes, where free earlobes are dominant over attached earlobes. The Law of Segregation explains that each parent contributes one allele for each trait, and these alleles separate during gamete formation. The Law of Independent Assortment states that different traits are inherited independently, though this has exceptions when genes are linked on the same chromosome. These fundamental principles help geneticists predict inheritance patterns and understand genetic disorders in humans.".into(),
                // Tier 1: Good
                "Mendel's laws apply to human traits like eye color and earlobe attachment. Brown eyes are dominant over blue eyes. If parents have Bb genotypes, there's a 25% chance of blue eyes. Free earlobes are dominant over attached. The Law of Segregation says alleles separate during gamete formation. The Law of Independent Assortment says traits are inherited independently. These laws help predict inheritance patterns.".into(),
                // Tier 2: Satisfactory
                "Mendel's laws apply to human traits. Eye color follows dominant-recessive patterns. Brown is dominant over blue. Earlobe attachment also follows Mendel's laws. The Law of Segregation explains allele separation. The Law of Independent Assortment explains independent inheritance. These help predict traits.".into(),
                // Tier 3: Developing
                "Mendel's laws work for humans. Eye color and earlobes follow patterns. Brown eyes are dominant. Alleles separate in gametes. Traits are inherited independently. This helps predict inheritance.".into(),
            ],
            // Essay 2: Protein synthesis
            [
                // Tier 0: Excellent
                "Protein synthesis begins with DNA in the nucleus. During transcription, the enzyme RNA polymerase unzips the DNA double helix and synthesizes a complementary mRNA strand using one DNA strand as a template. The mRNA then exits the nucleus and travels to a ribosome in the cytoplasm. During translation, the ribosome reads the mRNA in groups of three bases called codons. Each codon specifies a particular amino acid. tRNA molecules, each carrying a specific amino acid, bind to the codons through their anticodons. The ribosome links the amino acids together in the order specified by the mRNA, forming a polypeptide chain. This chain folds into a functional protein. The entire process is directed by the genetic code, which is nearly universal across all organisms, demonstrating the fundamental unity of life.".into(),
                // Tier 1: Good
                "Protein synthesis starts with DNA in the nucleus. Transcription makes mRNA from DNA using RNA polymerase. The mRNA goes to the ribosome. Translation happens at the ribosome, which reads mRNA codons. tRNA brings amino acids that match the codons. The ribosome links amino acids into a chain. This chain folds into a protein. The genetic code directs this process and is universal across organisms.".into(),
                // Tier 2: Satisfactory
                "Protein synthesis starts with DNA. Transcription makes mRNA. mRNA goes to ribosome. Translation reads mRNA codons. tRNA brings amino acids. Ribosome links amino acids into a protein chain. The genetic code directs the process. This shows unity of life.".into(),
                // Tier 3: Developing
                "DNA makes mRNA. mRNA goes to ribosome. Ribosome reads codons. tRNA brings amino acids. Amino acids form protein. Genetic code directs this. Shows life unity.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Mendel's laws
            [
                // Tier 0: Excellent
                "Mendel's laws apply to human inheritance through various observable traits. One example is blood type, where alleles A and B are codominant while O is recessive. If parents have genotypes AO and BO, their children can have blood types A, B, AB, or O with equal probability. Another example is the ability to taste PTC (phenylthiocarbamide), where the tasting allele (T) is dominant over non-tasting (t). The Law of Segregation explains that each parent contributes one allele, and these alleles separate during meiosis. The Law of Independent Assortment states that different traits are inherited independently, though this has exceptions with linked genes. These principles help genetic counselors predict the likelihood of inherited conditions and understand family health history.".into(),
                // Tier 1: Good
                "Mendel's laws apply to human traits like blood type and PTC tasting. Blood type A and B are codominant, O is recessive. Parents with AO and BO can have children with A, B, AB, or O blood types. PTC tasting is dominant over non-tasting. The Law of Segregation says alleles separate during meiosis. The Law of Independent Assortment says traits are inherited independently. These help predict inherited conditions.".into(),
                // Tier 2: Satisfactory
                "Mendel's laws apply to human traits. Blood type follows patterns. A and B are codominant, O is recessive. PTC tasting is dominant. Law of Segregation explains allele separation. Law of Independent Assortment explains independent inheritance. Helps predict conditions.".into(),
                // Tier 3: Developing
                "Mendel's laws work for humans. Blood type follows patterns. PTC tasting is dominant. Alleles separate in meiosis. Traits are independent. Helps predict inheritance.".into(),
            ],
            // Assignment 2: DNA and protein synthesis
            [
                // Tier 0: Excellent
                "(1) DNA has a double helix structure composed of nucleotides. Each nucleotide contains a sugar (deoxyribose), a phosphate group, and a nitrogenous base (adenine, thymine, guanine, or cytosine). The bases pair specifically: A with T, and G with C, forming the 'rungs' of the helix. (2) During transcription, RNA polymerase unwinds the DNA and synthesizes a complementary mRNA strand using one DNA strand as a template. The mRNA carries the genetic code from the nucleus to the cytoplasm. (3) mRNA plays a crucial role in protein synthesis by carrying the genetic instructions from DNA to the ribosome. The ribosome reads the mRNA codons and directs the assembly of amino acids in the correct order to build a specific protein, effectively translating the genetic code into functional molecules.".into(),
                // Tier 1: Good
                "(1) DNA is a double helix made of nucleotides. Each nucleotide has a sugar, phosphate, and base. Bases pair A-T and G-C. (2) Transcription is when RNA polymerase makes mRNA from DNA. mRNA carries the code from nucleus to cytoplasm. (3) mRNA carries genetic instructions to the ribosome. The ribosome reads mRNA codons and assembles amino acids to make proteins, translating the code into molecules.".into(),
                // Tier 2: Satisfactory
                "(1) DNA is double helix with nucleotides. Has sugar, phosphate, bases. A pairs with T, G with C. (2) Transcription makes mRNA from DNA. mRNA carries code to cytoplasm. (3) mRNA carries instructions to ribosome. Ribosome reads codons, assembles amino acids into proteins. Translates code to molecules.".into(),
                // Tier 3: Developing
                "(1) DNA is double helix. Has nucleotides. Bases pair A-T, G-C. (2) Transcription makes mRNA. Carries code. (3) mRNA carries instructions to ribosome. Ribosome makes proteins. Translates code.".into(),
            ],
        ],
    }
}

// ─── English 10: World Literature ───────────────────────────────────────────────

pub fn demo2_answers_eng_t2() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Contemporary global issues
            [
                // Tier 0: Excellent
                "The 21st century literary work 'The Breadwinner' by Deborah Ellis reflects contemporary global issues of gender inequality, conflict, and displacement. Set in Taliban-controlled Afghanistan, the story follows a young girl who must disguise herself as a boy to support her family after her father is arrested. This work highlights the global issue of women's rights and education in conflict zones. It also addresses the refugee crisis and the struggle for survival in war-torn regions. The protagonist's journey mirrors the experiences of millions of displaced people worldwide. By focusing on a child's perspective, Ellis makes these complex global issues accessible and emotionally resonant. The work demonstrates how literature can serve as a powerful tool for raising awareness about human rights and social justice issues that transcend national boundaries.".into(),
                // Tier 1: Good
                "'The Breadwinner' reflects global issues like gender inequality and conflict. Set in Afghanistan under Taliban rule, a girl must dress as a boy to help her family. This shows women's rights issues in conflict zones. It also shows the refugee crisis and survival in war. The girl's story is like many displaced people's stories. Using a child's perspective makes these issues relatable. Literature raises awareness about human rights across the world.".into(),
                // Tier 2: Satisfactory
                "The work shows global issues like gender inequality and war. Set in Afghanistan, a girl dresses as a boy to survive. Shows women's rights issues. Shows refugee crisis. Like many displaced people. Child perspective makes it relatable. Literature raises awareness of human rights.".into(),
                // Tier 3: Developing
                "The story shows global issues. Gender inequality and war. Girl dresses as boy. Women's rights. Refugee crisis. Displaced people. Child perspective. Literature raises awareness.".into(),
            ],
            // Essay 2: Traditional vs 21st century comparison
            [
                // Tier 0: Excellent
                "Traditional literary works like Shakespeare's 'Romeo and Juliet' and 21st century works like 'The Hunger Games' both explore universal themes of love, conflict, and identity, but differ significantly in form and approach. Shakespeare uses iambic pentameter, elaborate metaphors, and a five-act structure, while Collins uses contemporary prose, first-person narration, and a trilogy format. Both works address social issues—Shakespeare examines family feuds and social class, while Collins critiques media culture and authoritarianism. However, 21st century literature often incorporates diverse perspectives, addresses contemporary issues like technology and globalization, and uses more experimental narrative structures. Traditional works tend to focus on universal human experiences through classical forms, while 21st century works often blend genres and challenge traditional narrative conventions to reflect a more complex, interconnected world.".into(),
                // Tier 1: Good
                "Shakespeare's 'Romeo and Juliet' and 'The Hunger Games' both explore love and conflict but differ in form. Shakespeare uses poetry and five acts, while Collins uses prose and first-person narration. Both address social issues—family feuds vs media culture. 21st century literature has diverse perspectives and contemporary issues like technology. Traditional works use classical forms for universal themes. 21st century works blend genres and challenge conventions to reflect a complex world.".into(),
                // Tier 2: Satisfactory
                "Romeo and Juliet and Hunger Games both explore love and conflict. Different forms: poetry vs prose, five acts vs trilogy. Both address social issues. 21st century has diverse perspectives and contemporary issues. Traditional uses classical forms. 21st century blends genres, challenges conventions. Reflects complex world.".into(),
                // Tier 3: Developing
                "Both explore love and conflict. Different forms: poetry vs prose. Social issues in both. 21st century has diverse perspectives. Traditional uses classical forms. 21st century blends genres. Reflects world complexity.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Literature as mirror of life
            [
                // Tier 0: Excellent
                "The 21st century literary work 'Americanah' by Chimamanda Ngozi Adichie reflects contemporary global issues of race, identity, and migration. The novel follows a Nigerian woman who moves to the United States and later returns to Nigeria, exploring themes of cultural assimilation, racial identity, and the immigrant experience. Adichie uses the protagonist's journey to examine how race operates differently in America, Britain, and Nigeria, highlighting the global nature of racial dynamics. The work also addresses issues of globalization, as characters navigate multiple cultures and the tension between maintaining their cultural identity and adapting to new environments. Through detailed observations and sharp social commentary, 'Americanah' serves as a mirror reflecting contemporary globalized society, showing how literature can illuminate complex social realities and foster cross-cultural understanding.".into(),
                // Tier 1: Good
                "'Americanah' reflects global issues of race, identity, and migration. A Nigerian woman moves to America and returns to Nigeria. Explores cultural assimilation, racial identity, and immigrant experience. Shows how race works differently in America, Britain, and Nigeria. Addresses globalization as characters navigate multiple cultures. Shows tension between identity and adaptation. Literature illuminates social realities and cross-cultural understanding.".into(),
                // Tier 2: Satisfactory
                "The work reflects race, identity, migration issues. Nigerian woman moves to America and back. Explores assimilation, racial identity, immigrant experience. Race works differently in different countries. Globalization shown through multiple cultures. Tension between identity and adaptation. Literature shows social realities.".into(),
                // Tier 3: Developing
                "Shows race, identity, migration. Nigerian woman moves countries. Assimilation and identity. Race differences. Globalization. Multiple cultures. Identity vs adaptation. Literature shows reality.".into(),
            ],
            // Assignment 2: Text and context
            [
                // Tier 0: Excellent
                "Understanding the cultural and historical context of a literary work enhances its meaning by revealing the author's intentions, the social influences on the text, and the deeper significance of certain themes and symbols. For example, in 'Things Fall Apart' by Chinua Achebe, understanding the context of British colonialism in Nigeria is essential to fully appreciate the novel's exploration of cultural conflict and the impact of European imperialism on Igbo society. Without this context, the reader might miss the novel's critique of colonial narratives and its defense of indigenous culture. The historical context explains why certain events occur and why characters make specific choices. Cultural context illuminates the significance of traditional practices and beliefs that might otherwise seem unfamiliar. By studying context, readers gain a more nuanced understanding of the work's themes and its relevance to broader historical and social discussions.".into(),
                // Tier 1: Good
                "Context enhances meaning by showing author's intentions and social influences. In 'Things Fall Apart,' understanding British colonialism in Nigeria is essential to appreciate the cultural conflict and impact of imperialism. Without context, readers might miss the critique of colonial narratives and defense of indigenous culture. Historical context explains events and character choices. Cultural context shows the significance of traditional practices. Context gives nuanced understanding of themes and relevance to historical discussions.".into(),
                // Tier 2: Satisfactory
                "Context enhances meaning. Shows author's intentions and influences. In Things Fall Apart, colonialism context is essential for cultural conflict themes. Without context, miss critique of colonialism. Historical context explains events. Cultural context shows traditional practices. Context gives better understanding of themes and relevance.".into(),
                // Tier 3: Developing
                "Context helps meaning. Shows intentions. Colonialism context important for Things Fall Apart. Without context, miss themes. Historical context explains events. Cultural context shows practices. Context improves understanding.".into(),
            ],
        ],
    }
}

// ─── Math 10: Quadratic Functions ────────────────────────────────────────────

pub fn demo2_answers_math_t2() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Solving quadratic by factoring
            [
                // Tier 0: Excellent
                "To solve x² - 5x + 6 = 0 by factoring, I need to find two numbers that multiply to 6 and add to -5. These numbers are -2 and -3. So I can factor as (x - 2)(x - 3) = 0. Setting each factor equal to zero gives x - 2 = 0 → x = 2, and x - 3 = 0 → x = 3. Therefore, the solutions are x = 2 and x = 3. Verification: For x = 2: 2² - 5(2) + 6 = 4 - 10 + 6 = 0 ✓. For x = 3: 3² - 5(3) + 6 = 9 - 15 + 6 = 0 ✓. Both solutions satisfy the original equation. Factoring is an efficient method when the quadratic can be easily factored, as in this case where the coefficients are integers and the factors are obvious.".into(),
                // Tier 1: Good
                "I solve x² - 5x + 6 = 0 by factoring. I need two numbers that multiply to 6 and add to -5. These are -2 and -3. So (x - 2)(x - 3) = 0. Setting each factor to zero: x - 2 = 0 gives x = 2, and x - 3 = 0 gives x = 3. Solutions are x = 2 and x = 3. Verification: 2² - 5(2) + 6 = 0, and 3² - 5(3) + 6 = 0. Both work. Factoring works well here because the equation factors easily with integers.".into(),
                // Tier 2: Satisfactory
                "Factor x² - 5x + 6 = 0. Numbers that multiply to 6 and add to -5 are -2 and -3. (x - 2)(x - 3) = 0. x = 2, x = 3. Check: 4 - 10 + 6 = 0, 9 - 15 + 6 = 0. Both correct. Factoring works here.".into(),
                // Tier 3: Developing
                "Factor the equation. Numbers are -2 and -3. (x - 2)(x - 3) = 0. x = 2, x = 3. Check works. Factoring method used.".into(),
            ],
            // Essay 2: Ball thrown upward
            [
                // Tier 0: Excellent
                "The height function is h(t) = -5t² + 20t + 5. This is a quadratic function in the form h(t) = at² + bt + c, where a = -5, b = 20, c = 5. Since a < 0, the parabola opens downward, meaning the vertex represents the maximum height. The time at maximum height is t = -b/(2a) = -20/(2 × -5) = -20/-10 = 2 seconds. To find the maximum height, substitute t = 2 into the function: h(2) = -5(2)² + 20(2) + 5 = -5(4) + 40 + 5 = -20 + 40 + 5 = 25 meters. Therefore, the ball reaches a maximum height of 25 meters at 2 seconds after being thrown. This method uses the vertex formula, which is efficient for finding maximum or minimum values of quadratic functions modeling real-world situations like projectile motion.".into(),
                // Tier 1: Good
                "The height function is h(t) = -5t² + 20t + 5. Since a = -5 < 0, the parabola opens down, so the vertex is the maximum. Time at max height is t = -b/(2a) = -20/(2 × -5) = 2 seconds. Maximum height is h(2) = -5(4) + 40 + 5 = 25 meters. The ball reaches 25 meters at 2 seconds. This uses the vertex formula to find maximum values in projectile motion problems.".into(),
                // Tier 2: Satisfactory
                "h(t) = -5t² + 20t + 5. a = -5, opens down. Vertex is max. t = -b/(2a) = -20/-10 = 2 seconds. h(2) = -20 + 40 + 5 = 25 meters. Max height 25m at 2 seconds. Vertex formula finds max values in projectile motion.".into(),
                // Tier 3: Developing
                "Function h(t) = -5t² + 20t + 5. Opens down. t = 2 seconds. h(2) = 25 meters. Max height 25m at 2s. Vertex formula used.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Quadratic functions
            [
                // Tier 0: Excellent
                "(1) For y = x² - 4x + 3, the vertex x-coordinate is -b/(2a) = -(-4)/(2 × 1) = 4/2 = 2. Substitute x = 2: y = 4 - 8 + 3 = -1. So the vertex is (2, -1). (2) To convert y = 2(x-1)² + 3 to standard form, expand: y = 2(x² - 2x + 1) + 3 = 2x² - 4x + 2 + 3 = 2x² - 4x + 5. (3) The parabola y = -x² + 2x + 1 opens downward because the coefficient of x² is -1, which is negative. A negative leading coefficient means the parabola opens downward, creating a maximum point at the vertex rather than a minimum.".into(),
                // Tier 1: Good
                "(1) Vertex of y = x² - 4x + 3: x = -b/(2a) = 4/2 = 2. y = 4 - 8 + 3 = -1. Vertex is (2, -1). (2) Convert y = 2(x-1)² + 3: expand to y = 2x² - 4x + 5. (3) y = -x² + 2x + 1 opens downward because the x² coefficient is -1, which is negative. Negative coefficient means downward opening with a maximum at the vertex.".into(),
                // Tier 2: Satisfactory
                "(1) Vertex: x = 2, y = -1. Vertex (2, -1). (2) Expand: y = 2x² - 4x + 5. (3) Opens downward because coefficient is -1 (negative). Negative means downward, has maximum at vertex.".into(),
                // Tier 3: Developing
                "(1) Vertex (2, -1). (2) y = 2x² - 4x + 5. (3) Opens downward, coefficient is -1. Negative means downward, maximum at vertex.".into(),
            ],
            // Assignment 2: Quadratic applications
            [
                // Tier 0: Excellent
                "(1) Let width = w, length = w + 4. Area = w(w + 4) = 48. So w² + 4w - 48 = 0. Factor: (w + 8)(w - 6) = 0. w = -8 (reject) or w = 6. So width = 6, length = 10. (2) For h(t) = -5t² + 20t, the vertex is at t = -b/(2a) = -20/(2 × -5) = 2 seconds. Maximum height is h(2) = -5(4) + 40 = 20 meters. The ball reaches maximum height of 20m at 2 seconds. These problems show how quadratic functions model real-world situations involving area and projectile motion.".into(),
                // Tier 1: Good
                "(1) Let width = w, length = w + 4. Area = w(w + 4) = 48. w² + 4w - 48 = 0. Factor: (w + 8)(w - 6) = 0. w = 6 (reject -8). Width = 6, length = 10. (2) h(t) = -5t² + 20t. Vertex at t = 2 seconds. Max height = h(2) = 20 meters. Quadratic functions model area and projectile motion problems.".into(),
                // Tier 2: Satisfactory
                "(1) width = w, length = w + 4. w² + 4w - 48 = 0. w = 6. Width 6, length 10. (2) Vertex at t = 2s. Max height = 20m. Quadratics model real-world problems like area and projectile motion.".into(),
                // Tier 3: Developing
                "(1) width = w, length = w + 4. w = 6. Width 6, length 10. (2) t = 2s, height = 20m. Quadratics model real problems.".into(),
            ],
        ],
    }
}

// ─── AP 10: Revolution & American Period ────────────────────────────────────

pub fn demo2_answers_ap_t2() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Causes and consequences of revolution
            [
                // Tier 0: Excellent
                "The Philippine Revolution was caused by centuries of Spanish colonial oppression, including abuses by friars, excessive taxation, forced labor (polo y servicio), and denial of basic rights. The execution of Rizal in 1896 further galvanized revolutionary sentiment. Key events include the founding of the Katipunan by Bonifacio in 1892, the Cry of Pugad Lawin marking the start of armed struggle, and the Tejeros Convention where Aguinaldo assumed leadership. The revolution led to the declaration of independence in 1898, though this was short-lived due to American intervention. Consequences included the establishment of a revolutionary government, the Malolos Congress, and the first Philippine constitution. Figures like Bonifacio, Aguinaldo, Mabini, and del Pilar played crucial roles. The revolution awakened Filipino nationalism and laid the groundwork for future independence movements, though it also revealed internal divisions that would affect Philippine politics for decades.".into(),
                // Tier 1: Good
                "The revolution was caused by Spanish oppression, friar abuses, taxation, and forced labor. Rizal's execution in 1896 angered Filipinos. Key events: Katipunan founded by Bonifacio in 1892, Cry of Pugad Lawin started the armed struggle, Tejeros Convention gave leadership to Aguinaldo. The revolution led to independence declaration in 1898, but America intervened. Consequences included revolutionary government, Malolos Congress, and first constitution. Figures: Bonifacio, Aguinaldo, Mabini, del Pilar. The revolution awakened nationalism but showed internal divisions.".into(),
                // Tier 2: Satisfactory
                "Causes: Spanish oppression, abuses, taxation, forced labor. Rizal execution. Events: Katipunan 1892, Cry of Pugad Lawin, Tejeros Convention. Result: independence 1898, American intervention. Consequences: revolutionary government, Malolos Congress, constitution. Figures: Bonifacio, Aguinaldo. Awakened nationalism, showed divisions.".into(),
                // Tier 3: Developing
                "Causes: oppression, abuses. Rizal execution. Events: Katipunan, Cry, Tejeros. Result: independence, American intervention. Consequences: government, congress. Figures: Bonifacio, Aguinaldo. Nationalism awakened, divisions shown.".into(),
            ],
            // Essay 2: American colonial impact
            [
                // Tier 0: Excellent
                "American colonial rule had mixed effects on Philippine society, education, and government. Positively, Americans established a public school system with English as the medium of instruction, which improved literacy and created a more educated populace. They also introduced democratic institutions, a judicial system, and infrastructure improvements. The Jones Law (1916) promised eventual independence, and the Commonwealth period (1935-1946) prepared the Philippines for self-rule. However, American rule also maintained economic control through trade policies that favored American interests. They suppressed independence movements and imposed their cultural values. The education system, while beneficial, also promoted Americanization and eroded Filipino cultural identity. The period saw the rise of a Filipino elite educated in American ways, creating social divisions. Overall, American rule modernized the Philippines but also perpetuated dependency and cultural imperialism.".into(),
                // Tier 1: Good
                "American rule had positive and negative effects. Positives: public school system with English improved literacy, democratic institutions, judicial system, infrastructure. Jones Law promised independence, Commonwealth prepared for self-rule. Negatives: economic control through trade policies favoring America, suppressed independence movements, imposed American culture. Education promoted Americanization and eroded Filipino identity. Created Filipino elite educated in American ways, causing social divisions. American rule modernized but perpetuated dependency and cultural imperialism.".into(),
                // Tier 2: Satisfactory
                "Positive: schools, English, literacy, democracy, infrastructure. Jones Law, Commonwealth. Negative: economic control, suppressed independence, American culture. Education caused Americanization, eroded identity. Created elite class. Modernized but caused dependency and cultural imperialism.".into(),
                // Tier 3: Developing
                "Positive: schools, English, democracy. Jones Law, Commonwealth. Negative: economic control, suppressed independence, American culture. Education Americanized. Created elite. Modernized but dependency.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Causes of revolution
            [
                // Tier 0: Excellent
                "The Philippine Revolution was caused by the cumulative effect of Spanish colonial abuses over three centuries. Primary causes included the abuses of friars who held both religious and political power, excessive taxation that burdened the poor, forced labor (polo y servicio) that took men away from their families, and the denial of basic rights to Filipinos. The execution of Jose Rizal in 1896 served as a catalyst that united Filipinos against Spanish rule. Key events include the founding of the Katipunan by Andres Bonifacio in 1892 as a secret revolutionary society, the Cry of Pugad Lawin in August 1896 marking the start of armed resistance, and the Tejeros Convention in 1897 where Emilio Aguinaldo assumed leadership. Figures like Bonifacio (the Father of the Revolution), Aguinaldo (first president), Mabini (the Brains of the Revolution), and del Pilar (propagandist) shaped the revolution. The revolution established Filipino nationalism and created the first Philippine republic, though internal divisions between Bonifacio and Aguinaldo weakened the movement.".into(),
                // Tier 1: Good
                "The revolution was caused by Spanish abuses: friar abuses, taxation, forced labor, denial of rights. Rizal's execution in 1896 united Filipinos. Key events: Katipunan founded by Bonifacio in 1892, Cry of Pugad Lawin 1896 started armed struggle, Tejeros Convention 1897 gave leadership to Aguinaldo. Figures: Bonifacio (Father of Revolution), Aguinaldo (first president), Mabini (Brains), del Pilar (propagandist). The revolution established nationalism and the first republic, but divisions between Bonifacio and Aguinaldo weakened it.".into(),
                // Tier 2: Satisfactory
                "Causes: Spanish abuses, friar power, taxation, forced labor. Rizal execution catalyst. Events: Katipunan 1892, Cry 1896, Tejeros 1897. Figures: Bonifacio, Aguinaldo, Mabini. Established nationalism, first republic. Divisions weakened movement.".into(),
                // Tier 3: Developing
                "Causes: abuses, taxation, forced labor. Rizal execution. Events: Katipunan, Cry, Tejeros. Figures: Bonifacio, Aguinaldo. Nationalism, republic. Divisions.".into(),
            ],
            // Assignment 2: American colonial impact
            [
                // Tier 0: Excellent
                "(1) American education had a profound impact on Philippine society by establishing a public school system that dramatically increased literacy rates. English became the medium of instruction, creating a generation of Filipinos fluent in English and exposed to American culture and values. This facilitated communication and integration into the global economy but also led to the erosion of Spanish and indigenous languages. The Thomasites, American teachers who arrived in 1901, were instrumental in this educational transformation. (2) The Jones Law of 1916 was significant because it was the first formal promise of Philippine independence by the United States. It established a Philippine legislature and granted Filipinos greater autonomy in domestic affairs, while reserving foreign affairs and defense to the U.S. This law marked a step toward self-governance and acknowledged Filipino aspirations for independence. (3) The Commonwealth period (1935-1946) prepared for independence by establishing a transitional government with Filipino leaders like Manuel Quezon as president. It allowed Filipinos to govern themselves under American supervision, gain administrative experience, and prepare for full independence scheduled for 1946. This period was crucial for developing the political institutions and administrative capacity needed for an independent nation.".into(),
                // Tier 1: Good
                "(1) American education increased literacy through public schools. English became the medium of instruction, exposing Filipinos to American culture. This helped global integration but eroded local languages. Thomasites were key teachers. (2) The Jones Law 1916 was significant as the first promise of independence by the U.S. It established a Philippine legislature and granted autonomy in domestic affairs while the U.S. kept foreign affairs and defense. This was a step toward self-governance. (3) The Commonwealth (1935-1946) prepared for independence with a transitional government led by Quezon. Filipinos governed under American supervision, gaining experience for full independence in 1946. This developed political institutions needed for independence.".into(),
                // Tier 2: Satisfactory
                "(1) Education increased literacy. English medium of instruction. American culture exposure. Helped global integration, eroded local languages. Thomasites important. (2) Jones Law 1916: first independence promise. Philippine legislature, domestic autonomy. U.S. kept foreign affairs. Step to self-governance. (3) Commonwealth 1935-1946: transitional government, Quezon president. Filipinos governed under supervision, gained experience. Developed institutions for independence.".into(),
                // Tier 3: Developing
                "(1) Education increased literacy. English instruction. American culture. Global integration, local language loss. (2) Jones Law: independence promise. Legislature, autonomy. U.S. foreign affairs. Self-governance step. (3) Commonwealth: transitional government, Quezon. Supervision, experience. Institutions for independence.".into(),
            ],
        ],
    }
}

// ─── Filipino 10: Tula at Dula ───────────────────────────────────────────────

pub fn demo2_answers_fil_t2() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Literary devices in poetry
            [
                // Tier 0: Excellent
                "Ang mga tayutay sa tula ay nagpapalakas sa pagpapahayag ng mensahe sa pamamagitan ng paglikha ng makabuluhang imahen at emosyon. Sa tula 'Sa Aking mga Kabata' ni Jose Rizal, ang metapora sa 'Ang hindi magmahal sa sariling wika' ay inihalintulad ang pagmamahal sa wika sa pagmamahal sa sarili, na nagpapakita na ang wika ay bahagi ng identidad. Ang personipikasyon sa 'mahigit kumulang pumuti't ang buhok' ay binigyan ng katangiang tao ang pagtanda upang sumimbolo sa pagdaan ng panahon at ang urgency ng pagpapanatili ng heritage. Ang parallelism sa istraktura ay lumilikha ng rhythmic emphasis na nagpapatibay sa mensahe. Ang mga tayutay na ito ay nagtutulungan upang lumikha ng persuasive argument tungkol sa national identity at cultural pride, na ginagawang mas memorable at impactful ang tula.".into(),
                // Tier 1: Good
                "Ang mga tayutay sa tula ay nagpapalakas ng mensahe sa pamamagitan ng imahen at emosyon. Sa tula ni Rizal, ang metapora ay inihalintulad ang wika sa sarili, na nagpapakita na wika ay parte ng identidad. Ang personipikasyon sa pagtanda ng buhok ay sumimbolo sa pagdaan ng panahon. Ang parallelism ay nagbibigay ng emphasis sa mensahe. Ang mga tayutay na ito ay nagtutulong sa paglikha ng argument tungkol sa national identity at cultural pride, na ginagawang memorable ang tula.".into(),
                // Tier 2: Satisfactory
                "Ang tayutay ay nagpapalakas ng mensahe sa pamamagitan ng imahen. Sa tula ni Rizal, metapora ay wika = sarili. Personipikasyon = pagtanda = panahon. Parallelism = emphasis. Tayutay ay tumutulong sa argument tungkol sa identity at pride. Ginagawang memorable ang tula.".into(),
                // Tier 3: Developing
                "Tayutay ay nagpapalakas ng mensahe. Metapora: wika = sarili. Personipikasyon: pagtanda. Parallelism: emphasis. Tumutulong sa identity argument. Memorable ang tula.".into(),
            ],
            // Essay 2: Poetry vs drama comparison
            [
                // Tier 0: Excellent
                "Ang tula at dula ay parehong anyo ng panitikan na nagpapahayag ng tema, ngunit magkaiba sa anyo at pamamaraan. Ang tula ay binabasa o sinasabi, gumagamit ng rhythm, rhyme, at condensed language upang magpahayag ng damdamin at ideya. Ang dula ay isinasayaw o ginagampan sa entablado, gumagamit ng dialogo, aksyon, at visual elements upang mabuhay ang kwento. Ang pagkakatulad ay pareho silang gumagamit ng mga elemento tulad ng tema, tauhan, at conflict. Ang pagkakaiba ay sa medium: tula ay text-based, dula ay performance-based. Sa pagpapahayag ng tema, ang tula ay nakatuon sa internal na damdamin at imagery, habang ang dula ay nakatuon sa external na aksyon at interaksiyon ng mga tauhan. Ang tula ay nagbibigay ng personal na reflection, habang ang dula ay nagbibigay ng collective na experience sa manonood.".into(),
                // Tier 1: Good
                "Ang tula at dula ay parehong nagpapahayag ng tema pero magkaiba sa anyo. Tula ay binabasa, gumagamit ng rhythm at rhyme para sa damdamin at ideya. Dula ay isinasayaw, gumagamit ng dialogo at aksyon para mabuhay ang kwento. Pareho silang gumagamit ng tema, tauhan, at conflict. Pagkakaiba: tula ay text-based, dula ay performance-based. Sa tema, tula ay internal na damdamin, dula ay external na aksyon. Tula ay personal reflection, dula ay collective experience sa manonood.".into(),
                // Tier 2: Satisfactory
                "Tula at dula pareho nagpapahayag ng tema. Magkaiba sa anyo. Tula: binabasa, rhythm, rhyme, damdamin. Dula: isinasayaw, dialogo, aksyon. Pareho: tema, tauhan, conflict. Pagkakaiba: text vs performance. Tula: internal damdamin. Dula: external aksyon. Tula: personal. Dula: collective experience.".into(),
                // Tier 3: Developing
                "Tula at dula pareho may tema. Magkaiba sa anyo. Tula: binabasa, rhythm. Dula: isinasayaw, dialogo. Pareho: tema, tauhan. Text vs performance. Tula: internal. Dula: external. Personal vs collective.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Literary devices in poetry
            [
                // Tier 0: Excellent
                "Sa tula 'Ang Guryon' ni Jose Corazon de Jesus, ang mga tayutay ay nagpapalakas ng mensahe tungkol sa pag-ibig. Ang simili sa 'parang guryon na nasa gitna ng bagyo' ay inihalintulad ang pag-ibig sa isang guryon na binabagyo ng hamon, na nagpapakita ng kahinaan at vulnerability. Ang metapora sa 'puso kong saksak ng lagrima' ay nagpapakita ng puso na puno ng sakit at lungkot. Ang personipikasyon sa 'ang hangin ay humahalik ng awit' ay binigyan ng buhay ang hangin upang sumimbolo sa kalikasan na sumasaksi sa pag-ibig. Ang hyperbole sa 'isang libong taon na hindi ako mawawala' ay nagpapalaki ang pag-ibig upang ipakita ang walang hanggan nito. Ang mga tayutay na ito ay nagtutulungan upang ipakita ang pag-ibig bilang isang bagay na maganda ngunit mahirap, na nagdudulot ng sakit at lungkot pero may pag-asa.".into(),
                // Tier 1: Good
                "Sa tula 'Ang Guryon,' ang mga tayutay ay nagpapalakas ng mensahe tungkol sa pag-ibig. Ang simili sa guryon sa gitna ng bagyo ay inihalintulad ang pag-ibig sa isang guryon na binabagyo, na nagpapakita ng kahinaan. Ang metapora sa puso saksak ng lagrima ay nagpapakita ng sakit. Ang personipikasyon sa hangin na humahalik ay sumimbolo sa kalikasan na sumasaksi. Ang hyperbole sa isang libong taon ay nagpapalaki ang pag-ibig. Ang mga tayutay ay nagpapakita na pag-ibig ay maganda ngunit mahirap, may sakit at lungkot pero may pag-asa.".into(),
                // Tier 2: Satisfactory
                "Sa tula, tayutay ay nagpapalakas ng mensahe tungkol sa pag-ibig. Simili: guryon = pag-ibig sa bagyo, kahinaan. Metapora: puno ng lagrima = sakit. Personipikasyon: hangin = kalikasan saksi. Hyperbole: libong taon = walang hanggan. Tayutay ay nagpapakita: pag-ibig maganda, mahirap, may sakit, may pag-asa.".into(),
                // Tier 3: Developing
                "Tayutay sa tula tungkol sa pag-ibig. Simili: guryon = pag-ibig. Metapora: lagrima = sakit. Personipikasyon: hangin = saksi. Hyperbole: libong taon. Pag-ibig: maganda, mahirap, may pag-asa.".into(),
            ],
            // Assignment 2: Poetry vs drama
            [
                // Tier 0: Excellent
                "Ang tula at dula ay magkakaiba sa pagpapahayag ng tema. Sa tula 'Sa Aking mga Kabata,' ang tema ng pagmamahal sa wika ay ipinapahayag sa pamamagitan ng condensed language, rhythm, at imagery. Ang mambabasa ay nag-iimagine at nakaranas ng emosyon sa pamamagitan ng mga salita. Sa dula naman tulad ng 'Kahapon, Ngayon, at Bukas,' ang tema ng pag-asa ay ipinapahayag sa pamamagitan ng dialogo, aksyon, at interaksiyon ng mga tauhan. Ang manonood ay nakakakita ng mga emosyon sa pamamagitan ng pag-arte at visual elements. Ang tula ay nakatuon sa internal na reflection at personal na karanasan, habang ang dula ay nakatuon sa external na pagpapakita at collective na karanasan ng manonood. Ang tula ay nagbibigay ng depth sa pamamagitan ng symbolism, habang ang dula ay nagbibigay ng breadth sa pamamagitan ng multiple perspectives at real-time na pag-unfold ng kwento.".into(),
                // Tier 1: Good
                "Ang tula at dula ay magkakaiba sa pagpapahayag ng tema. Sa tula 'Sa Aking mga Kabata,' ang tema ng pagmamahal sa wika ay ipinapahayag sa pamamagitan ng condensed language at imagery. Ang mambabasa ay nag-iimagine ng emosyon. Sa dula 'Kahapon, Ngayon, at Bukas,' ang tema ng pag-asa ay ipinapahayag sa pamamagitan ng dialogo at aksyon. Ang manonood ay nakakakita ng emosyon sa pag-arte. Tula ay internal reflection at personal. Dula ay external na pagpapakita at collective experience. Tula ay depth sa symbolism, dula ay breadth sa multiple perspectives.".into(),
                // Tier 2: Satisfactory
                "Tula at dula magkakaiba sa tema. Tula 'Sa Aking mga Kabata': pagmamahal sa wika sa pamamagitan ng language at imagery. Mambabasa nag-iimagine. Dula 'Kahapon, Ngayon, at Bukas': pag-asa sa dialogo at aksyon. Manonood nakakakita sa pag-arte. Tula: internal, personal. Dula: external, collective. Tula: depth symbolism. Dula: breadth perspectives.".into(),
                // Tier 3: Developing
                "Tula at dula magkakaiba. Tula: pagmamahal sa wika, language, imagery. Mambabasa imagine. Dula: pag-asa, dialogo, aksyon. Manonood nakakakita. Tula: internal, personal. Dula: external, collective. Tula: depth. Dula: breadth.".into(),
            ],
        ],
    }
}

// ─── TLE 10: Cookery ─────────────────────────────────────────────────────────

pub fn demo2_answers_tle_t2() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Vegetable omelet preparation
            [
                // Tier 0: Excellent
                "The step-by-step process of preparing a vegetable omelet begins with Mise en place: gathering ingredients (eggs, vegetables like bell peppers, onions, tomatoes, cheese, salt, pepper, oil) and tools (chef's knife, cutting board, mixing bowl, whisk, non-stick pan, spatula). First, wash and chop vegetables into small, even pieces. Heat oil in a non-stick pan over medium heat and sauté vegetables until tender, then set aside. Crack eggs into a bowl, add salt and pepper, and whisk until blended. Heat a small amount of oil in the pan over medium-low heat, pour in the eggs, and let them set slightly. Add sautéed vegetables and cheese to one half of the omelet. Using a spatula, carefully fold the other half over the filling. Cook until the eggs are set but still moist. Slide onto a plate. Safety precautions: use a sharp knife properly with claw grip, keep pan handles away from heat, avoid splattering hot oil, and wash hands before and after handling food. Challenges include achieving the right cooking temperature to avoid burning or undercooking, and folding the omelet without breaking it.".into(),
                // Tier 1: Good
                "To prepare a vegetable omelet: gather ingredients (eggs, vegetables, cheese, oil) and tools (knife, cutting board, bowl, whisk, pan, spatula). Wash and chop vegetables. Heat oil, sauté vegetables until tender, set aside. Whisk eggs with salt and pepper. Heat oil in pan, pour eggs, let set slightly. Add vegetables and cheese to one half. Fold the other half over with spatula. Cook until set. Safety: proper knife grip, watch pan handles, avoid hot oil splatter, wash hands. Challenges: right temperature to avoid burning, folding without breaking.".into(),
                // Tier 2: Satisfactory
                "Prepare vegetable omelet: gather ingredients and tools. Chop vegetables. Sauté vegetables, set aside. Whisk eggs. Heat pan, pour eggs, set. Add vegetables and cheese. Fold omelet. Cook until set. Safety: knife grip, pan handles, hot oil, hand washing. Challenges: temperature control, folding without breaking.".into(),
                // Tier 3: Developing
                "Make vegetable omelet: get ingredients, chop vegetables, cook vegetables, whisk eggs, cook eggs, add vegetables, fold, cook. Safety: knife, hot oil, wash hands. Challenges: temperature, folding.".into(),
            ],
            // Essay 2: Food safety in egg cookery
            [
                // Tier 0: Excellent
                "Food safety in egg cookery is critical because eggs can carry Salmonella bacteria, which can cause serious foodborne illness. Risks of improper handling include cross-contamination when raw eggs contact other foods or surfaces, undercooking which leaves bacteria alive, and leaving eggs at room temperature in the danger zone (4°C to 60°C) where bacteria multiply rapidly. Prevention methods include: always washing hands before and after handling eggs, using separate cutting boards and utensils for eggs, cooking eggs to proper temperature (yolks should be firm, whites opaque), refrigerating eggs promptly at or below 4°C, and consuming eggs within their expiration date. When cracking eggs, check for cracks or abnormalities in the shell. Never use raw eggs in dishes that won't be cooked. Proper food safety protects consumers from illness and ensures the quality and reputation of food service establishments.".into(),
                // Tier 1: Good
                "Food safety in egg cookery is important because eggs can carry Salmonella bacteria causing illness. Risks of improper handling: cross-contamination when raw eggs contact other foods, undercooking leaves bacteria alive, leaving eggs at room temperature in danger zone (4-60°C) where bacteria multiply. Prevention: wash hands before and after handling eggs, use separate cutting boards for eggs, cook eggs properly (firm yolks, opaque whites), refrigerate eggs promptly below 4°C, use eggs before expiration. Check for cracked shells. Never use raw eggs in uncooked dishes. Food safety protects consumers from illness and ensures food quality.".into(),
                // Tier 2: Satisfactory
                "Food safety important because eggs have Salmonella bacteria causing illness. Risks: cross-contamination, undercooking, room temperature danger zone (4-60°C). Prevention: wash hands, separate cutting boards, cook properly (firm yolks), refrigerate below 4°C, use before expiration. Check cracked shells. No raw eggs in uncooked dishes. Protects consumers and quality.".into(),
                // Tier 3: Developing
                "Food safety important: eggs have Salmonella. Risks: contamination, undercooking, danger zone. Prevention: wash hands, separate boards, cook well, refrigerate, check expiration. No raw eggs uncooked. Protects consumers.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Egg dish preparation
            [
                // Tier 0: Excellent
                "The vegetable omelet preparation began with Mise en place: organizing ingredients (3 eggs, bell pepper, onion, tomato, cheese, salt, pepper, oil) and tools (chef's knife, cutting board, mixing bowl, whisk, non-stick 8-inch pan, spatula). Safety precautions included washing hands, using proper knife grip (claw grip), and keeping the pan handle away from the heat source. First, I washed and chopped the vegetables into small, uniform pieces. I heated 1 tablespoon of oil in the pan over medium heat and sautéed the vegetables for 3-4 minutes until tender, then removed them. I cracked the eggs into a bowl, added salt and pepper, and whisked until blended. I heated 1 teaspoon of oil in the pan over medium-low heat, poured in the eggs, and let them cook for 1-2 minutes until slightly set. I added the vegetables and cheese to one half, then used the spatula to fold the other half over. I cooked for another 1-2 minutes until set but moist. The main challenge was controlling the heat to prevent burning while ensuring the eggs were fully cooked. The omelet turned out well with even cooking and good folding.".into(),
                // Tier 1: Good
                "I prepared a vegetable omelet with ingredients (eggs, vegetables, cheese, oil) and tools (knife, board, bowl, whisk, pan, spatula). Safety: washed hands, proper knife grip, pan handle away from heat. Steps: chopped vegetables, sautéed until tender, set aside. Whisked eggs with salt and pepper. Heated pan, poured eggs, let set. Added vegetables and cheese to one half, folded over with spatula. Cooked until set. Challenge: controlling heat to avoid burning while ensuring eggs were cooked. Result: good omelet with even cooking and proper folding.".into(),
                // Tier 2: Satisfactory
                "Prepared vegetable omelet. Ingredients: eggs, vegetables, cheese, oil. Tools: knife, board, bowl, whisk, pan, spatula. Safety: washed hands, knife grip, pan handle. Steps: chop vegetables, sauté, set aside. Whisk eggs. Cook eggs, set. Add vegetables and cheese, fold. Cook until set. Challenge: heat control. Result: good omelet, even cooking.".into(),
                // Tier 3: Developing
                "Made vegetable omelet. Ingredients: eggs, vegetables, cheese. Tools: knife, pan, spatula. Safety: wash hands, knife grip. Steps: chop, cook vegetables, whisk eggs, cook eggs, add vegetables, fold. Challenge: heat. Result: good omelet.".into(),
            ],
            // Assignment 2: Food safety
            [
                // Tier 0: Excellent
                "(1) The danger zone for food is the temperature range between 4°C and 60°C (40°F to 140°F). In this range, bacteria multiply most rapidly, doubling in number every 20 minutes. Food should not be kept in the danger zone for more than 2 hours to prevent bacterial growth to dangerous levels. (2) Cross-contamination occurs when harmful bacteria from one food item are transferred to another, typically through cutting boards, utensils, hands, or surfaces. For example, using the same cutting board for raw eggs and then for vegetables without washing can transfer Salmonella from the eggs to the vegetables. (3) Proper hand washing is critical in food preparation because hands are a primary vehicle for transferring pathogens. Washing hands with soap for at least 20 seconds removes dirt, bacteria, and viruses. This prevents contamination of food and protects both food handlers and consumers from foodborne illnesses. Hands should be washed before handling food, after handling raw foods, after using the restroom, and after touching face or hair.".into(),
                // Tier 1: Good
                "(1) The danger zone is 4°C to 60°C. Bacteria multiply rapidly in this range, doubling every 20 minutes. Food should not be in the danger zone for more than 2 hours to prevent dangerous bacterial growth. (2) Cross-contamination is when bacteria transfer from one food to another through cutting boards, utensils, hands, or surfaces. Example: using the same board for raw eggs and vegetables without washing transfers Salmonella. (3) Proper hand washing is critical because hands transfer pathogens. Washing with soap for 20 seconds removes bacteria and viruses. This prevents food contamination and protects handlers and consumers from illness. Wash before handling food, after raw foods, after restroom, after touching face or hair.".into(),
                // Tier 2: Satisfactory
                "(1) Danger zone: 4-60°C. Bacteria multiply rapidly, double every 20 minutes. Food not in zone more than 2 hours to prevent bacterial growth. (2) Cross-contamination: bacteria transfer between foods via boards, utensils, hands. Example: same board for eggs and vegetables transfers Salmonella. (3) Hand washing critical because hands transfer pathogens. Soap 20 seconds removes bacteria/viruses. Prevents contamination, protects from illness. Wash before food, after raw food, after restroom, after touching face.".into(),
                // Tier 3: Developing
                "(1) Danger zone: 4-60°C. Bacteria grow fast. Food not in zone >2 hours. (2) Cross-contamination: bacteria transfer via boards, hands. Example: eggs to vegetables. (3) Hand washing important: hands transfer pathogens. Soap 20 seconds removes bacteria. Prevents contamination, protects from illness. Wash before food, after raw food, after restroom.".into(),
            ],
        ],
    }
}
