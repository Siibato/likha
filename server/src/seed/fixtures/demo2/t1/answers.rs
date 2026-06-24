//! T1 pre-written tiered student answers for demo-2: 6 subjects.

use super::super::SubjectTermAnswers;

// ─── Science 10: Plate Tectonics ─────────────────────────────────────────────

pub fn demo2_answers_sci_t1() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Plate tectonics and Philippine earthquakes
            [
                // Tier 0: Excellent
                "The theory of plate tectonics fully accounts for the high frequency of earthquakes in the Philippines because the archipelago sits at the convergence of several major tectonic plates: the Philippine Sea Plate, the Eurasian Plate, the Indo-Australian Plate, and the Pacific Plate. Two specific locations that demonstrate this are the Manila Trench along western Luzon, where the Eurasian Plate is subducting beneath the Philippine Sea Plate, and the Philippine Fault Zone running through the eastern Philippines, a major left-lateral strike-slip fault system. The continuous interactions at these boundaries—subduction, collision, and lateral sliding—generate frequent seismic activity. Additionally, the Philippine Islands are part of the Pacific Ring of Fire, a region where about 90% of the world's earthquakes occur, further confirming the causal link between plate tectonics and seismic hazard in this region.".into(),
                // Tier 1: Good
                "Plate tectonics explains why the Philippines has many earthquakes because the country is located where several plates meet. The Manila Trench and the Philippine Fault are two examples of places where earthquakes happen. The Philippines is also on the Ring of Fire, which is known for earthquakes and volcanoes. When plates move against each other, energy is released as earthquakes, making the Philippines a high-risk area.".into(),
                // Tier 2: Satisfactory
                "The Philippines has many earthquakes because of plate tectonics. The plates move and cause earthquakes. Two places are the Manila Trench and the Philippine Fault. The Ring of Fire also affects the Philippines.".into(),
                // Tier 3: Developing
                "Earthquakes happen in the Philippines because the ground moves. There are some fault lines like Manila. The Ring of Fire is a place with many earthquakes.".into(),
            ],
            // Essay 2: Divergent vs convergent boundaries
            [
                // Tier 0: Excellent
                "Divergent and convergent plate boundaries are fundamentally different in their motion, geology, and effects. At divergent boundaries, tectonic plates move away from each other, allowing magma from the mantle to rise and fill the gap, creating new crust. This process produces landforms such as mid-ocean ridges—like the Mid-Atlantic Ridge—and rift valleys, such as the East African Rift Valley. In contrast, at convergent boundaries, plates collide. Depending on the types of plates involved, this can produce different landforms: oceanic-continental convergence creates volcanic mountain ranges like the Andes, while continental-continental convergence produces massive mountain ranges like the Himalayas. Oceanic-oceanic convergence forms volcanic island arcs such as Japan. The Philippines experiences more convergent activity because it lies at the boundary where the Philippine Sea Plate is subducting beneath the Eurasian Plate and where the Pacific Plate is pushing westward. This convergence causes the formation of deep trenches, volcanic arcs, and frequent earthquakes, which are characteristic features of the Philippine archipelago.".into(),
                // Tier 1: Good
                "Divergent boundaries are where plates move apart and create mid-ocean ridges and rift valleys. Convergent boundaries are where plates collide and create mountains and trenches. The Philippines has more convergent activity because several plates are pushing together around it, like the Philippine Sea Plate and the Eurasian Plate. This is why there are many volcanoes and mountains in the Philippines.".into(),
                // Tier 2: Satisfactory
                "Divergent boundaries make rift valleys when plates move apart. Convergent boundaries make mountains when plates collide. The Philippines has convergent boundaries because plates meet there. This causes earthquakes and volcanoes.".into(),
                // Tier 3: Developing
                "Divergent plates go away from each other. Convergent plates hit each other. The Philippines has convergent because plates meet. Mountains form there.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Plate tectonics and mountain formation
            [
                // Tier 0: Excellent
                "Plate tectonics theory explains mountain formation primarily through the process of convergence at plate boundaries. When two continental plates collide, neither is dense enough to subduct, so the crust crumples and thickens, pushing rock layers upward over millions of years to form massive mountain ranges. A real-world example is the Himalayan Mountains, which formed when the Indian Plate crashed into the Eurasian Plate. Even today, the Himalayas continue to rise as the plates push against each other. Another example is the formation of the Sierra Madre mountain ranges in the Philippines, which were shaped by the convergence of the Philippine Sea Plate and the Eurasian Plate. These processes demonstrate how the dynamic movement of Earth's crust creates the towering landforms we see today.".into(),
                // Tier 1: Good
                "Mountains form when plates collide because the crust gets pushed up. An example is the Himalayas, formed by India and Asia colliding. In the Philippines, the Sierra Madre was also formed by plate collision. This shows how plate tectonics creates mountains.".into(),
                // Tier 2: Satisfactory
                "When plates hit each other, mountains form. The Himalayas are an example. The Sierra Madre in the Philippines is another example. Plate tectonics causes this.".into(),
                // Tier 3: Developing
                "Mountains form when plates crash. Himalayas is an example. Sierra Madre too. Plate tectonics makes mountains.".into(),
            ],
            // Assignment 2: Earth's interior
            [
                // Tier 0: Excellent
                "(1) The Earth's crust is made of solid rock, primarily composed of oxygen, silicon, aluminum, iron, calcium, sodium, potassium, and magnesium. It includes both continental crust, which is thicker and less dense, and oceanic crust, which is thinner but denser because it contains more iron and magnesium. (2) The mantle is different from the core in composition and state. The mantle is made of silicate minerals that are hot enough to flow slowly in a plastic-like manner, whereas the core is made mainly of iron and nickel. The outer core is liquid, while the inner core is solid due to extreme pressure. (3) Scientists use seismic waves to study Earth's interior. By analyzing how these waves change speed and direction as they travel through different layers, scientists can map the internal structure of the planet. Other evidence includes volcanic rocks that sample mantle material, meteorites that suggest core composition, and laboratory experiments simulating deep-Earth conditions.".into(),
                // Tier 1: Good
                "(1) The Earth's crust is made of solid rock like granite and basalt. (2) The mantle is made of hot rock that can flow, while the core is made of iron and nickel. The outer core is liquid and the inner core is solid. (3) Scientists study Earth's interior using seismic waves from earthquakes. They also look at volcanic rocks and do experiments.".into(),
                // Tier 2: Satisfactory
                "(1) The crust is made of rock. (2) The mantle is hot rock, the core is metal. The outer core is liquid. (3) Scientists use seismic waves to study inside Earth.".into(),
                // Tier 3: Developing
                "(1) Crust is rock. (2) Mantle is hot, core is iron. Outer core is liquid. (3) Seismic waves help scientists study Earth.".into(),
            ],
        ],
    }
}

// ─── English 10: Philippine Literature ───────────────────────────────────────

pub fn demo2_answers_eng_t1() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Setting and theme
            [
                // Tier 0: Excellent
                "The setting in Philippine short stories plays a crucial role in shaping and reinforcing the theme. For example, in many stories about rural life, the setting of a provincial village emphasizes themes of tradition, community, and the struggle between old and new ways. The physical environment—whether it's a rice field, a barrio, or urban Manila—provides context that influences character decisions and conflicts. In 'How My Brother Leon Brought Home a Wife,' the rural setting of Nagrebcan highlights themes of acceptance and the contrast between urban and rural values. The journey through the countryside becomes a metaphor for the wife's integration into the family. Similarly, stories set during the Spanish colonial period use historical settings to explore themes of oppression, resistance, and national identity. The setting is not just a backdrop but an active element that shapes the narrative's meaning and emotional impact.".into(),
                // Tier 1: Good
                "The setting in Philippine short stories is important because it shows where the story happens and affects the characters. For example, rural settings often show traditional Filipino values. In stories about the Spanish period, the historical setting helps show themes of oppression and resistance. The setting helps readers understand the theme better by providing context for the characters' actions.".into(),
                // Tier 2: Satisfactory
                "The setting affects the theme in Philippine stories. Rural settings show tradition. Historical settings show oppression. The setting helps explain what the story is about.".into(),
                // Tier 3: Developing
                "Setting is where the story happens. It affects the theme. Rural places show old ways. Historical places show the past.".into(),
            ],
            // Essay 2: Literary devices comparison
            [
                // Tier 0: Excellent
                "Both Filipino and English poetry use literary devices to enhance meaning, but they often reflect different cultural contexts and linguistic traditions. Filipino poetry frequently employs indigenous metaphors drawn from nature, local customs, and everyday Filipino life. For example, the use of 'bahay kubo' as a symbol of simplicity and unity resonates deeply with Filipino cultural values. English poetry, when written by Filipinos, often incorporates code-switching and hybrid imagery that bridges Western and Filipino sensibilities. Similes and metaphors in Filipino poetry may use local flora and fauna (like sampaguita, narra, or maya) that carry specific cultural meanings. English poetry might use more universal imagery but can still express distinctly Filipino themes of identity, diaspora, and social justice. Both traditions use devices like personification, hyperbole, and alliteration to create rhythm and emotional impact, but the choice of imagery and reference points reflects the poet's cultural background and intended audience. The effectiveness of these devices depends on how well they connect with the reader's cultural and emotional experiences.".into(),
                // Tier 1: Good
                "Filipino and English poems both use literary devices like metaphors and similes, but they often use different images. Filipino poems use local things like flowers and plants that have meaning in Filipino culture. English poems might use more universal images. Both use these devices to make the poem more meaningful and emotional. The difference is in the cultural references they use.".into(),
                // Tier 2: Satisfactory
                "Both Filipino and English poems use literary devices. Filipino poems use local images. English poems use universal images. Both help make the poem better. The devices add meaning to the poems.".into(),
                // Tier 3: Developing
                "Filipino and English poems use devices like metaphors. They are similar but use different words. Both make poems meaningful. Devices help the poem express ideas.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Theme analysis
            [
                // Tier 0: Excellent
                "In the short story 'The Wedding Dance' by Amador Daguio, the central theme is the conflict between personal desire and cultural tradition. The author develops this theme through the characters of Awiyao and Lumnay, whose love is tested by the tribal custom that requires a man to have a child to continue his lineage. The setting of the village at night, with the distant sounds of the wedding dance, creates a mood of melancholy and inevitability. The plot unfolds through dialogue that reveals the characters' deep emotional struggle—Awiyao's duty to his tribe and Lumnay's pride and love. The bead necklace that Awiyao returns to Lumnay symbolizes their broken relationship and the permanence of their separation. Through these elements, Daguio explores how cultural traditions can both preserve community and cause individual suffering, raising questions about the balance between personal happiness and social obligation.".into(),
                // Tier 1: Good
                "In 'The Wedding Dance,' the theme is about love versus tradition. The author shows this through the characters Awiyao and Lumnay, who love each other but must separate because of tribal custom. The setting at night with the wedding dance sounds shows sadness. The plot uses dialogue to show their feelings. The bead necklace symbolizes their broken relationship. The story shows how traditions can hurt people even when they preserve the community.".into(),
                // Tier 2: Satisfactory
                "The theme of 'The Wedding Dance' is love and tradition. Awiyao and Lumnay love each other but must separate. The setting is sad at night. The dialogue shows their feelings. The necklace shows their separation. Traditions can cause pain.".into(),
                // Tier 3: Developing
                "The theme is love and tradition. Awiyao and Lumnay separate because of custom. The setting is night. They are sad. The necklace is important. Traditions are hard.".into(),
            ],
            // Assignment 2: Literary devices
            [
                // Tier 0: Excellent
                "In the poem 'Sa Aking mga Kabata' by Jose Rizal, three literary devices stand out. First, metaphor is used in 'Ang hindi magmahal sa sariling wika,' where love for language is compared to love for self, suggesting that language is integral to identity. Second, personification appears in 'mahigit kumulang pumuti't ang buhok,' where the hair turning white is given human-like aging to symbolize the passage of time and the urgency of preserving one's heritage. Third, parallelism is evident in the structure 'ang hindi magmahal sa sariling wika' repeated with variations, creating a rhythmic emphasis that reinforces the poem's message about the importance of loving one's language. These devices work together to create a persuasive argument about national identity and cultural pride, making the poem both emotionally resonant and intellectually compelling.".into(),
                // Tier 1: Good
                "In 'Sa Aking mga Kabata,' Rizal uses metaphor when he compares loving language to loving oneself. This shows that language is part of identity. He uses personification with the hair turning white to show time passing. Parallelism is used in the repeated structure to emphasize the message. These devices make the poem's message about loving our language stronger and more memorable.".into(),
                // Tier 2: Satisfactory
                "The poem uses metaphor comparing language to self. Personification shows aging hair. Parallelism repeats the structure. These devices emphasize the message about loving our language. They make the poem more effective.".into(),
                // Tier 3: Developing
                "Metaphor compares language to self. Personification shows hair aging. Parallelism repeats words. These devices help the message. The poem is about loving language.".into(),
            ],
        ],
    }
}

// ─── Math 10: Linear Equations & Inequalities ────────────────────────────────

pub fn demo2_answers_math_t1() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: System of equations
            [
                // Tier 0: Excellent
                "To solve the system 2x + 3y = 12 and x - y = 1, I will use the substitution method. From the second equation, I can express x in terms of y: x = y + 1. Substituting this into the first equation: 2(y + 1) + 3y = 12. This simplifies to 2y + 2 + 3y = 12, then 5y + 2 = 12, so 5y = 10, and y = 2. Substituting y = 2 back into x = y + 1 gives x = 3. Therefore, the solution is (3, 2). I chose substitution because the second equation had a coefficient of 1 for x, making it easy to isolate. Verification: 2(3) + 3(2) = 6 + 6 = 12 ✓, and 3 - 2 = 1 ✓. The substitution method is efficient when one variable can be easily isolated, as in this case.".into(),
                // Tier 1: Good
                "I solved the system using substitution. From x - y = 1, I got x = y + 1. I substituted this into 2x + 3y = 12: 2(y + 1) + 3y = 12. This gave 5y + 2 = 12, so y = 2. Then x = 2 + 1 = 3. The answer is (3, 2). I used substitution because it was easy to isolate x in the second equation. Checking: 2(3) + 3(2) = 12 and 3 - 2 = 1, so it's correct.".into(),
                // Tier 2: Satisfactory
                "I used substitution. From x - y = 1, x = y + 1. Put this in 2x + 3y = 12: 2(y + 1) + 3y = 12. 5y = 10, y = 2. x = 3. Answer is (3, 2). Substitution was easy here. Check: 2(3) + 3(2) = 12, 3 - 2 = 1. Correct.".into(),
                // Tier 3: Developing
                "I solved it. x = y + 1 from second equation. Put in first: 2(y + 1) + 3y = 12. y = 2, x = 3. Answer (3, 2). Used substitution. It worked.".into(),
            ],
            // Essay 2: Word problem
            [
                // Tier 0: Excellent
                "Let x be the number of adult tickets and y be the number of student tickets. The system is: x + y = 200 (total tickets) and 5x + 3y = 800 (total revenue). Using elimination, I multiply the first equation by 3: 3x + 3y = 600. Subtracting from the second equation: (5x + 3y) - (3x + 3y) = 800 - 600, which gives 2x = 200, so x = 100. Substituting into x + y = 200 gives 100 + y = 200, so y = 100. Therefore, 100 adult tickets and 100 student tickets were sold. Verification: 100 + 100 = 200 tickets ✓, and 5(100) + 3(100) = 500 + 300 = $800 ✓. This type of problem is common in business and event planning, where understanding the mix of different price points helps optimize revenue while meeting attendance goals.".into(),
                // Tier 1: Good
                "Let x = adult tickets, y = student tickets. The equations are x + y = 200 and 5x + 3y = 800. I used elimination. Multiply the first by 3: 3x + 3y = 600. Subtract from the second: 2x = 200, so x = 100. Then y = 100. So 100 adult and 100 student tickets were sold. Check: 100 + 100 = 200, and 5(100) + 3(100) = 800. This is correct.".into(),
                // Tier 2: Satisfactory
                "x = adult, y = student. x + y = 200, 5x + 3y = 800. Elimination: multiply first by 3, subtract. 2x = 200, x = 100. y = 100. 100 each. Check: 200 tickets, $800. Correct.".into(),
                // Tier 3: Developing
                "x = adult, y = student. x + y = 200, 5x + 3y = 800. Solve: x = 100, y = 100. 100 of each. Check works.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Linear equations
            [
                // Tier 0: Excellent
                "(1) For y = 3x - 7, the equation is already in slope-intercept form y = mx + b, where m = 3 is the slope and b = -7 is the y-intercept. (2) To write the equation of a line through (2,5) with slope -2, I use point-slope form: y - y₁ = m(x - x₁). Substituting: y - 5 = -2(x - 2), which simplifies to y - 5 = -2x + 4, then y = -2x + 9. In slope-intercept form, this is y = -2x + 9. (3) For 2x + y = 4, I find the intercepts: x-intercept occurs when y = 0, so 2x = 4, x = 2. The x-intercept is (2, 0). y-intercept occurs when x = 0, so y = 4. The y-intercept is (0, 4). To graph, I plot these two points and draw a line through them. The slope is -2 (rise over run: -4/2 = -2).".into(),
                // Tier 1: Good
                "(1) y = 3x - 7 has slope 3 and y-intercept -7. (2) Using point-slope: y - 5 = -2(x - 2), so y = -2x + 9. (3) For 2x + y = 4, x-intercept is (2, 0) when y = 0, and y-intercept is (0, 4) when x = 0. Graph by plotting these points and connecting them with a line. The slope is -2.".into(),
                // Tier 2: Satisfactory
                "(1) Slope = 3, y-intercept = -7. (2) y - 5 = -2(x - 2), so y = -2x + 9. (3) x-intercept (2, 0), y-intercept (0, 4). Plot points, draw line. Slope is -2.".into(),
                // Tier 3: Developing
                "(1) m = 3, b = -7. (2) y = -2x + 9. (3) x-int (2, 0), y-int (0, 4). Draw line through points.".into(),
            ],
            // Assignment 2: Word problems
            [
                // Tier 0: Excellent
                "(1) Let x and y be the two numbers. The system is x + y = 15 and x - y = 3. Adding the equations: 2x = 18, so x = 9. Substituting: 9 + y = 15, so y = 6. The numbers are 9 and 6. (2) Let p = number of pens, n = number of notebooks. The system is p + n = 20 and 2p + 5n = 70. Using substitution: p = 20 - n. Substituting: 2(20 - n) + 5n = 70, which gives 40 - 2n + 5n = 70, so 3n = 30, and n = 10. Then p = 20 - 10 = 10. So 10 pens and 10 notebooks were sold. Verification: 10 + 10 = 20 items ✓, and 2(10) + 5(10) = 20 + 50 = $70 ✓.".into(),
                // Tier 1: Good
                "(1) Let the numbers be x and y. x + y = 15, x - y = 3. Adding: 2x = 18, x = 9. Then y = 6. Numbers are 9 and 6. (2) Let p = pens, n = notebooks. p + n = 20, 2p + 5n = 70. Substitute p = 20 - n: 2(20 - n) + 5n = 70. 3n = 30, n = 10. p = 10. So 10 pens and 10 notebooks. Check: 20 items, $70. Correct.".into(),
                // Tier 2: Satisfactory
                "(1) x + y = 15, x - y = 3. Add: 2x = 18, x = 9, y = 6. (2) p + n = 20, 2p + 5n = 70. p = 20 - n. 2(20 - n) + 5n = 70. n = 10, p = 10. 10 each. Check works.".into(),
                // Tier 3: Developing
                "(1) x + y = 15, x - y = 3. x = 9, y = 6. (2) p + n = 20, 2p + 5n = 70. p = 10, n = 10. 10 of each.".into(),
            ],
        ],
    }
}

// ─── AP 10: Pre-colonial to Spanish Period ────────────────────────────────────

pub fn demo2_answers_ap_t1() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Spanish colonization impact
            [
                // Tier 0: Excellent
                "Spanish colonization had profound and lasting effects on pre-colonial Philippine society, both positive and negative. On the positive side, Spain introduced Christianity, which became a unifying force and shaped Filipino culture, values, and identity. The Spanish also established a centralized government, formal education, and new agricultural technologies. However, the negative effects were significant. The encomienda system exploited Filipino labor, while the reduccion policy disrupted traditional communities. The galleon trade created economic dependency on Mexico and Spain. The Catholic Church gained immense political power, sometimes at the expense of local autonomy. Indigenous political structures like the barangay were replaced with Spanish colonial administration. Traditional beliefs and practices were suppressed or syncretized with Catholicism. The social hierarchy became based on race and birth, creating class divisions that persist today. Despite these changes, many aspects of pre-colonial culture—language, family structure, and community values—survived and blended with Spanish influences, creating a unique Filipino hybrid culture.".into(),
                // Tier 1: Good
                "Spanish colonization changed Philippine society in many ways. Positively, it brought Christianity, education, and a centralized government. These helped unify the islands. Negatively, the encomienda system exploited Filipinos, and the galleon trade made the economy dependent on Spain. The Catholic Church became very powerful and sometimes controlled politics. Traditional barangay government was replaced by Spanish rule. Indigenous beliefs were suppressed or mixed with Catholicism. A racial hierarchy was created. However, many Filipino traditions survived and blended with Spanish culture to create a unique identity.".into(),
                // Tier 2: Satisfactory
                "Spanish colonization had good and bad effects. Good: Christianity, education, government. Bad: exploitation, dependency, church power, loss of traditions. Racial hierarchy was created. Some traditions survived and mixed with Spanish culture.".into(),
                // Tier 3: Developing
                "Spanish colonization changed things. Good: religion, education. Bad: exploitation, church power. Traditions were lost or changed. New social classes were made.".into(),
            ],
            // Essay 2: Political systems comparison
            [
                // Tier 0: Excellent
                "Pre-colonial Philippine political systems and Spanish colonial government differed fundamentally in structure, authority, and relationship to the people. The pre-colonial barangay was a small, autonomous community led by a datu who ruled by consensus and personal authority. The datu's power came from his wealth, wisdom, and ability to protect his people. Decision-making involved the council of elders, and laws were based on custom and oral tradition. In contrast, Spanish colonial government was centralized, hierarchical, and bureaucratic. Power flowed from the Governor-General in Manila down to local officials like the alcalde-mayor and gobernadorcillo. Authority came from the Spanish crown and the Catholic Church, not from the people. Laws were written and enforced by Spanish officials, often without local input. The pre-colonial system was flexible and adapted to local conditions, while the Spanish system was rigid and uniform. The barangay served its people directly, while the colonial government served Spanish interests first, exploiting Filipino resources and labor. These differences show how colonization replaced indigenous, community-based governance with foreign, extractive rule.".into(),
                // Tier 1: Good
                "Pre-colonial barangay government was different from Spanish colonial government. The barangay was small and led by a datu who ruled by consensus. The datu's power came from his abilities and the people's support. Decisions involved elders. Spanish government was centralized with the Governor-General at the top. Power came from Spain and the Church. Laws were written by Spanish officials. The barangay served the people, while Spanish rule served Spanish interests. This shows how colonization changed governance from local to foreign control.".into(),
                // Tier 2: Satisfactory
                "Barangay was led by datu with elders' help. Spanish government was centralized under Governor-General. Barangay used custom laws. Spanish used written laws. Barangay served people. Spanish served Spain. Different systems of governance.".into(),
                // Tier 3: Developing
                "Barangay had datu leader. Spanish had Governor-General. Barangay was local. Spanish was foreign. Different ways of ruling.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Pre-colonial society
            [
                // Tier 0: Excellent
                "Pre-colonial Philippine society was organized around the barangay, a political and social unit led by a datu. The datu served as chief, judge, and military leader, ruling with the support of a council of elders. His authority was based on personal qualities—wisdom, bravery, wealth—and the consent of the community. Social structure was hierarchical: the maharlika (nobles) were the elite class who owned land and served as warriors; the timawa (freemen) were commoners who could own property and participate in governance; and the alipin (dependents) were those who owed service, either by debt or captivity. The economy was based on agriculture (rice, coconut, abaca) and trade with China, India, Japan, and other Southeast Asian countries. Filipinos had their own writing system (baybayin), practiced animism and indigenous religions, and had rich oral traditions including epics like Biag ni Lam-ang. This society was already complex, organized, and culturally rich before Spanish arrival.".into(),
                // Tier 1: Good
                "Pre-colonial Philippine society was organized in barangays led by a datu. The datu was the chief, judge, and military leader. He ruled with a council of elders. Social classes were maharlika (nobles), timawa (freemen), and alipin (dependents). The economy was based on agriculture and trade with other countries. Filipinos had baybayin writing, practiced animism, and had oral traditions like epics. The society was already organized and culturally rich before the Spanish came.".into(),
                // Tier 2: Satisfactory
                "Barangay was led by datu with council of elders. Social classes: maharlika, timawa, alipin. Economy: agriculture and trade. Writing: baybayin. Religion: animism. Oral traditions: epics. Complex society before Spanish.".into(),
                // Tier 3: Developing
                "Datu led barangay. Social classes existed. Agriculture and trade. Baybayin writing. Animism religion. Epics as stories. Organized society.".into(),
            ],
            // Assignment 2: Spanish colonial system
            [
                // Tier 0: Excellent
                "(1) The encomienda system was a colonial labor system where the Spanish crown granted encomenderos the right to collect tribute from Filipinos in a specific area in exchange for protecting them and Christianizing them. In practice, it became a system of exploitation where encomenderos abused their power, forced Filipinos into labor, and collected excessive tribute. (2) The Catholic Church played a central role during Spanish colonization, serving as both religious authority and political power. Friars influenced government policies, controlled education, and often acted as local administrators. They were instrumental in converting Filipinos to Christianity and shaping colonial society. (3) The galleon trade connected Manila to Acapulco, Mexico from 1565 to 1815. It brought silver from the Americas and Asian goods (silk, porcelain, spices) to the Philippines. This trade made the Philippine economy dependent on foreign markets, shaped Manila as a commercial center, but also limited local economic development by focusing on export rather than domestic production.".into(),
                // Tier 1: Good
                "(1) The encomienda system gave Spanish officials the right to collect tribute from Filipinos in exchange for protection and Christianization. It often led to abuse and exploitation of Filipino labor. (2) The Catholic Church was very powerful during Spanish colonization. Friars influenced government, controlled education, and served as local administrators. They converted Filipinos to Christianity and shaped colonial society. (3) The galleon trade connected Manila to Mexico. It brought silver from the Americas and Asian goods to the Philippines. This made the economy dependent on foreign trade and focused on exports rather than local production.".into(),
                // Tier 2: Satisfactory
                "(1) Encomienda: Spanish officials collected tribute in exchange for protection. Often abusive. (2) Catholic Church: powerful, influenced government, controlled education, converted Filipinos. (3) Galleon trade: Manila-Mexico connection, brought silver and Asian goods, made economy dependent on exports.".into(),
                // Tier 3: Developing
                "(1) Encomienda: tribute collection for protection. (2) Church: powerful, converted Filipinos. (3) Galleon trade: connected to Mexico, brought goods.".into(),
            ],
        ],
    }
}

// ─── Filipino 10: Maikling Kuwento ─────────────────────────────────────────────

pub fn demo2_answers_fil_t1() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Elements and theme
            [
                // Tier 0: Excellent
                "Ang mga elemento ng maikling kwento tulad ng tauhan, tagpuan, at plot ay naglalarawan sa pagbuo ng tema sa pamamagitan ng pagbibigay-kahulugan at konteksto sa kwento. Sa 'How My Brother Leon Brought Home a Wife,' ang tauhan na si Maria ay kumakatawan sa pag-ibig at pag-asa, habang ang tagpuan sa probinsya ay nagpapakita ng tradisyon at simpleng buhay. Ang plot ng paglalakbay ay nagsisilbing metapora para sa pagtanggap at pagsasama. Ang tema ng pag-ibig na lumalaban sa hamon ng tradisyon ay binuo sa pamamagitan ng interaksyon ng mga tauhan sa kanilang kapaligiran. Ang bawat elemento—ang pagkilos ng tauhan, ang deskripsyon ng tagpuan, at ang pag-unlad ng plot—ay nagtutulungan upang ibunyag ang mas malalim na kahulugan ng kwento. Kung wala ang mga elemento ito, ang tema ay hindi sasabog nang buo at makabuluhan.".into(),
                // Tier 1: Good
                "Ang tauhan, tagpuan, at plot ay tumutulong sa pagbuo ng tema ng maikling kwento. Sa kwentong binasa, ang mga tauhan ay nagpapakita ng iba't ibang personalidad na nakaapekto sa kwento. Ang tagpuan ay nagbibigay ng konteksto kung saan nangyayari ang mga pangyayari. Ang plot ay nagpapakita ng pagkakasunod-sunod ng mga pangyayari na nagdudulot sa tema. Halimbawa, kung ang tagpuan ay probinsya, maaaring ang tema ay tungkol sa tradisyon. Ang mga elemento ito ay nagtutulungan upang maipahayag ang mensahe ng may-akda.".into(),
                // Tier 2: Satisfactory
                "Ang tauhan, tagpuan, at plot ay nagtutulong sa tema. Ang tauhan ay nagpapakita ng kilos. Ang tagpuan ay nagbibigay ng lugar. Ang plot ay nagpapakita ng pangyayari. Sila ay nagtutulungan upang ipakita ang kahulugan ng kwento.".into(),
                // Tier 3: Developing
                "Ang tauhan, tagpuan, at plot ay importante sa tema. Sila ay nagpapakita ng kung ano ang kwento. Ang tema ay nanggagaling sa mga ito.".into(),
            ],
            // Essay 2: Style comparison
            [
                // Tier 0: Excellent
                "Ang istilo ng pagsulat ng dalawang Pilipinong manunulat ay may pagkakatulad at pagkakaiba. Ang pagkakatulad ay sa paggamit ng wikang Filipino at pagpapahayag ng mga temang Pilipino tulad ng pamilya, pag-ibig, at lipunan. Pareho rin sila gumagamit ng mga literary device tulad ng metapora at simili. Ang pagkakaiba ay sa tono at paraan ng pagsulat. Ang unang manunulat ay maaaring gumamit ng mas pormal na wika at detalyadong deskripsyon, habang ang ikalawa ay maaaring gumamit ng mas simpleng wika at direktong paglalahad. Ang unang manunulat ay maaaring nakatuon sa makasining na paglalahad, habang ang ikalawa ay mas nakatuon sa realismo. Ang mga akda ay parehong nagpapakita ng kultura ngunit sa iba't ibang pananaw at estilo.".into(),
                // Tier 1: Good
                "Ang dalawang manunulat ay parehong gumagamit ng wikang Filipino at nagpapakita ng mga temang Pilipino. Pareho rin sila gumagamit ng literary device. Ang pagkakaiba ay sa istilo ng pagsulat. Ang isa ay mas pormal at detalyado, habang ang isa ay mas simple at direkt. Ang iba ay mas makasining, habang ang iba ay mas realistiko. Pareho silang nagpapakita ng kultura ngunit sa iba't ibang paraan.".into(),
                // Tier 2: Satisfactory
                "Pareho silang gumagamit ng Filipino at Pilipinong tema. Pareho ring gumagamit ng literary device. Pagkakaiba: iba-iba ang istilo. Iba-iba ang tono. Pareho silang nagpapakita ng kultura.".into(),
                // Tier 3: Developing
                " pareho silang Pilipino. Pareho silang gumagamit ng device. Iba ang istilo. Iba ang tono. Pareho silang tungkol sa kultura.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Theme analysis
            [
                // Tier 0: Excellent
                "Sa maikling kwentong 'The Wedding Dance,' ang tema ay tungkol sa suliranin sa pagitan ng personal na pagnanasa at kultural na tradisyon. Ang may-akda na si Amador Daguio ay binuo ang tema ito sa pamamagitan ng mga tauhan na sina Awiyao at Lumnay, na nagmamahalan sa isa't isa ngunit kailangang maghiwalay dahil sa tribal custom. Ang tagpuan sa gabi sa barangay, kasama ang tunog ng sayaw sa kasal, ay lumilikha ng mood na lungkot at inevitabilidad. Ang plot ay nag-unfold sa pamamagitan ng dialogue na nagpapakita ng emosyonal na struggle ng mga tauhan—ang tungkulin ni Awiyao sa tribo at ang pride at pag-ibig ni Lumnay. Ang bead necklace na ibinalik ni Awiyao kay Lumnay ay sumisimbolo sa kanilang broken relationship. Sa pamamagitan ng mga elementong ito, ipinapakita ng Daguio kung paano ang mga kultural na tradisyon ay maaaring magpreserba ng komunidad at magdulot ng individual suffering.".into(),
                // Tier 1: Good
                "Sa 'The Wedding Dance,' ang tema ay tungkol sa pag-ibig laban sa tradisyon. Ang may-akda ay nagpakita nito sa pamamagitan ni Awiyao at Lumnay na nagmamahalan pero kailangang maghiwalay dahil sa custom. Ang tagpuan sa gabi ay nagpapakita ng lungkot. Ang plot ay gumagamit ng dialogue para ipakita ang feelings nila. Ang bead necklace ay sumisimbolo sa kanilang separation. Ang kwento ay nagpapakita kung paano ang tradisyon ay makakasakit sa tao.".into(),
                // Tier 2: Satisfactory
                "Ang tema ng 'The Wedding Dance' ay pag-ibig at tradisyon. Awiyao at Lumnay nagmamahalan pero maghiwalay dahil custom. Ang tagpuan ay lungkot. Ang dialogue ay nagpapakita ng feelings. Ang necklace ay simbolo ng separation. Tradisyon ay makakasakit.".into(),
                // Tier 3: Developing
                "Ang tema ay pag-ibig at tradisyon. Awiyao at Lumnay separate dahil custom. Tagpuan ay gabi. Sila ay sad. Necklace ay important. Tradisyon ay hard.".into(),
            ],
            // Assignment 2: Literary devices
            [
                // Tier 0: Excellent
                "Sa tula ni Jose Rizal na 'Sa Aking mga Kabata,' tatlong elemento ng panitikan ang kitang-kita. Una, ang metapora sa 'Ang hindi magmahal sa sariling wika,' kung saan ang pagmamahal sa wika ay inihalintulad sa pagmamahal sa sarili, na nagpapahiwatig na ang wika ay bahagi ng identity. Ikalawa, ang personipikasyon sa 'mahigit kumulang pumuti't ang buhok,' kung saan ang pagputi ng buhok ay binigyan ng katangiang tao upang sumimbolo sa pagdaan ng panahon at ang urgency ng pagpapanatili ng heritage. Ikatlo, ang parallelism sa istraktura na 'ang hindi magmahal sa sariling wika' na inuulit may variations, na lumilikha ng rhythmic emphasis na nagpapatibay sa mensahe ng tula tungkol sa kahalagahan ng pagmamahal sa sariling wika. Ang mga device na ito ay nagtutulungan upang lumikha ng persuasive argument tungkol sa national identity at cultural pride.".into(),
                // Tier 1: Good
                "Sa 'Sa Aking mga Kabata,' si Rizal ay gumamit ng metapora kung saan inihalintulad ang pagmamahal sa wika sa pagmamahal sa sarili. Ito ay nagpapakita na ang wika ay bahagi ng identity. Gumamit siya ng personipikasyon sa pagputi ng buhok upang ipakita ang pagdaan ng panahon. Ang parallelism ay ginamit sa repeated structure upang bigyang-diin ang mensahe. Ang mga device na ito ay gumagawa ng tula na mas malakas ang mensahe tungkol sa pagmamahal sa ating wika.".into(),
                // Tier 2: Satisfactory
                "Ang tula ay gumagamit ng metapora na inihalintulad ang wika sa sarili. Personipikasyon ay nagpapakita ng pagtanda ng buhok. Parallelism ay inuulit ang istraktura. Ang mga device ay nagbibigay-diin sa mensahe tungkol sa pagmamahal sa wika. Sila ay gumagawa ng tula na mas epektibo.".into(),
                // Tier 3: Developing
                "Metapora ay inihalintulad ang wika sa sarili. Personipikasyon ay nagpapakita ng pagtanda. Parallelism ay inuulit ang mga salita. Ang mga device ay tumutulong sa mensahe. Ang tula ay tungkol sa pagmamahal sa wika.".into(),
            ],
        ],
    }
}

// ─── TLE 10: Computer Hardware Servicing ─────────────────────────────────────

pub fn demo2_answers_tle_t1() -> SubjectTermAnswers {
    SubjectTermAnswers {
        exam_essays: vec![
            // Essay 1: Assembly process
            [
                // Tier 0: Excellent
                "The step-by-step process of assembling a computer begins with preparing a clean, static-free workspace and gathering all necessary components: motherboard, CPU, RAM, storage, power supply, and case. First, install the CPU into the motherboard socket, being careful to align the pins and apply thermal paste if needed. Next, install the RAM sticks into the appropriate slots, ensuring they click into place. Then, mount the motherboard into the case, connecting the I/O shield and standoffs. Install the power supply and connect the 24-pin motherboard power cable and CPU power cable. Install the storage drives (SSD/HDD) and connect SATA data and power cables. If using a GPU, install it into the PCIe slot and connect its power cable. Finally, connect the case fans, front panel headers (power switch, reset switch, LEDs), and any USB/audio headers. Safety precautions include: always wearing an anti-static wrist strap, powering off and unplugging before working, handling components by edges, and never forcing connections. Challenges include cable management, ensuring proper alignment, and troubleshooting if the system doesn't boot on first try.".into(),
                // Tier 1: Good
                "To assemble a computer, first prepare a clean workspace and gather components: motherboard, CPU, RAM, storage, PSU, and case. Install the CPU into the motherboard socket with thermal paste. Install RAM into the slots. Mount the motherboard in the case with standoffs. Install the PSU and connect motherboard and CPU power cables. Install storage drives and connect SATA cables. Install the GPU if needed and connect its power. Connect case fans and front panel headers. Safety: wear anti-static strap, power off before working, handle components by edges. Challenges: cable management, proper alignment, and troubleshooting if it doesn't boot.".into(),
                // Tier 2: Satisfactory
                "Prepare workspace, gather parts. Install CPU with thermal paste. Install RAM. Mount motherboard in case. Install PSU, connect power cables. Install storage, connect SATA. Install GPU, connect power. Connect fans and headers. Safety: anti-static strap, power off, handle carefully. Challenges: cables, alignment, troubleshooting.".into(),
                // Tier 3: Developing
                "Get parts ready. Install CPU. Install RAM. Put motherboard in case. Install PSU. Connect power. Install storage. Install GPU. Connect everything. Safety: don't shock, power off. Challenges: cables, making it work.".into(),
            ],
            // Essay 2: ESD protection
            [
                // Tier 0: Excellent
                "ESD (Electrostatic Discharge) protection is critically important in computer servicing because static electricity can damage sensitive electronic components without visible signs of damage. A static shock as small as 10 volts can harm a CPU, while humans can't feel shocks below 3,000 volts. This means you can damage components without even knowing it. Consequences of not using proper ESD protection include: immediate component failure, intermittent errors that are hard to diagnose, reduced component lifespan, and costly replacements. To prevent ESD, always use an anti-static wrist strap connected to a grounded surface, work on anti-static mats, avoid working on carpeted surfaces, touch a grounded metal object before handling components, and keep components in anti-static bags until installation. Proper ESD protection is a small investment that prevents expensive damage and ensures reliable system operation.".into(),
                // Tier 1: Good
                "ESD protection is important because static electricity can damage computer parts. Even small shocks that you can't feel can harm components like CPUs. If you don't use ESD protection, parts can fail immediately or have problems later. This costs money to replace. To prevent ESD, use an anti-static wrist strap connected to ground, work on anti-static mats, avoid carpet, touch metal before handling parts, and keep parts in anti-static bags. ESD protection prevents expensive damage and keeps systems working reliably.".into(),
                // Tier 2: Satisfactory
                "ESD protection prevents static damage. Small shocks can hurt parts. Without protection, parts can fail or have errors. This costs money. Prevention: use anti-static strap, avoid carpet, touch metal, use anti-static bags. Protection saves money and prevents damage.".into(),
                // Tier 3: Developing
                "ESD protection stops static damage. Static can break parts. Without it, parts fail. Use anti-static strap. Avoid carpet. Touch metal. Keep parts in bags. Protection is important.".into(),
            ],
        ],
        assignments: vec![
            // Assignment 1: Lab report
            [
                // Tier 0: Excellent
                "The computer assembly process began with preparing a clean, anti-static workspace and organizing all components: motherboard, CPU, RAM, SSD, PSU, and case. Safety precautions included wearing an anti-static wrist strap and ensuring the workspace was free of static-generating materials. First, I installed the Intel i5 CPU into the LGA socket, aligning the notches carefully. I applied a pea-sized amount of thermal paste to the CPU heat spreader. Next, I installed two 8GB DDR4 RAM sticks into the dual-channel slots, ensuring they clicked into place. I then mounted the motherboard into the case using standoffs to prevent short circuits. The PSU was installed at the bottom, and I connected the 24-pin motherboard power and 8-pin CPU power cables. The 500GB SSD was mounted in a drive bay and connected with SATA data and power cables. Finally, I connected the case fans and front panel headers following the motherboard manual. The main challenge was cable management—I had to route cables neatly to ensure good airflow. The system powered on successfully on the first attempt, confirming proper assembly.".into(),
                // Tier 1: Good
                "I assembled a computer with a motherboard, CPU, RAM, SSD, PSU, and case. Safety: wore anti-static wrist strap, clean workspace. Steps: installed CPU with thermal paste, installed RAM, mounted motherboard in case with standoffs, installed PSU and connected power cables, installed SSD with SATA cables, connected fans and front panel headers. Challenge: cable management was difficult, had to route cables neatly for airflow. Result: system powered on successfully, assembly was correct.".into(),
                // Tier 2: Satisfactory
                "Assembled computer with parts: motherboard, CPU, RAM, SSD, PSU, case. Safety: anti-static strap. Steps: CPU with paste, RAM, motherboard in case, PSU with power, SSD with SATA, fans and headers. Challenge: cable management hard. Result: worked on first try.".into(),
                // Tier 3: Developing
                "Put computer together. Parts: motherboard, CPU, RAM, SSD, PSU, case. Safety: strap. Steps: CPU, RAM, motherboard, PSU, SSD, fans. Challenge: cables. Result: it worked.".into(),
            ],
            // Assignment 2: Components
            [
                // Tier 0: Excellent
                "(1) The CPU (Central Processing Unit) is the brain of the computer, executing instructions and performing calculations for all software and operations. It processes data by fetching, decoding, and executing instructions at high speeds. (2) RAM (Random Access Memory) and ROM (Read-Only Memory) differ in function and volatility. RAM is temporary, volatile memory that stores data currently in use by the CPU; it loses data when power is turned off. ROM is permanent, non-volatile memory that stores essential system instructions and firmware; it retains data even without power. RAM is much faster than ROM and can be written to and read from, while ROM is typically read-only. (3) Thermal paste is important when installing a CPU because it fills microscopic gaps between the CPU heat spreader and the cooler's base. Without thermal paste, air pockets would form, creating poor thermal contact and causing the CPU to overheat. Thermal paste improves heat transfer, ensuring efficient cooling and preventing thermal throttling or damage to the CPU.".into(),
                // Tier 1: Good
                "(1) The CPU is the computer's brain. It executes instructions and processes data for all programs and operations. (2) RAM is temporary memory that stores data currently in use. It loses data when power is off. ROM is permanent memory that stores system instructions. It keeps data without power. RAM is faster and can be written to, while ROM is read-only. (3) Thermal paste fills gaps between the CPU and cooler. Without it, air pockets cause poor heat transfer and overheating. Thermal paste improves cooling and prevents CPU damage.".into(),
                // Tier 2: Satisfactory
                "(1) CPU is the brain, executes instructions. (2) RAM is temporary, loses data without power. ROM is permanent, keeps data. RAM is faster, writable. ROM is read-only. (3) Thermal paste fills gaps for heat transfer. Without it, overheating occurs. Important for cooling.".into(),
                // Tier 3: Developing
                "(1) CPU processes instructions. (2) RAM is temporary, ROM is permanent. (3) Thermal paste helps cooling. Without it, CPU overheats. Important for heat transfer.".into(),
            ],
        ],
    }
}
