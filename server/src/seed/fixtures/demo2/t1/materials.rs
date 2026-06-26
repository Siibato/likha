//! T1 learning modules for demo-2: 2 subjects × 2 modules each (4 total).

use super::super::{cid, mid};
use crate::seed::specs::MaterialSpec;
use crate::seed::tools::SeedContext;

pub fn demo2_materials_t1(ctx: &SeedContext) -> Vec<MaterialSpec> {
    let mut materials = Vec::with_capacity(4);

    // Science 10: Plate Tectonics
    materials.push(MaterialSpec {
        id: mid("sci_t1_mod1"),
        class_id: cid("sci10"),
        title: "Module 1: The Earth's Interior".into(),
        description: Some("Covers crust, mantle, outer core, inner core, seismic waves, and how scientists study Earth's layers.".into()),
        content_text: Some(
            "The Earth is composed of four main layers: the crust, mantle, outer core, and inner core. \
            The crust is the thin, solid outermost layer where we live. It is made of solid rock and is divided into continental and oceanic crust. \
            Beneath the crust lies the mantle, the thickest layer of the Earth. The mantle is made of semi-solid rock that can flow slowly over geological time. \
            Scientists study Earth's interior by analyzing seismic waves produced by earthquakes. These waves change speed and direction as they pass through different materials. \
            The outer core is a layer of liquid iron and nickel that lies beneath the mantle. The movement of this liquid metal generates Earth's magnetic field. \
            At the very center is the inner core, a solid sphere composed mainly of iron and nickel. Despite extremely high temperatures, the inner core remains solid due to the immense pressure from the layers above."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("sci_t1_mod2"),
        class_id: cid("sci10"),
        title: "Module 2: Plate Tectonics".into(),
        description: Some("Covers plate boundaries (divergent, convergent, transform), landforms, Philippine Ring of Fire, earthquake and volcano formation.".into()),
        content_text: Some(
            "Plate tectonics is the scientific theory that explains how major landforms are created as a result of Earth's subterranean movements. \
            The Earth's lithosphere is broken into large pieces called tectonic plates. These plates float on the semi-fluid asthenosphere and move slowly over time. \
            There are three main types of plate boundaries. At divergent boundaries, plates move away from each other, creating mid-ocean ridges and rift valleys. \
            At convergent boundaries, plates collide. When oceanic and continental plates converge, the denser oceanic plate subducts beneath the continental plate, creating deep ocean trenches and volcanic mountain ranges. \
            At transform boundaries, plates slide past each other horizontally. The Philippines sits along the Pacific Ring of Fire, a horseshoe-shaped belt around the Pacific Ocean where about 75% of the world's volcanoes are located and where earthquakes are frequent. This is because the Philippine archipelago is located at the convergence of several tectonic plates, making it one of the most geologically active places on Earth."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // English 10: Philippine Literature (disconnected from seed)
    // materials.push(MaterialSpec {
    //     id: mid("eng_t1_mod1"),
    //     class_id: cid("eng10"),
    //     title: "Module 1: Elements of Literature".into(),
    //     description: Some("Covers the basic elements of fiction: plot, character, setting, theme, and point of view.".into()),
    //     content_text: Some(
    //         "Literature is any written work that has artistic or intellectual value. Understanding the elements of literature helps readers analyze and appreciate literary works more deeply. \
    //         Plot is the sequence of events in a story, including exposition, rising action, climax, falling action, and resolution. \
    //         Characters are the individuals in the story, including the protagonist (main character), antagonist (opposing force), and supporting characters. \
    //         Setting refers to the time and place where the story takes place, which influences the mood and events of the narrative. \
    //         Theme is the central idea or message of the story, often revealing a universal truth about human nature or society. \
    //         Point of view is the perspective from which the story is told: first person (I), third person limited (he/she), or third person omniscient (all-knowing)."
    //             .into(),
    //     ),
    //     order_index: 0,
    //     created_at: ctx.now(),
    // });
    // materials.push(MaterialSpec {
    //     id: mid("eng_t1_mod2"),
    //     class_id: cid("eng10"),
    //     title: "Module 2: Philippine Literary Forms".into(),
    //     description: Some("Covers Philippine literary forms including short stories, poetry, epics, and their cultural significance.".into()),
    //     content_text: Some(
    //         "Philippine literature reflects the rich cultural heritage and diverse traditions of the Filipino people. \
    //         The maikling kwento (short story) is a brief narrative that focuses on a single incident or character, often with a clear theme. \
    //         Tula (poetry) expresses emotions and ideas through rhythm and imagery, using various literary devices like metaphor, simile, and personification. \
    //         Epiko (epic) is a long narrative poem about heroic deeds, such as Biag ni Lam-ang and Bantugan, which preserve pre-colonial history and values. \
    //         Other forms include bugtong (riddles), tanaga (short poems), and korido (metrical romances). \
    //         These literary forms serve as vehicles for preserving Filipino identity, values, and historical consciousness across generations."
    //             .into(),
    //     ),
    //     order_index: 1,
    //     created_at: ctx.now(),
    // });

    // Math 10: Linear Equations & Inequalities
    materials.push(MaterialSpec {
        id: mid("math_t1_mod1"),
        class_id: cid("math10"),
        title: "Module 1: Linear Equations in Two Variables".into(),
        description: Some("Covers standard form, slope-intercept form, graphing lines, and finding intercepts.".into()),
        content_text: Some(
            "A linear equation in two variables is an equation that can be written in the form Ax + By = C, where A, B, and C are real numbers. \
            The slope-intercept form is y = mx + b, where m is the slope (rate of change) and b is the y-intercept (where the line crosses the y-axis). \
            To graph a linear equation, you can use the slope and y-intercept, find two points and draw a line through them, or use the x- and y-intercepts. \
            The x-intercept is found by setting y = 0 and solving for x. The y-intercept is found by setting x = 0 and solving for y. \
            The slope of a horizontal line is 0, while the slope of a vertical line is undefined. \
            Parallel lines have the same slope, while perpendicular lines have slopes that are negative reciprocals of each other."
                .into(),
        ),
        order_index: 0,
        created_at: ctx.now(),
    });
    materials.push(MaterialSpec {
        id: mid("math_t1_mod2"),
        class_id: cid("math10"),
        title: "Module 2: Systems of Linear Equations".into(),
        description: Some("Covers solving systems by graphing, substitution, and elimination methods.".into()),
        content_text: Some(
            "A system of linear equations consists of two or more linear equations with the same variables. The solution is the point(s) where the graphs intersect. \
            The graphing method involves graphing both equations and finding their intersection point. This method is visual but may not be precise for fractional solutions. \
            The substitution method involves solving one equation for one variable and substituting it into the other equation. This method works well when one equation has a variable with a coefficient of 1. \
            The elimination method involves adding or subtracting equations to eliminate one variable, then solving for the remaining variable. This method is efficient when coefficients can be easily matched. \
            A system can have one solution (consistent and independent), no solution (inconsistent, parallel lines), or infinitely many solutions (consistent and dependent, same line)."
                .into(),
        ),
        order_index: 1,
        created_at: ctx.now(),
    });

    // AP 10: Pre-colonial to Spanish Period (disconnected from seed)
    // materials.push(MaterialSpec {
    //     id: mid("ap_t1_mod1"),
    //     class_id: cid("ap10"),
    //     title: "Module 1: Pre-colonial Philippines".into(),
    //     description: Some("Covers the geographical setting, political structure (barangay), social classes, economy, and culture before Spanish colonization.".into()),
    //     content_text: Some(
    //         "The Philippines is an archipelago of over 7,000 islands strategically located in Southeast Asia, making it a natural crossroads for trade and cultural exchange. \
    //         Before Spanish colonization, Filipinos lived in independent political units called barangays, each headed by a datu (chief). The barangay was both a political and social unit. \
    //         Social structure was hierarchical: the maharlika (nobles) were the elite class; the timawa (freemen) were commoners; and the alipin (dependents) were those who owed service to others. \
    //         The economy was based on agriculture (rice, coconut, abaca) and trade with neighboring countries like China, India, and Japan. \
    //         Filipinos had their own writing system (baybayin), practiced animism and indigenous religions, and had rich oral traditions including epics, folk tales, and songs. \
    //         This pre-colonial society was already complex and organized, with established systems of government, trade, and social relations."
    //             .into(),
    //     ),
    //     order_index: 0,
    //     created_at: ctx.now(),
    // });
    // materials.push(MaterialSpec {
    //     id: mid("ap_t1_mod2"),
    //     class_id: cid("ap10"),
    //     title: "Module 2: Spanish Colonization".into(),
    //     description: Some("Covers Spanish arrival, encomienda system, galleon trade, Catholic Church role, and colonial government.".into()),
    //     content_text: Some(
    //         "Ferdinand Magellan arrived in the Philippines in 1521, marking the first European contact. Spanish colonization formally began with Miguel Lopez de Legazpi in 1565, who established the first permanent settlement in Cebu and later moved the capital to Manila. \
    //         The encomienda system was implemented, giving Spanish officials the right to collect tribute from Filipinos in exchange for protection and Christianization. This system often led to abuse and exploitation. \
    //         The galleon trade (1565-1815) connected Manila to Acapulco, Mexico, bringing silver from the Americas and Asian goods to the Philippines. This trade shaped the Philippine economy for centuries. \
    //         The Catholic Church played a central role in colonial society, serving as both religious authority and political power. Friars influenced government policies and education. \
    //         The reduccion system gathered scattered communities into centralized towns centered around the church, making administration and conversion easier. \
    //         Spanish colonization transformed Philippine society, introducing new religion, language, institutions, and a social hierarchy based on race and class."
    //             .into(),
    //     ),
    //     order_index: 1,
    //     created_at: ctx.now(),
    // });

    // Filipino 10: Maikling Kuwento (disconnected from seed)
    // materials.push(MaterialSpec {
    //     id: mid("fil_t1_mod1"),
    //     class_id: cid("fil10"),
    //     title: "Module 1: Mga Elemento ng Maikling Kwento".into(),
    //     description: Some("Tinatalakay ang mga elemento ng maikling kwento: tauhan, tagpuan, plot, tema, at punto de vista.".into()),
    //     content_text: Some(
    //         "Ang maikling kwento ay isang maikling salaysay na mayroong isang pangyayari o tauhan na mayroong malinaw na tema. \
    //         Ang tauhan ang mga indibidwal sa kwento, kabilang ang bida (protagonista), kalaban (antagonista), at mga sumusuporta. \
    //         Ang tagpuan ang lugar at panahon kung saan nangyayari ang kwento, na nakakaapekto sa mood at mga pangyayari. \
    //         Ang plot ang pagkakasunod-sunod ng mga pangyayari, kasama ang simula, gitna, klimaks, at wakas. \
    //         Ang tema ang pangunahing ideya o mensahe ng kwento, kadalasang nagpapakita ng katotohanan sa buhay ng tao o lipunan. \
    //         Ang punto de vista ang pananaw kung saan sinasabi ang kwento: unang panauhan (ako), ikatlong panauhang limitado (siya/sila), o ikatlong panauhang omniscient (lahat ng alam)."
    //             .into(),
    //     ),
    //     order_index: 0,
    //     created_at: ctx.now(),
    // });
    // materials.push(MaterialSpec {
    //     id: mid("fil_t1_mod2"),
    //     class_id: cid("fil10"),
    //     title: "Module 2: Mga Anyo ng Panitikang Pilipino".into(),
    //     description: Some("Tinatalakay ang mga anyo ng panitikang Pilipino tulad ng maikling kwento, tula, epiko, at kanilang kahalagahan sa kultura.".into()),
    //     content_text: Some(
    //         "Ang panitikang Pilipino ay sumasalamin sa mayamang pamana at iba't ibang tradisyon ng mga Pilipino. \
    //         Ang maikling kwento ay isang maikling salaysay na nakatuon sa isang pangyayari o tauhan, na mayroong malinaw na tema. \
    //         Ang tula ay nagpapahayag ng damdamin at ideya sa pamamagitan ng ritmo at imahen, gamit ang iba't ibang literary device tulad ng metapora, simili, at personipikasyon. \
    //         Ang epiko ay isang mahabang tulang epiko tungkol sa bayaning gawa, tulad ng Biag ni Lam-ang at Bantugan, na nagpapanatili ng kasaysayan at pagpapahalaga bago ang kolonyalismo. \
    //         Ang ibang anyo ay kasama ang bugtong (mga palaisipan), tanaga (maikling tula), at korido (metrikal na romansa). \
    //         Ang mga anyong ito ng panitikan ay nagsisilbing sasakyan sa pagpapanatili ng identidad, pagpapahalaga, at kamalayan sa kasaysayan ng mga Pilipino sa mga henerasyon."
    //             .into(),
    //     ),
    //     order_index: 1,
    //     created_at: ctx.now(),
    // });

    // TLE 10: Computer Hardware Servicing (disconnected from seed)
    // materials.push(MaterialSpec {
    //     id: mid("tle_t1_mod1"),
    //     class_id: cid("tle10"),
    //     title: "Module 1: Computer Components".into(),
    //     description: Some("Covers CPU, RAM, ROM, hard drive, motherboard, GPU, PSU, and their functions.".into()),
    //     content_text: Some(
    //         "Understanding computer components is essential for hardware servicing. The CPU (Central Processing Unit) is the brain of the computer, executing instructions and processing data. \
    //         RAM (Random Access Memory) is temporary memory that stores data currently in use by the CPU. It is volatile, meaning data is lost when power is turned off. \
    //         ROM (Read-Only Memory) is permanent memory that stores essential system instructions. It is non-volatile and retains data even without power. \
    //         The hard drive or SSD (Solid State Drive) provides permanent storage for the operating system, programs, and files. SSDs are faster than traditional hard drives. \
    //         The motherboard is the main circuit board that connects all components together. It houses the CPU, RAM, and provides slots for expansion cards. \
    //         The GPU (Graphics Processing Unit) handles graphics rendering, essential for gaming and graphic design. The PSU (Power Supply Unit) converts electricity from the outlet to power the computer components."
    //             .into(),
    //     ),
    //     order_index: 0,
    //     created_at: ctx.now(),
    // });
    // materials.push(MaterialSpec {
    //     id: mid("tle_t1_mod2"),
    //     class_id: cid("tle10"),
    //     title: "Module 2: Tools and Safety Procedures".into(),
    //     description: Some("Covers computer tools (screwdriver, pliers, anti-static strap), ESD protection, and proper assembly/disassembly procedures.".into()),
    //     content_text: Some(
    //         "Proper tools and safety procedures are critical in computer hardware servicing to prevent damage to components and injury to the technician. \
    //         Essential tools include screwdrivers (Phillips and flathead), pliers (needle-nose and diagonal cutters), and an anti-static wrist strap. \
    //         ESD (Electrostatic Discharge) can damage sensitive electronic components. An anti-static wrist strap grounds the technician, preventing static buildup. \
    //         Always work in a clean, well-lit area with adequate ventilation. Power off and unplug the computer before opening the case. \
    //         When handling components, hold them by the edges and avoid touching the circuitry or contacts. Use thermal paste when installing a CPU to ensure proper heat transfer. \
    //         Follow the manufacturer's instructions and use the correct tools for each task. Organize screws and small parts to avoid losing them during assembly or disassembly."
    //             .into(),
    //     ),
    //     order_index: 1,
    //     created_at: ctx.now(),
    // });

    materials
}
