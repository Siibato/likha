//! T4 learning modules for demo seeding: Physics.

use super::super::{cid, mid};
use crate::seed::specs::MaterialSpec;
use crate::seed::tools::SeedContext;

pub fn demo_materials_t4(ctx: &SeedContext) -> Vec<MaterialSpec> {
    vec![
        MaterialSpec {
            id: mid("t4_mod1"), class_id: cid("sci10"),
            title: "Module 1: Force and Motion".into(),
            description: Some("Covers Newton's laws, speed, velocity, acceleration, and momentum.".into()),
            content_text: Some(
                "Force and motion are fundamental concepts in physics that explain how objects move and interact. Sir Isaac Newton formulated three laws of motion that form the basis of classical mechanics. Newton's First Law, also called the Law of Inertia, states that an object at rest stays at rest and an object in motion stays in motion with the same speed and direction unless acted upon by an unbalanced force. Newton's Second Law states that the acceleration of an object is directly proportional to the net force acting on it and inversely proportional to its mass, expressed as F = ma. Newton's Third Law states that for every action, there is an equal and opposite reaction. Speed is a scalar quantity that measures how fast an object is moving, while velocity is a vector quantity that includes both speed and direction. Acceleration is the rate of change of velocity over time. Momentum is the product of an object's mass and velocity, and according to the law of conservation of momentum, the total momentum of a closed system remains constant unless acted upon by external forces."
                    .into(),
            ),
            order_index: 0, created_at: ctx.now(),
        },
        MaterialSpec {
            id: mid("t4_mod2"), class_id: cid("sci10"),
            title: "Module 2: Energy and Simple Machines".into(),
            description: Some("Covers forms of energy, conservation of energy, work, power, and simple machines.".into()),
            content_text: Some(
                "Energy is the ability to do work, and it exists in many forms including kinetic, potential, thermal, chemical, and electrical energy. Kinetic energy is the energy of motion, while potential energy is stored energy due to position or condition. The law of conservation of energy states that energy cannot be created or destroyed, only transformed from one form to another. Work is done when a force causes an object to move in the direction of the force, calculated as W = Fd. Power is the rate at which work is done, measured in watts (W = work/time). Simple machines are devices that make work easier by changing the direction or magnitude of a force. The six classical simple machines are the lever, wheel and axle, pulley, inclined plane, wedge, and screw. Each machine provides a mechanical advantage, which is the ratio of output force to input force. However, no machine can create energy; they only redistribute it. Understanding energy and simple machines is essential for designing efficient tools, vehicles, and structures in everyday life."
                    .into(),
            ),
            order_index: 1, created_at: ctx.now(),
        },
    ]
}
