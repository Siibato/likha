//! T3 learning modules for demo-2: 6 subjects × 2 modules each (12 total).

use super::super::{cid, mid};
use crate::seed::specs::MaterialSpec;
use crate::seed::tools::SeedContext;

pub fn demo2_materials_t3(ctx: &SeedContext) -> Vec<MaterialSpec> {
    let mut materials = Vec::with_capacity(12);

    // Science 10: Chemistry
    materials.push(MaterialSpec {
        id: mid("sci_t3_mod1"),
        class_id: cid("sci10"),
        title: "Module 1: Chemical Bonding".into(),
        description: Some("Covers ionic bonds, covalent bonds, metallic bonds, and molecular structure.".into()),
        content_text: Some(
            "Chemical bonds are the forces that hold atoms together in molecules and compounds. There are three main types of chemical bonds. \
            Ionic bonds form when atoms transfer electrons, creating positive and negative ions that attract each other. Table salt (NaCl) is a classic example, where sodium transfers an electron to chlorine. \
            Covalent bonds form when atoms share electrons. In a water molecule (H2O), oxygen shares electrons with two hydrogen atoms, creating a polar molecule. \
            Metallic bonds occur in metals where electrons are delocalized and shared among all atoms, giving metals their characteristic properties like conductivity and malleability. \
            The type of bond formed depends on the electronegativity difference between atoms. Large differences lead to ionic bonds, while small differences lead to covalent bonds. \
            Understanding chemical bonding is essential for explaining the properties of substances and predicting how they will react in chemical processes."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("sci_t3_mod2"),
        class_id: cid("sci10"),
        title: "Module 2: Chemical Reactions".into(),
        description: Some("Covers types of reactions, balancing equations, and everyday applications.".into()),
        content_text: Some(
            "A chemical reaction is a process that transforms one set of chemical substances to another. The starting materials are called reactants, and the substances formed are called products. \
            Chemical reactions follow the law of conservation of mass, which states that matter is neither created nor destroyed in a chemical reaction. This is why chemical equations must be balanced. \
            Common types of reactions include synthesis (A + B → AB), decomposition (AB → A + B), single replacement (AB + C → AC + B), double replacement (AB + CD → AD + CB), and combustion (reaction with oxygen). \
            Combustion reactions, such as burning fuel, release energy in the form of heat and light. Endothermic reactions absorb energy, while exothermic reactions release energy. \
            Chemical reactions are everywhere in everyday life: cooking involves chemical changes, rusting is oxidation, and digestion breaks down food through chemical processes. \
            Catalysts are substances that speed up reactions without being consumed, playing crucial roles in industrial processes and biological systems."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // English 10: Academic Writing
    materials.push(MaterialSpec {
        id: mid("eng_t3_mod1"),
        class_id: cid("eng10"),
        title: "Module 1: Features of Academic Writing".into(),
        description: Some("Covers formal tone, structure, thesis statements, and evidence.".into()),
        content_text: Some(
            "Academic writing is a formal style of writing used in scholarly publications and educational settings. It is characterized by a formal tone, objective language, and precise terminology. \
            The basic structure of an academic essay includes an introduction that presents the topic and thesis statement, body paragraphs that provide supporting evidence and analysis, and a conclusion that summarizes the main points and restates the thesis. \
            A thesis statement is a clear, arguable claim that guides the entire essay. It should be specific, debatable, and supported by evidence throughout the paper. \
            Evidence in academic writing must come from credible sources and be properly cited. Common citation styles include APA (American Psychological Association) and MLA (Modern Language Association). \
            Academic writing requires critical thinking, logical organization, and the ability to synthesize information from multiple sources. It differs from creative or personal writing in its purpose, audience, and style."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("eng_t3_mod2"),
        class_id: cid("eng10"),
        title: "Module 2: Claims and Arguments".into(),
        description: Some("Covers types of claims, counterarguments, and position papers.".into()),
        content_text: Some(
            "In academic writing, claims are the main arguments or assertions that writers make. There are three main types of claims: claims of fact (verifiable statements), claims of value (judgments about worth), and claims of policy (calls to action). \
            A position paper presents an argument on a controversial issue and supports it with evidence. It should acknowledge counterarguments—opposing viewpoints—and address them with additional evidence or reasoning. \
            Strong arguments are built on logical reasoning, credible evidence, and clear organization. Writers must avoid logical fallacies such as ad hominem attacks, straw man arguments, and false dilemmas. \
            Plagiarism—the use of someone else's work without proper credit—is a serious academic offense. Proper citation practices give credit to original sources and allow readers to verify information. \
            Academic integrity is fundamental to scholarly work. It includes honesty in research, proper attribution of sources, and respect for intellectual property rights."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // Math 10: Geometry
    materials.push(MaterialSpec {
        id: mid("math_t3_mod1"),
        class_id: cid("math10"),
        title: "Module 1: Geometric Sequences".into(),
        description: Some("Covers geometric sequences, common ratio, nth term formula, and series.".into()),
        content_text: Some(
            "A geometric sequence is a sequence where each term after the first is found by multiplying the previous term by a constant called the common ratio (r). \
            The formula for the nth term is an = a1 × r^(n-1), where a1 is the first term, r is the common ratio, and n is the term number. \
            For example, in the sequence 2, 6, 18, 54, the common ratio is 3, and the nth term is an = 2 × 3^(n-1). \
            The sum of the first n terms of a geometric series is Sn = a1(1 - r^n) / (1 - r) when r ≠ 1. If |r| < 1, the infinite series converges to S = a1 / (1 - r). \
            Geometric sequences model many real-world phenomena including population growth, compound interest, radioactive decay, and bacterial reproduction. \
            When the common ratio is greater than 1, the sequence grows exponentially. When it is between 0 and 1, the sequence decays toward zero."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("math_t3_mod2"),
        class_id: cid("math10"),
        title: "Module 2: Applications of Geometric Sequences".into(),
        description: Some("Covers real-world applications including finance, population growth, and decay.".into()),
        content_text: Some(
            "Geometric sequences have numerous practical applications in finance, science, and everyday life. \
            In finance, compound interest follows a geometric sequence. If you invest P at an annual interest rate r, after n years you have P(1 + r)^n. This is why starting to save early is so powerful. \
            Population growth can be modeled geometrically when each generation multiplies by a constant factor. Bacterial cultures also grow geometrically under ideal conditions, doubling at regular intervals. \
            Depreciation of assets often follows a geometric pattern, where value decreases by a fixed percentage each year. \
            Radioactive decay is a natural example of a geometric sequence with a common ratio less than 1, as the amount of radioactive material decreases by a constant percentage over time. \
            Understanding these applications helps students see the relevance of mathematics to real-world situations and decision-making."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // AP 10: Contemporary PH History
    materials.push(MaterialSpec {
        id: mid("ap_t3_mod1"),
        class_id: cid("ap10"),
        title: "Module 1: Independence to Martial Law".into(),
        description: Some("Covers Third Republic, Martial Law declaration, and human rights situation.".into()),
        content_text: Some(
            "The Philippines gained independence from the United States on July 4, 1946, establishing the Third Republic. This period was characterized by democratic governance but also faced challenges of post-war reconstruction and economic development. \
            The Third Republic saw the election of presidents including Manuel Roxas, Elpidio Quirino, Ramon Magsaysay, Carlos Garcia, Diosdado Macapagal, and Ferdinand Marcos. \
            On September 21, 1972, President Ferdinand Marcos declared Martial Law through Proclamation 1081, citing rising communism and insurgency. This suspended the writ of habeas corpus, dissolved Congress, and centralized power in the executive branch. \
            Martial Law was marked by human rights abuses, including arbitrary arrests, torture, and disappearances. Media was censored, and political opposition was suppressed. \
            The economy initially grew under Martial Law but later suffered from corruption, cronyism, and mismanagement. The period also saw massive infrastructure projects but at great social cost."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("ap_t3_mod2"),
        class_id: cid("ap10"),
        title: "Module 2: People Power and Contemporary Issues".into(),
        description: Some("Covers the 1986 EDSA Revolution, post-Martial Law period, and contemporary challenges.".into()),
        content_text: Some(
            "The People Power Revolution of 1986, also known as the EDSA Revolution, was a nonviolent uprising that ousted Ferdinand Marcos and restored democracy. Millions of Filipinos gathered at EDSA to support Corazon Aquino, who had won the snap elections. \
            The revolution inspired similar movements around the world and marked a new chapter in Philippine history, emphasizing the power of peaceful protest and people's unity. \
            The post-Martial Law period saw the restoration of democratic institutions, a new constitution (1987), and the return of press freedom. However, it also faced challenges including political instability, economic difficulties, and the persistence of social problems. \
            Contemporary issues facing the Philippines include poverty, corruption, environmental degradation, drug abuse, and political dynasties. Globalization has brought economic opportunities but also challenges to local industries and cultural identity. \
            Understanding this history is crucial for addressing contemporary issues and building a better future. The lessons of Martial Law and People Power remind Filipinos of the importance of democracy, human rights, and civic engagement."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // Filipino 10: Sanaysay at Komunikasyon
    materials.push(MaterialSpec {
        id: mid("fil_t3_mod1"),
        class_id: cid("fil10"),
        title: "Module 1: Mga Elemento ng Sanaysay".into(),
        description: Some("Tinatalakay ang istraktura ng sanaysay, thesis statement, at pagbuo ng argumento.".into()),
        content_text: Some(
            "Ang sanaysay ay isang akademikong sulatin na nagpapahayag ng isang pananaw o argumento tungkol sa isang paksa. \
            Ang istraktura ng sanaysay ay binubuo ng introduction (panimula), body (katawan), at conclusion (konklusyon). \
            Ang introduction ay nagpapakilala ng paksa at thesis statement na siyang pangunahing argumento. Ang thesis statement ay dapat maging malinat, arguable, at supported ng ebidensya. \
            Ang body paragraphs ay nagbibigay ng supporting evidence at analysis. Bawat paragraph ay dapat may topic sentence na sumusuporta sa thesis. \
            Ang conclusion ay nagbubuod ng mga puntos at nagrerestatement ng thesis sa ibang paraan. \
            Ang sanaysay ay nangangailangan ng critical thinking, logical organization, at proper citation ng sources."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("fil_t3_mod2"),
        class_id: cid("fil10"),
        title: "Module 2: Wastong Komunikasyon at Integridad".into(),
        description: Some("Tinatalakay ang wastong komunikasyon, citation styles, at pag-iwas sa plagiarism.".into()),
        content_text: Some(
            "Ang wastong komunikasyon ay mahalaga sa akademikong pagsulat at sa pang-araw-araw na buhay. Ito ay nangangangailangan ng malinat na pagpapahayag, tamang gamit ng wika, at pagrespeto sa mambabasa. \
            Sa akademikong pagsulat, ang citation ay nagbibigay ng credit sa mga orihinal na authors. Ito ay nagpapakita ng academic integrity at nagpapaiwas sa plagiarism. \
            Ang plagiarism ay ang paggamit ng trabaho ng iba nang walang proper credit. Ito ay isang seryosong academic offense na may mga konsekwensya tulad ng failing grade at expulsion. \
            Para iwasan ang plagiarism, dapat: (1) always cite sources, (2) use quotation marks for direct quotes, (3) paraphrase properly, (4) keep track of research notes. \
            Ang academic integrity ay fundamental sa scholarly work. Ito ay kasama ang honesty sa research, proper attribution, at respect sa intellectual property."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // TLE 10: Entrepreneurship
    materials.push(MaterialSpec {
        id: mid("tle_t3_mod1"),
        class_id: cid("tle10"),
        title: "Module 1: Business Opportunities and Planning".into(),
        description: Some("Covers identifying business opportunities, SWOT analysis, and business plan components.".into()),
        content_text: Some(
            "Entrepreneurship is the process of starting and running a new business. It begins with identifying a business opportunity—a need in the market that can be met with a product or service. \
            A business plan is a document that outlines the business concept, target market, marketing strategy, operational plan, and financial projections. It serves as a roadmap for the business and is essential for attracting investors. \
            SWOT analysis helps entrepreneurs assess their business idea by examining Strengths, Weaknesses, Opportunities, and Threats. This analysis guides strategic planning and risk management. \
            Key components of a business plan include: executive summary, company description, market analysis, organization and management, service or product line, marketing and sales strategy, financial projections, and funding request. \
            Capital is the money needed to start and operate a business. Sources include personal savings, loans from banks or family, and investments from venture capitalists or angel investors."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("tle_t3_mod2"),
        class_id: cid("tle10"),
        title: "Module 2: Business Operations and Financial Management".into(),
        description: Some("Covers bookkeeping, financial statements, marketing, and customer service.".into()),
        content_text: Some(
            "Successful business operations require effective financial management, marketing, and customer service. \
            Bookkeeping is the recording of financial transactions. It provides the data needed to create financial statements like the balance sheet (assets, liabilities, equity) and income statement (revenue, expenses, profit). \
            Financial management involves planning, organizing, directing, and controlling financial activities. It includes budgeting, cash flow management, and investment decisions. Poor financial management is a leading cause of business failure. \
            Marketing is the process of promoting and selling products or services. It involves market research, identifying target customers, developing pricing strategies, advertising, and sales. Effective marketing attracts and retains customers. \
            Customer service is crucial for business success. Good customer service builds loyalty, generates positive word-of-mouth, and differentiates a business from competitors. \
            Innovation and adaptability are also important for long-term success, as markets and technologies change over time."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    materials
}
