//! Q4 assessments for demo seeding: Physics.

use crate::seed::specs::*;
use crate::seed::tools::SeedContext;
use super::super::{cid, tid, compid, aid, build_questions};

pub fn demo_assessments_q4(ctx: &SeedContext) -> Vec<AssessmentSpec> {
    let created = ctx.days_ago(20);
    let now = ctx.now();
    let comps = &[compid("s10q4_comp_0"), compid("s10q4_comp_1"), compid("s10q4_comp_2"), compid("s10q4_comp_3")];

    let quiz1_qs = build_questions("q4_quiz1",
        &[
            ("Which of Newton's laws states that an object at rest stays at rest unless acted upon by a force?", &["First", "Second", "Third", "Fourth"], 0, "easy", "remembering"),
            ("What is the formula for speed?", &["Force x distance", "Distance / time", "Mass x acceleration", "Energy / time"], 1, "easy", "remembering"),
            ("What does acceleration measure?", &["How fast an object is moving", "The change in velocity over time", "The total distance traveled", "The force applied"], 1, "easy", "remembering"),
            ("If a car travels 100 meters in 10 seconds, what is its average speed?", &["10 m/s", "100 m/s", "1 m/s", "1000 m/s"], 0, "medium", "applying"),
            ("What is the SI unit of force?", &["Watt", "Joule", "Newton", "Pascal"], 2, "easy", "remembering"),
        ],
        &[
            ("What is the term for the tendency of an object to resist changes in motion?", "Inertia", "easy", "remembering"),
            ("What is the speed of an object in a specific direction called?", "Velocity", "easy", "remembering"),
            ("What is the rate at which velocity changes over time?", "Acceleration", "easy", "remembering"),
            ("What does Newton's Third Law state?", "For every action there is an equal and opposite reaction", "easy", "remembering"),
            ("What is the force of attraction between any two masses called?", "Gravitational force", "easy", "remembering"),
        ],
        &[],
        comps,
    );

    let quiz2_qs = build_questions("q4_quiz2",
        &[
            ("Which form of energy is stored in an object due to its position?", &["Kinetic", "Potential", "Thermal", "Chemical"], 1, "easy", "remembering"),
            ("What is the unit of power?", &["Joule", "Watt", "Newton", "Volt"], 1, "easy", "remembering"),
            ("Which simple machine is a sloping surface that reduces the force needed to raise an object?", &["Lever", "Pulley", "Inclined plane", "Wheel and axle"], 2, "easy", "remembering"),
            ("What is the efficiency of a machine that outputs 80 J of work for every 100 J of work input?", &["20%", "80%", "100%", "180%"], 1, "medium", "applying"),
            ("Which type of energy transformation occurs in a hydroelectric dam?", &["Chemical to electrical", "Potential to kinetic to electrical", "Thermal to mechanical", "Nuclear to electrical"], 1, "medium", "understanding"),
        ],
        &[
            ("What is the ability to do work called?", "Energy", "easy", "remembering"),
            ("What is the energy of motion called?", "Kinetic energy", "easy", "remembering"),
            ("What is a device that makes work easier by changing the direction or magnitude of force?", "Simple machine", "easy", "remembering"),
            ("What principle states that energy cannot be created or destroyed?", "Law of conservation of energy", "easy", "remembering"),
            ("What do you call the force exerted per unit area?", "Pressure", "easy", "remembering"),
        ],
        &[],
        comps,
    );

    let exam_qs = build_questions("q4_exam",
        &[
            ("According to Newton's Second Law, what is the relationship between force, mass, and acceleration?", &["F = m + a", "F = m / a", "F = m x a", "F = m - a"], 2, "easy", "remembering"),
            ("A 5 kg object accelerates at 2 m/s2. What is the net force acting on it?", &["2.5 N", "10 N", "7 N", "3 N"], 1, "medium", "applying"),
            ("Which of the following is NOT a simple machine?", &["Lever", "Pulley", "Motor", "Screw"], 2, "easy", "remembering"),
            ("What happens to the kinetic energy of an object if its velocity doubles?", &["It doubles", "It triples", "It quadruples", "It stays the same"], 2, "medium", "applying"),
            ("What is the mechanical advantage of a lever?", &["Output force / input force", "Input force / output force", "Output distance / input distance", "Input distance / output distance"], 0, "medium", "understanding"),
            ("In a perfectly elastic collision, what is conserved?", &["Only momentum", "Only kinetic energy", "Both momentum and kinetic energy", "Neither"], 2, "difficult", "analyzing"),
            ("What is the gravitational potential energy of a 10 kg object lifted 5 meters? (g = 9.8 m/s2)", &["49 J", "98 J", "490 J", "980 J"], 2, "difficult", "applying"),
            ("Which simple machine is essentially an inclined plane wrapped around a cylinder?", &["Lever", "Wedge", "Screw", "Pulley"], 2, "medium", "understanding"),
            ("What does the law of conservation of momentum state?", &["Momentum is created in collisions", "Total momentum before equals total momentum after", "Momentum only applies to moving objects", "Momentum decreases over time"], 1, "medium", "understanding"),
            ("Which form of energy does a stretched spring possess?", &["Kinetic", "Elastic potential", "Thermal", "Chemical"], 1, "easy", "remembering"),
        ],
        &[
            ("What is the formula for work?", "Force times distance", "easy", "remembering"),
            ("What is the unit of energy?", "Joule", "easy", "remembering"),
            ("What is the fixed point around which a lever rotates?", "Fulcrum", "easy", "remembering"),
            ("What force opposes the motion of objects through air?", "Air resistance", "easy", "remembering"),
            ("What is the term for the distance between the fulcrum and the load in a lever?", "Load arm", "medium", "understanding"),
        ],
        &[
            ("Explain Newton's three laws of motion and provide a real-world example for each. Describe how these laws apply to everyday situations such as riding a bicycle, driving a car, or playing sports.", 5, "difficult", "evaluating"),
            ("Describe the relationship between work, energy, and power. Explain how simple machines help us do work more efficiently, and provide two specific examples of simple machines used in Philippine communities.", 5, "difficult", "evaluating"),
        ],
        comps,
    );

    vec![
        AssessmentSpec {
            id: aid("q4_quiz1"), class_id: cid("sci10"),
            title: "Q4 Quiz 1: Force and Motion".into(),
            description: Some("10-item quiz on Newton's laws, speed, velocity, and acceleration.".into()),
            time_limit_minutes: 30, open_at: now - chrono::Duration::days(7), close_at: now - chrono::Duration::days(1),
            show_results_immediately: true, total_points: 10, component: "written_work".into(),
            tos_id: tid("sci10_tos_q4"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, grading_period_number: 4,
            questions: quiz1_qs,
        },
        AssessmentSpec {
            id: aid("q4_quiz2"), class_id: cid("sci10"),
            title: "Q4 Quiz 2: Energy and Simple Machines".into(),
            description: Some("10-item quiz on energy forms, conservation, and simple machines.".into()),
            time_limit_minutes: 30, open_at: now - chrono::Duration::days(5), close_at: now - chrono::Duration::days(1),
            show_results_immediately: true, total_points: 10, component: "written_work".into(),
            tos_id: tid("sci10_tos_q4"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, grading_period_number: 4,
            questions: quiz2_qs,
        },
        AssessmentSpec {
            id: aid("q4_exam"), class_id: cid("sci10"),
            title: "Q4 Quarter Exam: Physics".into(),
            description: Some("25-item quarterly assessment on force, motion, energy, and simple machines.".into()),
            time_limit_minutes: 60, open_at: now - chrono::Duration::days(10), close_at: now - chrono::Duration::days(2),
            show_results_immediately: true, total_points: 25, component: "period_assessment".into(),
            tos_id: tid("sci10_tos_q4"), created_at: created, deleted_at: None,
            is_published: true, results_released: true, grading_period_number: 4,
            questions: exam_qs,
        },
    ]
}
