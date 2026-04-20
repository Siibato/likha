use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();

        // Clear sample data, insert full Grade 7-12 MELCS
        db.execute_unprepared("DELETE FROM melcs;").await?;

        // ===== GRADE 7 MATHEMATICS =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','7',1,'M7NS-Ia-1','describes well-defined sets, subsets, universal sets, and the null set and cardinality of sets','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ia-2','illustrates the union and intersection of sets and the difference of two sets','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ib-1','uses Venn Diagrams to represent sets, subsets, and set operations','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ib-2','solves problems involving sets','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ic-1','represents the absolute value of a number on a number line as the distance of a number from 0','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ic-d-1','performs fundamental operations on integers','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ie-1','illustrates the different properties of operations on the set of integers','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-If-1','expresses rational numbers from fraction form to decimal form and vice versa','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-If-2','performs operations on rational numbers','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ig-1','describes principal roots and tells whether they are rational or irrational','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ig-2','determines between what two integers the square root of a number is','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ih-1','illustrates the different subsets of real numbers','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ih-2','arranges real numbers in increasing or decreasing order and on a number line','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ii-1','writes numbers in scientific notation and vice versa','Numbers and Number Sense'),
('Mathematics','7',1,'M7NS-Ij-1','represents real-life situations and conditions using real numbers','Numbers and Number Sense');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','7',2,'M7AL-IIa-1','illustrates what it means to raise a number to a rational exponent','Algebra'),
('Mathematics','7',2,'M7AL-IIa-2','simplifies expressions with rational exponents','Algebra'),
('Mathematics','7',2,'M7AL-IIb-1','writes expressions with rational exponents as radicals and vice versa','Algebra'),
('Mathematics','7',2,'M7AL-IIb-2','derives the laws of radicals','Algebra'),
('Mathematics','7',2,'M7AL-IIc-1','simplifies radical expressions using the laws of radicals','Algebra'),
('Mathematics','7',2,'M7AL-IIc-2','performs operations on radical expressions','Algebra'),
('Mathematics','7',2,'M7AL-IId-1','solves equations involving radical expressions','Algebra'),
('Mathematics','7',2,'M7AL-IId-2','solves problems involving radicals','Algebra'),
('Mathematics','7',2,'M7AL-IIe-1','defines and illustrates polynomials','Algebra'),
('Mathematics','7',2,'M7AL-IIe-2','evaluates polynomials','Algebra'),
('Mathematics','7',2,'M7AL-IIe-g-1','adds and subtracts polynomials','Algebra'),
('Mathematics','7',2,'M7AL-IIg-1','derives the laws of exponents','Algebra'),
('Mathematics','7',2,'M7AL-IIh-1','multiplies and divides polynomials','Algebra'),
('Mathematics','7',2,'M7AL-IIi-1','uses models and algebraic methods to find the product of two binomials','Algebra'),
('Mathematics','7',2,'M7AL-IIj-1','solves problems involving polynomials','Algebra');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','7',3,'M7AL-IIIa-1','factors completely different types of polynomials','Algebra'),
('Mathematics','7',3,'M7AL-IIIb-1','solves problems involving factors of polynomials','Algebra'),
('Mathematics','7',3,'M7AL-IIIc-1','illustrates rational algebraic expressions','Algebra'),
('Mathematics','7',3,'M7AL-IIIc-2','simplifies rational algebraic expressions','Algebra'),
('Mathematics','7',3,'M7AL-IIId-1','performs operations on rational algebraic expressions','Algebra'),
('Mathematics','7',3,'M7AL-IIIe-1','solves problems involving rational algebraic expressions','Algebra'),
('Mathematics','7',3,'M7AL-IIIf-1','relates a linear equation to a table of values and a graph','Algebra'),
('Mathematics','7',3,'M7AL-IIIf-2','finds the solution of linear equation or inequality in one variable','Algebra'),
('Mathematics','7',3,'M7AL-IIIg-1','solves linear equations or inequalities in one variable involving absolute value','Algebra'),
('Mathematics','7',3,'M7AL-IIIg-2','solves problems involving equations and inequalities in one variable','Algebra'),
('Mathematics','7',3,'M7AL-IIIh-1','represents a linear function using table of values, graph, and equation','Algebra'),
('Mathematics','7',3,'M7AL-IIIi-1','determines the slope of a line given two points','Algebra'),
('Mathematics','7',3,'M7AL-IIIi-2','writes the linear equation in two variables given real life situations','Algebra'),
('Mathematics','7',3,'M7AL-IIIj-1','graphs a linear equation given the following: slope-intercept, two points, x-intercept and y-intercept','Algebra');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','7',4,'M7GE-IVa-1','represents point, line and plane using concrete and pictorial models','Geometry'),
('Mathematics','7',4,'M7GE-IVb-1','illustrates subsets of a line','Geometry'),
('Mathematics','7',4,'M7GE-IVc-1','classifies the different kinds of angles','Geometry'),
('Mathematics','7',4,'M7GE-IVd-1','derives relationships of geometric figures using measurements','Geometry'),
('Mathematics','7',4,'M7GE-IVe-1','derives relationships among angles formed by parallel lines cut by a transversal','Geometry'),
('Mathematics','7',4,'M7GE-IVf-1','uses properties to find measures of angles formed by parallel lines cut by a transversal','Geometry'),
('Mathematics','7',4,'M7GE-IVg-1','illustrates polygons: convexity, angles and sides','Geometry'),
('Mathematics','7',4,'M7GE-IVh-1','derives the relationship of exterior and interior angles of any convex polygon','Geometry'),
('Mathematics','7',4,'M7SP-IVi-1','explains the importance of Statistics','Statistics and Probability'),
('Mathematics','7',4,'M7SP-IVi-2','poses problems that can be solved using Statistics','Statistics and Probability'),
('Mathematics','7',4,'M7SP-IVj-1','formulates simple statistical instruments','Statistics and Probability'),
('Mathematics','7',4,'M7SP-IVj-2','gathers statistical data','Statistics and Probability');
"#).await?;

        // ===== GRADE 8 MATHEMATICS =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','8',1,'M8AL-Ia-1','factors completely different types of polynomials','Algebra'),
('Mathematics','8',1,'M8AL-Ib-1','solves problems involving factors of polynomials','Algebra'),
('Mathematics','8',1,'M8AL-Ic-1','illustrates rational algebraic expressions','Algebra'),
('Mathematics','8',1,'M8AL-Ic-2','simplifies rational algebraic expressions','Algebra'),
('Mathematics','8',1,'M8AL-Id-1','performs operations on rational algebraic expressions','Algebra'),
('Mathematics','8',1,'M8AL-Ie-1','solves problems involving rational algebraic expressions','Algebra'),
('Mathematics','8',1,'M8AL-If-1','illustrates linear equations in two variables','Algebra'),
('Mathematics','8',1,'M8AL-Ig-1','illustrates and graphs a system of linear equations in two variables','Algebra'),
('Mathematics','8',1,'M8AL-Ih-1','solves a system of linear equations in two variables by substitution and elimination','Algebra'),
('Mathematics','8',1,'M8AL-Ih-2','solves problems involving systems of linear equations in two variables','Algebra');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','8',2,'M8AL-IIa-1','differentiates linear inequalities in two variables from linear equations in two variables','Algebra'),
('Mathematics','8',2,'M8AL-IIa-2','illustrates and graphs linear inequalities in two variables','Algebra'),
('Mathematics','8',2,'M8AL-IIa-3','solves problems involving linear inequalities in two variables','Algebra'),
('Mathematics','8',2,'M8AL-IIb-1','solves a system of linear inequalities in two variables','Algebra'),
('Mathematics','8',2,'M8AL-IIb-2','solves problems involving systems of linear inequalities in two variables','Algebra'),
('Mathematics','8',2,'M8AL-IIc-1','illustrates a relation and a function','Algebra'),
('Mathematics','8',2,'M8AL-IId-1','finds the domain and range of a function','Algebra'),
('Mathematics','8',2,'M8AL-IId-2','illustrates a linear function','Algebra'),
('Mathematics','8',2,'M8AL-IIe-1','graphs a linear function domain, range, slope and intercepts','Algebra'),
('Mathematics','8',2,'M8AL-IIf-1','solves problems involving linear functions','Algebra');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','8',3,'M8GE-IIIa-1','describes a mathematical system','Geometry'),
('Mathematics','8',3,'M8GE-IIIb-1','illustrates the need for an axiomatic structure of a mathematical system','Geometry'),
('Mathematics','8',3,'M8GE-IIIc-1','illustrates triangle congruence','Geometry'),
('Mathematics','8',3,'M8GE-IIId-1','illustrates the SAS, ASA, and SSS congruence postulates','Geometry'),
('Mathematics','8',3,'M8GE-IIIe-1','solves corresponding parts of congruent triangles','Geometry'),
('Mathematics','8',3,'M8GE-IIIf-1','proves two triangles are congruent','Geometry'),
('Mathematics','8',3,'M8GE-IIIg-1','proves statements on triangle congruence','Geometry'),
('Mathematics','8',3,'M8GE-IIIh-1','applies triangle congruence to construct perpendicular lines and angle bisectors','Geometry');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','8',4,'M8GE-IVa-1','illustrates theorems on triangle inequalities','Geometry'),
('Mathematics','8',4,'M8GE-IVb-1','applies theorems on triangle inequalities','Geometry'),
('Mathematics','8',4,'M8GE-IVc-1','proves inequalities in a triangle','Geometry'),
('Mathematics','8',4,'M8GE-IVd-1','proves properties of parallel lines cut by a transversal','Geometry'),
('Mathematics','8',4,'M8GE-IVe-1','determines the conditions under which lines and segments are parallel or perpendicular','Geometry'),
('Mathematics','8',4,'M8SP-IVf-1','describes and illustrates the probability of simple events','Statistics and Probability'),
('Mathematics','8',4,'M8SP-IVg-1','finds the probability of a simple event','Statistics and Probability'),
('Mathematics','8',4,'M8SP-IVh-1','illustrates an experimental probability and a theoretical probability','Statistics and Probability'),
('Mathematics','8',4,'M8SP-IVi-1','solves problems involving probabilities of simple events','Statistics and Probability');
"#).await?;

        // ===== GRADE 9 MATHEMATICS =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','9',1,'M9AL-Ia-1','illustrates quadratic equations','Algebra'),
('Mathematics','9',1,'M9AL-Ia-2','solves quadratic equations by extracting square roots, factoring, completing the square, and quadratic formula','Algebra'),
('Mathematics','9',1,'M9AL-Ib-1','characterizes the roots of a quadratic equation using the discriminant','Algebra'),
('Mathematics','9',1,'M9AL-Ic-1','describes the relationship between the coefficients and the roots of a quadratic equation','Algebra'),
('Mathematics','9',1,'M9AL-Id-1','solves equations transformable to quadratic equations','Algebra'),
('Mathematics','9',1,'M9AL-Ie-1','solves problems involving quadratic equations and rational algebraic equations','Algebra'),
('Mathematics','9',1,'M9AL-If-1','illustrates quadratic inequalities','Algebra'),
('Mathematics','9',1,'M9AL-If-2','solves quadratic inequalities','Algebra'),
('Mathematics','9',1,'M9AL-Ig-1','solves problems involving quadratic inequalities','Algebra'),
('Mathematics','9',1,'M9AL-Ih-1','models real-life situations using quadratic functions','Algebra'),
('Mathematics','9',1,'M9AL-Ih-2','represents a quadratic function using table of values, graph, and equation','Algebra'),
('Mathematics','9',1,'M9AL-Ii-1','analyzes the effects of changing the values of a, h, and k in the equation y=a(x-h)^2+k of a quadratic function','Algebra'),
('Mathematics','9',1,'M9AL-Ij-1','determines the equation of a quadratic function given a table of values, graph, and zeros','Algebra');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','9',2,'M9AL-IIa-1','illustrates situations that involve the following variations: direct, inverse, joint, and combined','Algebra'),
('Mathematics','9',2,'M9AL-IIb-1','translates into variation statement a relationship between two quantities given a table of values, graph, and mathematical equation','Algebra'),
('Mathematics','9',2,'M9AL-IIc-1','solves problems involving variation','Algebra'),
('Mathematics','9',2,'M9AL-IId-1','applies the laws involving positive integral exponents to zero and negative integral exponents','Algebra'),
('Mathematics','9',2,'M9AL-IIe-1','illustrates expressions with rational exponents','Algebra'),
('Mathematics','9',2,'M9AL-IIf-1','simplifies expressions with rational exponents','Algebra'),
('Mathematics','9',2,'M9AL-IIg-1','writes expressions with rational exponents as radicals and vice versa','Algebra'),
('Mathematics','9',2,'M9AL-IIh-1','performs operations on radicals','Algebra'),
('Mathematics','9',2,'M9AL-IIi-1','solves equations involving radical expressions','Algebra'),
('Mathematics','9',2,'M9AL-IIj-1','solves problems involving radicals','Algebra');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','9',3,'M9GE-IIIa-1','determines the conditions for similarity of triangles','Geometry'),
('Mathematics','9',3,'M9GE-IIIb-1','applies the properties of similar triangles to prove congruence','Geometry'),
('Mathematics','9',3,'M9GE-IIIc-1','proves the conditions for similarity of triangles: SAS, AA, SSS similarity theorems','Geometry'),
('Mathematics','9',3,'M9GE-IIId-1','applies the properties of right triangles','Geometry'),
('Mathematics','9',3,'M9GE-IIId-2','illustrates the six trigonometric ratios','Geometry'),
('Mathematics','9',3,'M9GE-IIIe-1','finds the trigonometric ratios of special angles','Geometry'),
('Mathematics','9',3,'M9GE-IIIf-1','illustrates angles of elevation and angles of depression','Geometry'),
('Mathematics','9',3,'M9GE-IIIg-1','uses trigonometric ratios to solve real-life problems involving right triangles','Geometry'),
('Mathematics','9',3,'M9GE-IIIh-1','illustrates laws of sines and cosines','Geometry'),
('Mathematics','9',3,'M9GE-IIIi-1','solves problems involving oblique triangles','Geometry');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','9',4,'M9GE-IVa-1','identifies and describes the different kinds of quadrilaterals','Geometry'),
('Mathematics','9',4,'M9GE-IVb-1','determines the conditions that guarantee a quadrilateral is a parallelogram','Geometry'),
('Mathematics','9',4,'M9GE-IVc-1','uses properties to find measures of angles, sides, and other quantities involving parallelograms','Geometry'),
('Mathematics','9',4,'M9GE-IVd-1','proves theorems on the different kinds of parallelograms','Geometry'),
('Mathematics','9',4,'M9GE-IVe-1','proves the Midpoint Theorem','Geometry'),
('Mathematics','9',4,'M9GE-IVf-1','solves problems involving parallelograms, trapezoids, and kites','Geometry'),
('Mathematics','9',4,'M9GE-IVg-1','describes a circle and its related terms','Geometry'),
('Mathematics','9',4,'M9GE-IVh-1','proves theorems related to chords, arcs, central angles, and inscribed angles','Geometry'),
('Mathematics','9',4,'M9GE-IVi-1','solves problems involving circles','Geometry');
"#).await?;

        // ===== GRADE 10 MATHEMATICS =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','10',1,'M10AL-Ia-1','generates patterns','Algebra'),
('Mathematics','10',1,'M10AL-Ib-1','illustrates an arithmetic sequence','Algebra'),
('Mathematics','10',1,'M10AL-Ib-2','determines arithmetic means, nth term of an arithmetic sequence, and sum of the terms of a given arithmetic sequence','Algebra'),
('Mathematics','10',1,'M10AL-Ic-1','illustrates a geometric sequence','Algebra'),
('Mathematics','10',1,'M10AL-Ic-2','determines geometric means, nth term of a geometric sequence, and sum of the terms of a given finite or infinite geometric sequence','Algebra'),
('Mathematics','10',1,'M10AL-Id-1','illustrates other types of sequences: harmonic, Fibonacci','Algebra'),
('Mathematics','10',1,'M10AL-Ie-1','uses the Binomial Theorem to expand a polynomial expression','Algebra'),
('Mathematics','10',1,'M10AL-If-1','finds the specified term of a binomial expansion','Algebra'),
('Mathematics','10',1,'M10AL-Ig-1','solves problems involving sequences','Algebra');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','10',2,'M10AL-IIa-1','factors polynomials','Algebra'),
('Mathematics','10',2,'M10AL-IIb-1','illustrates polynomial functions','Algebra'),
('Mathematics','10',2,'M10AL-IIb-2','graphs polynomial functions','Algebra'),
('Mathematics','10',2,'M10AL-IIc-1','solves problems involving polynomial functions','Algebra'),
('Mathematics','10',2,'M10AL-IId-1','derives inductively the relations among chords, arcs, central angles, and inscribed angles','Geometry'),
('Mathematics','10',2,'M10GE-IIe-1','proves theorems related to chords, arcs, central angles, and inscribed angles','Geometry'),
('Mathematics','10',2,'M10GE-IIf-1','illustrates secants, tangents, segments, and sectors of a circle','Geometry'),
('Mathematics','10',2,'M10GE-IIg-1','proves theorems on secants, tangents, and segments','Geometry'),
('Mathematics','10',2,'M10GE-IIh-1','solves problems on circles','Geometry');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','10',3,'M10GE-IIIa-1','derives the distance formula','Geometry'),
('Mathematics','10',3,'M10GE-IIIb-1','applies the distance formula to prove some geometric properties','Geometry'),
('Mathematics','10',3,'M10GE-IIIc-1','illustrates the center-radius form of the equation of a circle','Geometry'),
('Mathematics','10',3,'M10GE-IIId-1','determines the center and radius of a circle given its equation','Geometry'),
('Mathematics','10',3,'M10GE-IIIe-1','graphs a circle and other geometric figures on the coordinate plane','Geometry'),
('Mathematics','10',3,'M10GE-IIIf-1','solves problems involving geometric figures on the coordinate plane','Geometry');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Mathematics','10',4,'M10SP-IVa-1','illustrates the permutation of objects','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVb-1','derives the formula for finding the number of permutations of n objects taken r at a time','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVb-2','solves problems involving permutations','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVc-1','illustrates the combination of objects','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVd-1','differentiates permutation from combination of n objects taken r at a time','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVd-2','solves problems involving combinations','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVe-1','illustrates events, and union and intersection of events','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVf-1','illustrates the probability of a union of two events','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVg-1','finds the probability of (AUB)','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVh-1','illustrates mutually exclusive events','Statistics and Probability'),
('Mathematics','10',4,'M10SP-IVi-1','solves problems involving probability','Statistics and Probability');
"#).await?;

        // ===== GRADE 7 SCIENCE =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','7',1,'S7MT-Ia-1','describe the components of a scientific investigation','Scientific Inquiry'),
('Science','7',1,'S7MT-Ib-2','distinguish between accurate and precise measurements','Scientific Inquiry'),
('Science','7',1,'S7MT-Ic-3','use appropriate instruments to measure length, volume, mass, temperature, and time','Scientific Inquiry'),
('Science','7',1,'S7MT-Id-e-1','appreciate the contributions of scientists in the understanding of matter','Matter'),
('Science','7',1,'S7MT-Ie-f-1','describe the appearance, odor, and other properties of common materials','Matter'),
('Science','7',1,'S7MT-Ig-1','identify the physical properties of matter','Matter'),
('Science','7',1,'S7MT-Ih-1','describe that matter undergoes changes through physical or chemical processes','Matter'),
('Science','7',1,'S7MT-IIa-1','classify substances as elements or compounds','Matter'),
('Science','7',1,'S7MT-IIb-1','recognize that elements in a compound are in fixed ratios','Matter'),
('Science','7',1,'S7MT-IIb-2','distinguish between physical change and chemical change','Matter');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','7',2,'S7FE-IIc-1','describe the motion of objects in terms of distance or displacement, speed or velocity, and acceleration','Force and Motion'),
('Science','7',2,'S7FE-IId-1','differentiate quantities in terms of magnitude and direction','Force and Motion'),
('Science','7',2,'S7FE-IIe-1','infer that waves carry energy','Force and Motion'),
('Science','7',2,'S7FE-IIf-1','describe the characteristics of sound using the concepts of wavelength, velocity, and amplitude','Force and Motion'),
('Science','7',2,'S7FE-IIg-1','relate the characteristics of light such as color and intensity to frequency and wavelength','Force and Motion'),
('Science','7',2,'S7FE-IIh-1','explain the effects of the different factors on the propagation of sound through solid, liquid, and gas','Force and Motion'),
('Science','7',2,'S7FE-IIi-1','demonstrate the existence of the colors of visible light using a prism or diffraction grating','Force and Motion');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','7',3,'S7LT-IIIa-1','identify beneficial and harmful microorganisms','Living Things and Their Environment'),
('Science','7',3,'S7LT-IIIb-1','describe the different parts of the microscope and their functions','Living Things and Their Environment'),
('Science','7',3,'S7LT-IIIc-1','describe the different levels of biological organization from cell to biosphere','Living Things and Their Environment'),
('Science','7',3,'S7LT-IIId-1','compare and contrast plant and animal cells','Living Things and Their Environment'),
('Science','7',3,'S7LT-IIIe-1','identify the parts of the cell and their functions','Living Things and Their Environment'),
('Science','7',3,'S7LT-IIIf-1','describe the different types of cell transport','Living Things and Their Environment');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','7',4,'S7ES-IVa-1','describe the internal structure of the Earth','Earth and Space'),
('Science','7',4,'S7ES-IVb-1','explain the different types of volcanoes','Earth and Space'),
('Science','7',4,'S7ES-IVc-1','differentiate the epicenter of an earthquake from its focus','Earth and Space'),
('Science','7',4,'S7ES-IVd-1','describe how rocks are formed','Earth and Space'),
('Science','7',4,'S7ES-IVe-1','explain the different types of soil','Earth and Space'),
('Science','7',4,'S7ES-IVf-1','describe the atmosphere of the Earth','Earth and Space'),
('Science','7',4,'S7ES-IVg-1','explain how the weather and climate affect water cycle','Earth and Space');
"#).await?;

        // ===== GRADE 8 SCIENCE =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','8',1,'S8MT-Ia-1','describe the arrangement of elements in the periodic table','Matter'),
('Science','8',1,'S8MT-Ib-1','trace the development of the periodic table','Matter'),
('Science','8',1,'S8MT-Ic-1','use the periodic table to find information about an element','Matter'),
('Science','8',1,'S8MT-Id-1','describe the formation of ionic and covalent bonds','Matter'),
('Science','8',1,'S8MT-Ie-1','compare the properties of ionic and covalent compounds','Matter'),
('Science','8',1,'S8MT-If-1','explain how acids and bases are defined','Matter'),
('Science','8',1,'S8MT-Ig-1','describe the properties of acids and bases','Matter'),
('Science','8',1,'S8MT-Ih-1','explain how neutralization reactions occur','Matter');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','8',2,'S8FE-IIa-1','infer that the total momentum before and after collision is equal','Force and Motion'),
('Science','8',2,'S8FE-IIb-1','demonstrate the relationship of impulse and momentum','Force and Motion'),
('Science','8',2,'S8FE-IIc-1','explain the relationship between work and energy','Force and Motion'),
('Science','8',2,'S8FE-IId-1','describe the different forms of energy','Force and Motion'),
('Science','8',2,'S8FE-IIe-1','explain the conservation of energy in various processes','Force and Motion'),
('Science','8',2,'S8FE-IIf-1','infer how motion in a curved path is caused by a centripetal force','Force and Motion'),
('Science','8',2,'S8FE-IIg-1','relate the motion of objects in uniform circular motion','Force and Motion');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','8',3,'S8LT-IIIa-1','explain the major stages of the cell cycle','Living Things and Their Environment'),
('Science','8',3,'S8LT-IIIb-1','describe the process of mitosis and meiosis','Living Things and Their Environment'),
('Science','8',3,'S8LT-IIIc-1','explain the different types of asexual reproduction','Living Things and Their Environment'),
('Science','8',3,'S8LT-IIId-1','describe the process of sexual reproduction','Living Things and Their Environment'),
('Science','8',3,'S8LT-IIIe-1','explain Mendel''s Laws of Inheritance','Living Things and Their Environment'),
('Science','8',3,'S8LT-IIIf-1','predict the genotypes and phenotypes of offspring using Punnett squares','Living Things and Their Environment');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','8',4,'S8ES-IVa-1','describe the atmosphere of the Earth in terms of its composition and structure','Earth and Space'),
('Science','8',4,'S8ES-IVb-1','explain how heat from the sun affects the weather','Earth and Space'),
('Science','8',4,'S8ES-IVc-1','describe how typhoons develop and their effects','Earth and Space'),
('Science','8',4,'S8ES-IVd-1','explain the effect of different human activities on the atmosphere','Earth and Space'),
('Science','8',4,'S8ES-IVe-1','describe the causes and effects of climate change','Earth and Space');
"#).await?;

        // ===== GRADE 9 SCIENCE =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','9',1,'S9MT-Ia-1','investigate properties of unsaturated and saturated solutions','Matter'),
('Science','9',1,'S9MT-Ib-1','prepare saturated, unsaturated, and supersaturated solutions','Matter'),
('Science','9',1,'S9MT-Ic-1','explain what happens to solutions when they are heated or cooled','Matter'),
('Science','9',1,'S9MT-Id-1','express concentration of solution quantitatively by computing for percent by mass','Matter'),
('Science','9',1,'S9MT-Ie-1','investigate factors that affect the rate of chemical reactions','Matter'),
('Science','9',1,'S9MT-If-1','explain the energy changes involved in chemical reactions','Matter'),
('Science','9',1,'S9MT-Ig-1','describe oxidation-reduction reactions','Matter'),
('Science','9',1,'S9MT-Ih-1','identify oxidizing and reducing agents','Matter');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','9',2,'S9FE-IIa-1','describe the horizontal and vertical motions of a projectile','Force and Motion'),
('Science','9',2,'S9FE-IIb-1','investigate the relationship between the angle of release and the height and range of a projectile','Force and Motion'),
('Science','9',2,'S9FE-IIc-1','relate the laws of conservation of momentum and energy to collisions','Force and Motion'),
('Science','9',2,'S9FE-IId-1','explain the concept of work as used in science','Force and Motion'),
('Science','9',2,'S9FE-IIe-1','compute for the power of machines','Force and Motion'),
('Science','9',2,'S9FE-IIf-1','explain how heat affects the behavior of matter','Force and Motion'),
('Science','9',2,'S9FE-IIg-1','infer the relationship between current and voltage','Force and Motion'),
('Science','9',2,'S9FE-IIh-1','explain the effect of current and voltage in a circuit','Force and Motion');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','9',3,'S9LT-IIIa-1','explain the process of evolution by natural selection','Living Things and Their Environment'),
('Science','9',3,'S9LT-IIIb-1','explain how fossil records support the theory of evolution','Living Things and Their Environment'),
('Science','9',3,'S9LT-IIIc-1','describe the mechanisms of evolution','Living Things and Their Environment'),
('Science','9',3,'S9LT-IIId-1','explain how biodiversity is maintained','Living Things and Their Environment'),
('Science','9',3,'S9LT-IIIe-1','describe the different types of ecological relationships','Living Things and Their Environment'),
('Science','9',3,'S9LT-IIIf-1','analyze the flow of matter and energy in ecosystems','Living Things and Their Environment');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','9',4,'S9ES-IVa-1','describe the different layers of the Earth','Earth and Space'),
('Science','9',4,'S9ES-IVb-1','explain the theory of plate tectonics','Earth and Space'),
('Science','9',4,'S9ES-IVc-1','describe the different types of plate boundaries','Earth and Space'),
('Science','9',4,'S9ES-IVd-1','explain how volcanoes and earthquakes are distributed','Earth and Space'),
('Science','9',4,'S9ES-IVe-1','relate the occurrence of earthquakes and volcanic eruptions to geologic hazards','Earth and Space');
"#).await?;

        // ===== GRADE 10 SCIENCE =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','10',1,'S10MT-Ia-1','describe the structure of the atom','Matter'),
('Science','10',1,'S10MT-Ib-1','explain how atoms form chemical bonds','Matter'),
('Science','10',1,'S10MT-Ic-1','predict the type of bond formed based on electronegativity values','Matter'),
('Science','10',1,'S10MT-Id-1','explain why properties of compounds depend on the type of bond formed','Matter'),
('Science','10',1,'S10MT-Ie-1','explain how changes in temperature affect the behavior of matter','Matter'),
('Science','10',1,'S10MT-If-1','describe the four types of biomolecules','Matter'),
('Science','10',1,'S10MT-Ig-1','explain how nuclear reactions produce energy','Matter');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','10',2,'S10FE-IIa-1','describe the different types of waves','Force and Motion'),
('Science','10',2,'S10FE-IIb-1','explain the Doppler effect','Force and Motion'),
('Science','10',2,'S10FE-IIc-1','describe the behavior of light','Force and Motion'),
('Science','10',2,'S10FE-IId-1','explain the relationship between electricity and magnetism','Force and Motion'),
('Science','10',2,'S10FE-IIe-1','describe the different applications of electromagnetic radiation','Force and Motion'),
('Science','10',2,'S10FE-IIf-1','explain how renewable and non-renewable energy sources differ','Force and Motion');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','10',3,'S10LT-IIIa-1','explain the different mechanisms that produce genetic variations','Living Things and Their Environment'),
('Science','10',3,'S10LT-IIIb-1','explain the concept of natural selection and how it leads to speciation','Living Things and Their Environment'),
('Science','10',3,'S10LT-IIIc-1','describe the different types of adaptations','Living Things and Their Environment'),
('Science','10',3,'S10LT-IIId-1','explain how the immune system protects the body','Living Things and Their Environment'),
('Science','10',3,'S10LT-IIIe-1','describe the different types of diseases','Living Things and Their Environment');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Science','10',4,'S10ES-IVa-1','explain the formation of the solar system','Earth and Space'),
('Science','10',4,'S10ES-IVb-1','describe the characteristics of stars','Earth and Space'),
('Science','10',4,'S10ES-IVc-1','explain the life cycle of a star','Earth and Space'),
('Science','10',4,'S10ES-IVd-1','describe the different types of galaxies','Earth and Space'),
('Science','10',4,'S10ES-IVe-1','explain the Big Bang Theory','Earth and Space'),
('Science','10',4,'S10ES-IVf-1','describe the impact of human activity on the environment','Earth and Space');
"#).await?;

        // ===== GRADE 7 ENGLISH =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','7',1,'EN7RC-Ia-1','use the appropriate reading style for different texts','Reading Comprehension'),
('English','7',1,'EN7RC-Ia-2','predict the content of a text based on clues provided','Reading Comprehension'),
('English','7',1,'EN7RC-Ib-1','note details and organize information','Reading Comprehension'),
('English','7',1,'EN7RC-Ic-1','make a timeline of events','Reading Comprehension'),
('English','7',1,'EN7VC-Ia-1','use clues from context to determine the meaning of unfamiliar words','Vocabulary and Concept Development'),
('English','7',1,'EN7WC-Ia-1','compose effective paragraphs','Writing and Composition'),
('English','7',1,'EN7WC-Ib-1','write a coherent and unified paragraph','Writing and Composition'),
('English','7',1,'EN7OL-Ia-1','use expressions that affirm, negate, and qualify statements','Oral Language and Fluency');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','7',2,'EN7RC-IIa-1','determine the central theme of the text and how it is conveyed','Reading Comprehension'),
('English','7',2,'EN7RC-IIb-1','analyze the elements of a literary text','Reading Comprehension'),
('English','7',2,'EN7VC-IIa-1','recognize collocations in texts','Vocabulary and Concept Development'),
('English','7',2,'EN7WC-IIa-1','write a literary analysis essay','Writing and Composition'),
('English','7',2,'EN7OL-IIa-1','use correct word stress in oral reading','Oral Language and Fluency'),
('English','7',2,'EN7LT-IIa-1','appreciate the diversity of oral literature across different cultures','Literature'),
('English','7',2,'EN7G-IIa-1','use the correct form of the verb in sentences','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','7',3,'EN7RC-IIIa-1','identify features of informational texts','Reading Comprehension'),
('English','7',3,'EN7RC-IIIb-1','distinguish between relevant and irrelevant information','Reading Comprehension'),
('English','7',3,'EN7WC-IIIa-1','write a summary and reaction paper','Writing and Composition'),
('English','7',3,'EN7G-IIIa-1','use phrases and clauses as sentence modifiers','Grammar Awareness'),
('English','7',3,'EN7G-IIIb-1','use different sentence types: simple, compound, complex','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','7',4,'EN7RC-IVa-1','evaluate persuasive texts based on logical reasoning','Reading Comprehension'),
('English','7',4,'EN7WC-IVa-1','write a persuasive essay','Writing and Composition'),
('English','7',4,'EN7OL-IVa-1','deliver a persuasive speech','Oral Language and Fluency'),
('English','7',4,'EN7G-IVa-1','use connectors expressing condition, purpose, and concession','Grammar Awareness');
"#).await?;

        // ===== GRADE 8 ENGLISH =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','8',1,'EN8RC-Ia-1','identify the main idea and supporting details of a text','Reading Comprehension'),
('English','8',1,'EN8RC-Ib-1','use reading strategies such as skimming and scanning','Reading Comprehension'),
('English','8',1,'EN8VC-Ia-1','determine the meaning of idioms and figurative language','Vocabulary and Concept Development'),
('English','8',1,'EN8WC-Ia-1','write a descriptive essay','Writing and Composition'),
('English','8',1,'EN8G-Ia-1','use active and passive voice correctly','Grammar Awareness'),
('English','8',1,'EN8OL-Ia-1','use the right intonation in asking and giving information','Oral Language and Fluency');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','8',2,'EN8RC-IIa-1','analyze literary texts for tone, mood, and style','Reading Comprehension'),
('English','8',2,'EN8LT-IIa-1','appreciate literature from Asia and other continents','Literature'),
('English','8',2,'EN8WC-IIa-1','write a character analysis essay','Writing and Composition'),
('English','8',2,'EN8G-IIa-1','use participial phrases, gerund phrases, and infinitive phrases','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','8',3,'EN8RC-IIIa-1','note the important points made by each speaker in a discussion','Reading Comprehension'),
('English','8',3,'EN8WC-IIIa-1','write a research-based expository essay','Writing and Composition'),
('English','8',3,'EN8G-IIIa-1','use modal auxiliaries in giving advice and expressing possibilities','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','8',4,'EN8RC-IVa-1','analyze the elements and techniques of argumentative texts','Reading Comprehension'),
('English','8',4,'EN8WC-IVa-1','write an argumentative essay','Writing and Composition'),
('English','8',4,'EN8OL-IVa-1','deliver an informative speech','Oral Language and Fluency'),
('English','8',4,'EN8G-IVa-1','use conditional sentences (if-clauses)','Grammar Awareness');
"#).await?;

        // ===== GRADE 9 ENGLISH =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','9',1,'EN9RC-Ia-1','identify the main features of text types: narrative, expository, and persuasive','Reading Comprehension'),
('English','9',1,'EN9VC-Ia-1','use structural analysis to determine the meaning of unfamiliar words','Vocabulary and Concept Development'),
('English','9',1,'EN9WC-Ia-1','write a short story or narrative essay','Writing and Composition'),
('English','9',1,'EN9G-Ia-1','use reported speech correctly','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','9',2,'EN9RC-IIa-1','appreciate world literature that speaks of universal themes','Reading Comprehension'),
('English','9',2,'EN9LT-IIa-1','analyze themes and techniques in world literary texts','Literature'),
('English','9',2,'EN9WC-IIa-1','write a poem or short drama','Writing and Composition'),
('English','9',2,'EN9G-IIa-1','use complex sentence patterns with coordinating and subordinating conjunctions','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','9',3,'EN9RC-IIIa-1','draw conclusions and make inferences from informational texts','Reading Comprehension'),
('English','9',3,'EN9WC-IIIa-1','write a feature article','Writing and Composition'),
('English','9',3,'EN9G-IIIa-1','use the past perfect and past perfect progressive tenses','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','9',4,'EN9RC-IVa-1','evaluate the effectiveness of a speech based on content and delivery','Reading Comprehension'),
('English','9',4,'EN9OL-IVa-1','deliver a speech with proper use of pitch, stress, and intonation','Oral Language and Fluency'),
('English','9',4,'EN9G-IVa-1','use correct noun-pronoun agreement','Grammar Awareness');
"#).await?;

        // ===== GRADE 10 ENGLISH =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','10',1,'EN10RC-Ia-1','use context clues to determine the meaning of unfamiliar words','Reading Comprehension'),
('English','10',1,'EN10RC-Ib-1','draw inferences from texts','Reading Comprehension'),
('English','10',1,'EN10WC-Ia-1','compose a research report','Writing and Composition'),
('English','10',1,'EN10G-Ia-1','use a variety of sentence structures','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','10',2,'EN10RC-IIa-1','analyze and interpret literary texts from different cultures','Reading Comprehension'),
('English','10',2,'EN10LT-IIa-1','appreciate Philippine and World literature','Literature'),
('English','10',2,'EN10WC-IIa-1','write a critique of a literary or media text','Writing and Composition'),
('English','10',2,'EN10G-IIa-1','use complex sentence structures effectively','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','10',3,'EN10RC-IIIa-1','detect propaganda techniques in media texts','Reading Comprehension'),
('English','10',3,'EN10WC-IIIa-1','write a persuasive letter or editorial','Writing and Composition'),
('English','10',3,'EN10G-IIIa-1','use transitional devices in writing','Grammar Awareness');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('English','10',4,'EN10RC-IVa-1','synthesize information from various texts','Reading Comprehension'),
('English','10',4,'EN10OL-IVa-1','deliver a well-organized impromptu speech','Oral Language and Fluency'),
('English','10',4,'EN10G-IVa-1','maintain consistent verb tense in writing','Grammar Awareness');
"#).await?;

        // ===== GRADE 7 ARALING PANLIPUNAN =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','7',1,'AP7PAK-Ia-1','natutukoy ang lokasyon ng Asya sa mapa ng mundo','Pagsasabansa at Pagkamamamayan'),
('Araling Panlipunan','7',1,'AP7PAK-Ib-1','nasusuri ang katangiang pisikal ng Asya','Pagsasabansa at Pagkamamamayan'),
('Araling Panlipunan','7',1,'AP7PAK-Ic-1','naipaliliwanag ang impluwensya ng pisikal na kalikasan sa pamumuhay ng mga tao sa Asya','Pagsasabansa at Pagkamamamayan'),
('Araling Panlipunan','7',1,'AP7PAK-Id-1','natutukoy ang mga sinaunang kabihasnan ng Asya','Pagsasabansa at Pagkamamamayan'),
('Araling Panlipunan','7',1,'AP7PAK-Ie-1','nasusuri ang ugnayan ng kalikasan at lipunan sa pagbuo ng kabihasnan sa Asya','Pagsasabansa at Pagkamamamayan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','7',2,'AP7KAS-IIa-1','natutukoy ang mga pangunahing relihiyon sa Asya','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','7',2,'AP7KAS-IIb-1','nasusuri ang impluwensya ng relihiyon sa kultura ng mga bansa sa Asya','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','7',2,'AP7KAS-IIc-1','naipaliliwanag ang paglaganap ng Islam sa Asya','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','7',2,'AP7KAS-IId-1','natutukoy ang mga salik ng pananakop ng mga Europeo sa Asya','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','7',3,'AP7KAS-IIIa-1','nasusuri ang kilusang nasyonalismo sa Asya','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','7',3,'AP7KAS-IIIb-1','natutukoy ang mga dahilan ng Ikalawang Digmaang Pandaigdig sa Asya','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','7',3,'AP7KAS-IIIc-1','naipaliliwanag ang mga epekto ng Ikalawang Digmaang Pandaigdig sa Asya','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','7',3,'AP7KAS-IIId-1','nasusuri ang mga hamon ng dekolonisasyon sa Asya','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','7',4,'AP7EKEK-IVa-1','natutukoy ang mga salik ng pag-unlad ng ekonomiya ng mga bansa sa Asya','Ekonomiya at Kabuhayan'),
('Araling Panlipunan','7',4,'AP7EKEK-IVb-1','nasusuri ang mga isyu at hamon sa kasalukuyang Asya','Ekonomiya at Kabuhayan'),
('Araling Panlipunan','7',4,'AP7EKEK-IVc-1','naipaliliwanag ang kahalagahan ng ASEAN sa Asya','Ekonomiya at Kabuhayan');
"#).await?;

        // ===== GRADE 8 ARALING PANLIPUNAN =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','8',1,'AP8PAK-Ia-1','natutukoy ang katangiang heograpiko ng Africa at Middle East','Pagsasabansa at Pagkamamamayan'),
('Araling Panlipunan','8',1,'AP8PAK-Ib-1','nasusuri ang impluwensya ng kalikasan sa pamumuhay sa Africa at Middle East','Pagsasabansa at Pagkamamamayan'),
('Araling Panlipunan','8',1,'AP8KAS-Ic-1','nasusuri ang mga kabihasnang naganap sa Africa at Middle East','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','8',1,'AP8KAS-Id-1','natutukoy ang mga dahilan at epekto ng pananakop sa Africa','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','8',2,'AP8KAS-IIa-1','nasusuri ang mga kabihasnang naganap sa Europe','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','8',2,'AP8KAS-IIb-1','naipaliliwanag ang impluwensya ng Renaissance at Repormasyon','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','8',2,'AP8KAS-IIc-1','nasusuri ang epekto ng Rebolusyong Industriyal','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','8',2,'AP8KAS-IId-1','natutukoy ang mga sanhi at epekto ng Unang Digmaang Pandaigdig','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','8',3,'AP8KAS-IIIa-1','nasusuri ang mga sanhi at epekto ng Ikalawang Digmaang Pandaigdig','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','8',3,'AP8KAS-IIIb-1','naipaliliwanag ang pagbuo ng United Nations at iba pang internasyonal na organisasyon','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','8',3,'AP8KAS-IIIc-1','nasusuri ang Cold War at ang mga epekto nito sa mundo','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','8',4,'AP8EKEK-IVa-1','natutukoy ang mga pangunahing isyu at hamon sa pandaigdigang lipunan','Ekonomiya at Kabuhayan'),
('Araling Panlipunan','8',4,'AP8EKEK-IVb-1','nasusuri ang epekto ng globalisasyon sa kultura at kabuhayan','Ekonomiya at Kabuhayan'),
('Araling Panlipunan','8',4,'AP8EKEK-IVc-1','naipaliliwanag ang kahalagahan ng internasyonal na kooperasyon','Ekonomiya at Kabuhayan');
"#).await?;

        // ===== GRADE 9 ARALING PANLIPUNAN =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','9',1,'AP9PAK-Ia-1','natutukoy ang lokasyon ng Pilipinas sa mapa ng Asya at mundo','Pagsasabansa at Pagkamamamayan'),
('Araling Panlipunan','9',1,'AP9KAS-Ib-1','nasusuri ang mga kabihasnang nagkaroon ng impluwensya sa Pilipinas','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','9',1,'AP9KAS-Ic-1','naipaliliwanag ang mga dahilan ng pananakop ng Espanya sa Pilipinas','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','9',1,'AP9KAS-Id-1','nasusuri ang mga epekto ng kolonisasyong Espanyol','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','9',2,'AP9KAS-IIa-1','nasusuri ang kilusang nagtataguyod ng kalayaan ng Pilipinas','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','9',2,'AP9KAS-IIb-1','naipaliliwanag ang Rebolusyong Pilipino','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','9',2,'AP9KAS-IIc-1','nasusuri ang mga pangyayari sa panahon ng Amerikano','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','9',3,'AP9KAS-IIIa-1','nasusuri ang pagtatag ng Komonwelt at mga paghahanda para sa kalayaan','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','9',3,'AP9KAS-IIIb-1','naipaliliwanag ang Ikalawang Digmaang Pandaigdig sa Pilipinas','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','9',3,'AP9KAS-IIIc-1','nasusuri ang Ikatlong Republika at ang hamon ng pag-unlad','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','9',4,'AP9EKEK-IVa-1','nasusuri ang mga salik ng pag-unlad ng ekonomiya ng Pilipinas','Ekonomiya at Kabuhayan'),
('Araling Panlipunan','9',4,'AP9EKEK-IVb-1','naipaliliwanag ang kahalagahan ng pagkilos ng mamamayan sa lipunan','Ekonomiya at Kabuhayan');
"#).await?;

        // ===== GRADE 10 ARALING PANLIPUNAN =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','10',1,'AP10KAS-Ia-1','nasusuri ang mga pagsisikap para sa pagbabago at repormang panlipunan','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','10',1,'AP10KAS-Ib-1','naipaliliwanag ang kahalagahan ng Konstitusyon ng Pilipinas','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','10',2,'AP10KAS-IIa-1','nasusuri ang mga isyung panlipunan at pang-ekonomiya sa Pilipinas','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','10',2,'AP10KAS-IIb-1','naipaliliwanag ang ugnayan ng Pilipinas at iba pang bansa','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','10',3,'AP10KAS-IIIa-1','nasusuri ang mga hamon ng globalisasyon sa Pilipinas','Kasaysayan at Kabihasnan'),
('Araling Panlipunan','10',3,'AP10KAS-IIIb-1','naipaliliwanag ang kahalagahan ng pagpapahalaga ng pagkakaisa','Kasaysayan at Kabihasnan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Araling Panlipunan','10',4,'AP10EKEK-IVa-1','nasusuri ang mga pangunahing isyu at hamon sa Pilipinas','Ekonomiya at Kabuhayan'),
('Araling Panlipunan','10',4,'AP10EKEK-IVb-1','naipaliliwanag ang kahalagahan ng mamamayan sa pagpapaunlad ng lipunan','Ekonomiya at Kabuhayan');
"#).await?;

        // ===== GRADE 7-10 EDUKASYON SA PAGPAPAKATAO (EsP) =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Edukasyon sa Pagpapakatao','7',1,'EsP-PD7PDP-Ia-1','naipahahayag ang mga aspekto ng sariling kakayahan','Pansariling Pag-unlad'),
('Edukasyon sa Pagpapakatao','7',1,'EsP-PD7PDP-Ib-1','naiuugnay ang personal na misyon at bisyon sa pamilya at komunidad','Pansariling Pag-unlad'),
('Edukasyon sa Pagpapakatao','7',2,'EsP-PD7PDP-IIa-1','nasusuri ang epekto ng peer pressure sa pagpapasya','Pansariling Pag-unlad'),
('Edukasyon sa Pagpapakatao','7',3,'EsP-PD7PDP-IIIa-1','natutukoy ang mga paraan ng pagpapataas ng sariling respeto','Pansariling Pag-unlad'),
('Edukasyon sa Pagpapakatao','7',4,'EsP-PD7PDP-IVa-1','naipamamalas ang mga katangiang nagpapakita ng isang mabuting Pilipino','Pansariling Pag-unlad');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Edukasyon sa Pagpapakatao','8',1,'EsP-PD8PDP-Ia-1','nasusuri ang sariling kalagayan at nagpapakita ng pananagutang personal','Pansariling Pag-unlad'),
('Edukasyon sa Pagpapakatao','8',2,'EsP-PD8PDP-IIa-1','naipamamalas ang pagpapahalaga sa kahalagahan ng pamilya','Pamilya'),
('Edukasyon sa Pagpapakatao','8',3,'EsP-PD8PDP-IIIa-1','nasusuri ang mga isyu at hamon sa pagbuo ng malusog na relasyon','Pansariling Pag-unlad'),
('Edukasyon sa Pagpapakatao','8',4,'EsP-PD8PDP-IVa-1','naipahahayag ang pagmamahal at pasasalamat sa Diyos','Pananampalataya');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Edukasyon sa Pagpapakatao','9',1,'EsP-PD9PDP-Ia-1','nasusuri ang mga salik na nakaaapekto sa pagpapaunlad ng sarili','Pansariling Pag-unlad'),
('Edukasyon sa Pagpapakatao','9',2,'EsP-PD9PDP-IIa-1','naipahahayag ang pagmamahal sa bansa sa pamamagitan ng makabuluhang pagkilos','Pagkamamamayan'),
('Edukasyon sa Pagpapakatao','9',3,'EsP-PD9PDP-IIIa-1','natutukoy ang mga paraan ng pagtulong sa kapwa','Panlipunang Responsibilidad'),
('Edukasyon sa Pagpapakatao','9',4,'EsP-PD9PDP-IVa-1','naipaliliwanag ang kahalagahan ng paggalang sa karapatang pantao','Pagkamamamayan');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Edukasyon sa Pagpapakatao','10',1,'EsP-PD10PDP-Ia-1','nasusuri ang mga pagpapahalaga at prinsipyong etikal','Etika'),
('Edukasyon sa Pagpapakatao','10',2,'EsP-PD10PDP-IIa-1','naipamamalas ang responsableng pagkilos bilang miyembro ng lipunan','Panlipunang Responsibilidad'),
('Edukasyon sa Pagpapakatao','10',3,'EsP-PD10PDP-IIIa-1','nasusuri ang kahalagahan ng pagkakaisa at pakikiisa sa pagbabago','Pagkamamamayan'),
('Edukasyon sa Pagpapakatao','10',4,'EsP-PD10PDP-IVa-1','naipahahayag ang pagmamahal at malasakit sa kalikasan','Kalikasan at Kapaligiran');
"#).await?;

        // ===== GRADE 11-12 SHS CORE: ORAL COMMUNICATION =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Oral Communication','11',1,'EN11/12OC-Ia-1','explains the nature and process of communication','Communication'),
('Oral Communication','11',1,'EN11/12OC-Ib-1','differentiates the various models of communication','Communication'),
('Oral Communication','11',1,'EN11/12OC-Ic-1','uses various strategies in order to avoid communication breakdown','Communication'),
('Oral Communication','11',1,'EN11/12OC-Id-1','identifies the types of speech context','Communication'),
('Oral Communication','11',1,'EN11/12OC-Ie-1','exhibits appropriate verbal and non-verbal behavior in a given speech context','Communication'),
('Oral Communication','11',1,'EN11/12OC-If-1','identifies the types of speech acts','Communication'),
('Oral Communication','11',1,'EN11/12OC-Ig-1','identifies the verbal and non-verbal cues that communicate feelings','Communication'),
('Oral Communication','11',1,'EN11/12OC-Ih-1','recognizes the social context that influence oral communication','Communication');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Oral Communication','11',2,'EN11/12OC-IIa-1','identifies the principles of effective speech delivery','Speech Delivery'),
('Oral Communication','11',2,'EN11/12OC-IIb-1','uses principles of effective speech delivery in various situations','Speech Delivery'),
('Oral Communication','11',2,'EN11/12OC-IIc-1','uses the appropriate oral language register in various situations','Speech Delivery'),
('Oral Communication','11',2,'EN11/12OC-IId-1','identifies the various types of speeches and their purposes','Speech Types'),
('Oral Communication','11',2,'EN11/12OC-IIe-1','crafts and delivers effective speeches','Speech Types'),
('Oral Communication','11',2,'EN11/12OC-IIf-1','uses various strategies for effective interpersonal communication','Interpersonal Communication'),
('Oral Communication','11',2,'EN11/12OC-IIg-1','communicates effectively in various interview settings','Interpersonal Communication');
"#).await?;

        // ===== GRADE 11-12 SHS CORE: READING AND WRITING =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Reading and Writing','11',1,'EN11/12RWS-Ia-1','describes a written text as a purposeful act of communication','Reading'),
('Reading and Writing','11',1,'EN11/12RWS-Ib-1','identifies the properties of a well-written text','Reading'),
('Reading and Writing','11',1,'EN11/12RWS-Ic-1','reads various types of texts critically','Reading'),
('Reading and Writing','11',1,'EN11/12RWS-Id-1','evaluates a reading or viewing selection based on structures of paragraphs','Reading'),
('Reading and Writing','11',1,'EN11/12RWS-Ie-1','synthesizes information gathered from various sources','Reading');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Reading and Writing','11',2,'EN11/12RWS-IIa-1','writes a close analysis and critique of a text','Writing'),
('Reading and Writing','11',2,'EN11/12RWS-IIb-1','composes a well-crafted informative essay','Writing'),
('Reading and Writing','11',2,'EN11/12RWS-IIc-1','writes a reaction paper based on a specific material','Writing'),
('Reading and Writing','11',2,'EN11/12RWS-IId-1','composes a research-based argumentative essay','Writing'),
('Reading and Writing','11',2,'EN11/12RWS-IIe-1','uses a variety of informational or practical writing strategies','Writing');
"#).await?;

        // ===== GRADE 11-12 SHS CORE: GENERAL MATHEMATICS =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('General Mathematics','11',1,'M11GM-Ia-1','represents real-life situations using functions, including piece-wise functions','Functions and Their Graphs'),
('General Mathematics','11',1,'M11GM-Ia-2','evaluates a function','Functions and Their Graphs'),
('General Mathematics','11',1,'M11GM-Ib-1','performs addition, subtraction, multiplication, division, and composition of functions','Functions and Their Graphs'),
('General Mathematics','11',1,'M11GM-Ib-2','solves problems involving functions','Functions and Their Graphs'),
('General Mathematics','11',1,'M11GM-Ic-1','represents real-life situations using rational functions','Rational Functions'),
('General Mathematics','11',1,'M11GM-Ic-2','distinguishes rational function, rational equation, and rational inequality','Rational Functions'),
('General Mathematics','11',1,'M11GM-Id-1','solves rational equations and inequalities','Rational Functions'),
('General Mathematics','11',1,'M11GM-Ie-1','represents rational functions through its table of values, graph, and equation','Rational Functions'),
('General Mathematics','11',1,'M11GM-If-1','finds the domain and range of a rational function','Rational Functions');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('General Mathematics','11',2,'M11GM-IIa-1','represents real-life situations using one-to-one functions','Inverse and Exponential Functions'),
('General Mathematics','11',2,'M11GM-IIa-2','determines the inverse of a one-to-one function','Inverse and Exponential Functions'),
('General Mathematics','11',2,'M11GM-IIb-1','represents an exponential function through its table of values, graph, and equation','Inverse and Exponential Functions'),
('General Mathematics','11',2,'M11GM-IIb-2','solves exponential equations and inequalities','Inverse and Exponential Functions'),
('General Mathematics','11',2,'M11GM-IIc-1','represents a logarithmic function through its table of values, graph, and equation','Logarithms'),
('General Mathematics','11',2,'M11GM-IId-1','solves logarithmic equations and inequalities','Logarithms'),
('General Mathematics','11',2,'M11GM-IIe-1','represents real-life situations using simple and compound interests','Financial Mathematics'),
('General Mathematics','11',2,'M11GM-IIf-1','computes interest, maturity value, future value, and present value in simple and compound interest','Financial Mathematics'),
('General Mathematics','11',2,'M11GM-IIg-1','illustrates and distinguishes simple and general annuities','Financial Mathematics');
"#).await?;

        // ===== GRADE 11-12 SHS CORE: STATISTICS AND PROBABILITY =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Statistics and Probability','11',3,'M11/12SP-IIIa-1','illustrates a random variable','Random Variables and Probability Distributions'),
('Statistics and Probability','11',3,'M11/12SP-IIIa-2','distinguishes between a discrete and a continuous random variable','Random Variables and Probability Distributions'),
('Statistics and Probability','11',3,'M11/12SP-IIIb-1','finds the possible values of a random variable','Random Variables and Probability Distributions'),
('Statistics and Probability','11',3,'M11/12SP-IIIc-1','illustrates a probability distribution for a discrete random variable and its properties','Random Variables and Probability Distributions'),
('Statistics and Probability','11',3,'M11/12SP-IIId-1','computes probabilities corresponding to a given random variable','Random Variables and Probability Distributions'),
('Statistics and Probability','11',3,'M11/12SP-IIIe-1','illustrates the mean and variance of a discrete random variable','Normal Distribution'),
('Statistics and Probability','11',3,'M11/12SP-IIIf-1','calculates the mean and the variance of a discrete random variable','Normal Distribution'),
('Statistics and Probability','11',3,'M11/12SP-IIIg-1','illustrates a normal random variable and its characteristics','Normal Distribution'),
('Statistics and Probability','11',3,'M11/12SP-IIIh-1','identifies regions under the normal curve corresponding to different standard normal values','Normal Distribution');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Statistics and Probability','11',4,'M11/12SP-IVa-1','illustrates random sampling','Sampling and Estimation'),
('Statistics and Probability','11',4,'M11/12SP-IVb-1','distinguishes between parameter and statistic','Sampling and Estimation'),
('Statistics and Probability','11',4,'M11/12SP-IVc-1','identifies sampling distributions of statistics','Sampling and Estimation'),
('Statistics and Probability','11',4,'M11/12SP-IVd-1','finds the interval estimates of population mean','Sampling and Estimation'),
('Statistics and Probability','11',4,'M11/12SP-IVe-1','illustrates hypothesis testing','Hypothesis Testing'),
('Statistics and Probability','11',4,'M11/12SP-IVf-1','formulates the appropriate null and alternative hypotheses on a population mean','Hypothesis Testing'),
('Statistics and Probability','11',4,'M11/12SP-IVg-1','identifies the appropriate form of the test statistic','Hypothesis Testing'),
('Statistics and Probability','11',4,'M11/12SP-IVh-1','draws conclusions from test results','Hypothesis Testing');
"#).await?;

        // ===== GRADE 11-12 SHS CORE: EARTH AND LIFE SCIENCE =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Earth and Life Science','11',1,'ES11/12ES-Ia-1','describe the origin and structure of the Earth','Earth Science'),
('Earth and Life Science','11',1,'ES11/12ES-Ib-1','describe the Earth''s subsystems','Earth Science'),
('Earth and Life Science','11',1,'ES11/12ES-Ic-1','explain the role of each subsystem in supporting life on Earth','Earth Science'),
('Earth and Life Science','11',1,'ES11/12ES-Id-1','describe the origin of the universe and the solar system','Earth Science'),
('Earth and Life Science','11',1,'ES11/12ES-Ie-1','explain the characteristics of Earth that make it suitable for life','Earth Science'),
('Earth and Life Science','11',1,'ES11/12ES-If-1','describe the Earth''s interior and its layers','Earth Science');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Earth and Life Science','11',2,'ES11/12ES-IIa-1','describe the characteristics and life cycles of stars','Earth Science'),
('Earth and Life Science','11',2,'ES11/12ES-IIb-1','explain the different types of plate boundaries and the geological processes associated','Earth Science'),
('Earth and Life Science','11',2,'ES11/12ES-IIc-1','describe how earthquakes and volcanoes occur','Earth Science'),
('Earth and Life Science','11',2,'LS11/12ES-IId-1','describe the different types of organisms based on their biochemical processes','Life Science'),
('Earth and Life Science','11',2,'LS11/12ES-IIe-1','explain the characteristics of living things','Life Science'),
('Earth and Life Science','11',2,'LS11/12ES-IIf-1','identify the major groups of organisms','Life Science'),
('Earth and Life Science','11',2,'LS11/12ES-IIg-1','describe how ecosystems work','Life Science');
"#).await?;

        // ===== GRADE 12 SHS CORE: PHYSICAL SCIENCE =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Physical Science','12',1,'PS12/12PS-Ia-1','describe the development of the atomic model','Chemistry'),
('Physical Science','12',1,'PS12/12PS-Ib-1','explain how bonding affects properties of materials','Chemistry'),
('Physical Science','12',1,'PS12/12PS-Ic-1','describe how the properties of substances are related to their uses','Chemistry'),
('Physical Science','12',1,'PS12/12PS-Id-1','explain the properties of matter based on particle model','Chemistry'),
('Physical Science','12',1,'PS12/12PS-Ie-1','describe chemical reactions in terms of conservation of mass','Chemistry'),
('Physical Science','12',1,'PS12/12PS-If-1','explain rates of chemical reactions in terms of collision theory','Chemistry');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Physical Science','12',2,'PS12/12PS-IIa-1','describe the motion of objects in terms of displacement, velocity, and acceleration','Physics'),
('Physical Science','12',2,'PS12/12PS-IIb-1','apply Newton''s laws of motion to daily life situations','Physics'),
('Physical Science','12',2,'PS12/12PS-IIc-1','explain how energy is conserved in mechanical processes','Physics'),
('Physical Science','12',2,'PS12/12PS-IId-1','describe the properties of waves and how they transfer energy','Physics'),
('Physical Science','12',2,'PS12/12PS-IIe-1','explain the relationship between electricity and magnetism','Physics'),
('Physical Science','12',2,'PS12/12PS-IIf-1','describe the modern model of the atom and its significance','Physics');
"#).await?;

        // ===== GRADE 11 SHS CORE: 21ST CENTURY LITERATURE =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('21st Century Literature','11',1,'EN11/12LT-Ia-1','identify the geographic, linguistic, and ethnic dimensions of Philippine literary history','Philippine Literature'),
('21st Century Literature','11',1,'EN11/12LT-Ib-1','value the contributions of local writers to Philippine culture','Philippine Literature'),
('21st Century Literature','11',1,'EN11/12LT-Ic-1','identify representative texts and authors from each region','Philippine Literature'),
('21st Century Literature','11',1,'EN11/12LT-Id-1','analyze the relationship of a literary text to the Philippine context','Philippine Literature');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('21st Century Literature','11',2,'EN11/12LT-IIa-1','identify the geographic, linguistic, and ethnic dimensions of world literary history','World Literature'),
('21st Century Literature','11',2,'EN11/12LT-IIb-1','analyze literary texts from various world regions','World Literature'),
('21st Century Literature','11',2,'EN11/12LT-IIc-1','explain the relationship of a literary text to its historical and cultural context','World Literature');
"#).await?;

        // ===== GRADE 11-12 SHS CORE: MEDIA AND INFORMATION LITERACY =====
        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Media and Information Literacy','11',1,'MIL11/12MIL-Ia-1','describes how communication is influenced by media and information','Media Literacy'),
('Media and Information Literacy','11',1,'MIL11/12MIL-Ib-1','identifies the similarities and differences of media literacy, information literacy, and technology literacy','Media Literacy'),
('Media and Information Literacy','11',1,'MIL11/12MIL-Ic-1','compares and contrasts media and information sources','Media Literacy'),
('Media and Information Literacy','11',1,'MIL11/12MIL-Id-1','identifies the different types of media','Media Literacy'),
('Media and Information Literacy','11',1,'MIL11/12MIL-Ie-1','evaluates information from various sources for credibility and reliability','Information Literacy');
"#).await?;

        db.execute_unprepared(r#"INSERT INTO melcs (subject, grade_level, quarter, competency_code, competency_text, domain) VALUES
('Media and Information Literacy','11',2,'MIL11/12MIL-IIa-1','identifies responsible use and creation of media content','Digital Citizenship'),
('Media and Information Literacy','11',2,'MIL11/12MIL-IIb-1','synthesizes information from various media texts','Information Literacy'),
('Media and Information Literacy','11',2,'MIL11/12MIL-IIc-1','produces a media product that shows responsible use of media','Digital Citizenship');
"#).await?;

        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();
        db.execute_unprepared("DELETE FROM melcs;").await?;
        Ok(())
    }
}
