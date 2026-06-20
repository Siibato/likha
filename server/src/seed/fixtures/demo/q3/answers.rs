//! Q3 pre-written tiered student answers for demo seeding.

use super::super::QuarterAnswers;

pub fn demo_answers_q3() -> QuarterAnswers {
    QuarterAnswers {
        exam_essay_1: [
            // Tier 0: Excellent
            "Ionic and covalent bonding represent two fundamentally different ways that atoms combine to form compounds, and these differences produce compounds with very different properties. Ionic bonding occurs when a metal transfers one or more electrons to a non-metal, creating oppositely charged ions that are held together by strong electrostatic attraction. A real-world example is sodium chloride (NaCl), or table salt. Because ionic compounds form crystal lattices with strong bonds, they tend to have high melting points and dissolve easily in water. When dissolved, they dissociate into ions, allowing the solution to conduct electricity. In contrast, covalent bonding involves the sharing of electron pairs between atoms, usually non-metals. Water (H2O) is a classic example: oxygen shares electrons with two hydrogen atoms. Covalent compounds typically have lower melting points than ionic compounds, do not conduct electricity when dissolved, and may be gases, liquids, or soft solids at room temperature. These property differences arise directly from the nature of the bonding: the strong, non-directional ionic bonds create rigid crystals, while the directional covalent bonds form discrete molecules with weaker intermolecular forces.".into(),
            // Tier 1: Good
            "Ionic bonds form when metals give electrons to non-metals, creating charged ions that attract each other. Table salt (NaCl) is an example. Ionic compounds have high melting points and conduct electricity when dissolved. Covalent bonds form when atoms share electrons, like in water (H2O). Covalent compounds usually have lower melting points and do not conduct electricity. The type of bond determines the properties of the compound.".into(),
            // Tier 2: Satisfactory
            "Ionic bonds transfer electrons and form salts like NaCl. They have high melting points. Covalent bonds share electrons like in water. They have lower melting points. Bonds affect compound properties.".into(),
            // Tier 3: Developing
            "Ionic bonds give electrons. Salt is ionic. Covalent bonds share. Water is covalent. Ionic is stronger.".into(),
        ],
        exam_essay_2: [
            // Tier 0: Excellent
            "Balancing chemical equations is necessary to satisfy the law of conservation of mass, which states that matter cannot be created or destroyed in a chemical reaction. This means that the number of atoms of each element must be equal on both sides of the equation. Coefficients are whole numbers placed before chemical formulas to indicate how many molecules or formula units are involved in the reaction. For example, the unbalanced equation H2 + O2 -> H2O shows two hydrogen atoms and two oxygen atoms on the left, but only two hydrogen atoms and one oxygen atom on the right. To balance it, we place a coefficient of 2 before H2O and a coefficient of 2 before H2, giving the balanced equation 2H2 + O2 -> 2H2O. Now there are four hydrogen atoms and two oxygen atoms on each side. A real-world example is the combustion of methane: CH4 + 2O2 -> CO2 + 2H2O. This balanced equation tells us that one molecule of methane reacts with two molecules of oxygen to produce one molecule of carbon dioxide and two molecules of water. Without balancing, we would incorrectly predict the amounts of reactants and products, which is critical in engineering, medicine, and environmental science.".into(),
            // Tier 1: Good
            "Chemical equations must be balanced because mass cannot be created or destroyed. Coefficients show how many molecules are needed. For example, H2 + O2 -> H2O is not balanced. We change it to 2H2 + O2 -> 2H2O so atoms are equal on both sides. In real life, burning methane is CH4 + 2O2 -> CO2 + 2H2O. Balancing helps us know how much of each substance is used.".into(),
            // Tier 2: Satisfactory
            "Equations must be balanced because mass stays the same. Coefficients fix the numbers. H2 + O2 becomes 2H2 + O2 -> 2H2O. Burning methane is CH4 + 2O2 -> CO2 + 2H2O.".into(),
            // Tier 3: Developing
            "Balancing equations keeps mass same. Coefficients fix numbers. Water equation needs 2H2 and 2H2O.".into(),
        ],
        assignment_1: [
            // Tier 0: Excellent
            "Ionic compounds form through the transfer of electrons from metals to non-metals, creating a crystal lattice structure held together by electrostatic attraction. They are typically hard, brittle solids with high melting points and good electrical conductivity when dissolved in water or molten. Common examples include table salt (NaCl) and limestone (CaCO3). Covalent compounds form when non-metal atoms share electrons, creating discrete molecules. They often exist as gases, liquids, or soft solids with lower melting points. Examples include water (H2O), sugar (C12H22O11), and carbon dioxide (CO2). Ionic compounds tend to dissolve in polar solvents like water because water molecules can surround and separate the ions. Covalent compounds generally do not conduct electricity because they lack free-moving charged particles. These differences make ionic compounds useful for applications requiring conductivity or high melting points, while covalent compounds are essential for biological processes and organic chemistry.".into(),
            // Tier 1: Good
            "Ionic compounds form when metals and non-metals trade electrons. They are hard, have high melting points, and conduct electricity when dissolved. Examples are salt and limestone. Covalent compounds form when atoms share electrons. They have lower melting points and do not conduct electricity. Examples are water and sugar. Ionic compounds dissolve in water, but covalent ones usually do not.".into(),
            // Tier 2: Satisfactory
            "Ionic compounds transfer electrons and are hard solids like salt. Covalent compounds share electrons and are softer like sugar. Ionic conducts when dissolved. Covalent does not.".into(),
            // Tier 3: Developing
            "Ionic compounds are hard like salt. Covalent compounds are soft like sugar. Ionic conducts. Covalent does not.".into(),
        ],
        assignment_2: [
            // Tier 0: Excellent
            "(1) Chemical equations must be balanced to obey the law of conservation of mass, ensuring that the same number of each type of atom exists on both sides of the equation. (2) A coefficient is a whole number placed in front of a chemical formula that indicates how many molecules or formula units of that substance are involved in the reaction. It multiplies all atoms in the formula. (3) A real-life example of a balanced equation is the combustion of propane in gas stoves: C3H8 + 5O2 -> 3CO2 + 4H2O. This tells us that one molecule of propane reacts with five molecules of oxygen to produce three molecules of carbon dioxide and four molecules of water. Understanding this balance is important for ensuring safe and efficient fuel use in households and industries.".into(),
            // Tier 1: Good
            "(1) Equations must be balanced so mass is conserved. (2) A coefficient tells how many molecules of a substance are in the reaction. (3) Burning propane in stoves is C3H8 + 5O2 -> 3CO2 + 4H2O. This is important for safe cooking.".into(),
            // Tier 2: Satisfactory
            "(1) Balancing keeps mass same. (2) Coefficients show molecule numbers. (3) Propane burning is a balanced equation example.".into(),
            // Tier 3: Developing
            "(1) Balancing keeps mass equal. (2) Coefficients count molecules. (3) Gas stove uses balanced equation.".into(),
        ],
    }
}
