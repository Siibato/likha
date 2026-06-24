//! Demo-2 users: 6 teachers + 30 Filipino students.

use super::super::uid;
use crate::seed::fixtures::shared::{PASSWORD_STUDENT, PASSWORD_TEACHER};
use crate::seed::specs::UserSpec;
use crate::seed::tools::SeedContext;

pub const STUDENT_DATA: [(&str, &str, &str); 30] = [
    ("juan.delacruz", "Juan", "Dela Cruz"),
    ("maria.santos", "Maria", "Santos"),
    ("antonio.garcia", "Antonio", "Garcia"),
    ("carmen.bautista", "Carmen", "Bautista"),
    ("pedro.lim", "Pedro", "Lim"),
    ("rosa.mendoza", "Rosa", "Mendoza"),
    ("miguel.fernandez", "Miguel", "Fernandez"),
    ("lucia.tan", "Lucia", "Tan"),
    ("francisco.ramos", "Francisco", "Ramos"),
    ("teresa.villanueva", "Teresa", "Villanueva"),
    ("carlos.navarro", "Carlos", "Navarro"),
    ("dolores.castillo", "Dolores", "Castillo"),
    ("manuel.flores", "Manuel", "Flores"),
    ("esperanza.morales", "Esperanza", "Morales"),
    ("rafael.santiago", "Rafael", "Santiago"),
    ("consuelo.delrosario", "Consuelo", "Del Rosario"),
    ("andres.deleon", "Andres", "De Leon"),
    ("mercedes.reyes", "Mercedes", "Reyes"),
    ("gabriel.aguilar", "Gabriel", "Aguilar"),
    ("remedios.silva", "Remedios", "Silva"),
    ("diego.alvarez", "Diego", "Alvarez"),
    ("milagros.pascual", "Milagros", "Pascual"),
    ("lorenzo.gonzalez", "Lorenzo", "Gonzalez"),
    ("trinidad.soriano", "Trinidad", "Soriano"),
    ("ramon.rivera", "Ramon", "Rivera"),
    ("pilar.delacruz", "Pilar", "Dela Cruz"),
    ("ernesto.bautista", "Ernesto", "Bautista"),
    ("soledad.ortega", "Soledad", "Ortega"),
    ("eduardo.martinez", "Eduardo", "Martinez"),
    ("cristina.domingo", "Cristina", "Domingo"),
];

pub const TEACHER_DATA: [(&str, &str, &str); 6] = [
    ("rodrigo.santos", "Rodrigo", "Santos"),
    ("maria.reyes", "Maria", "Reyes"),
    ("antonio.cruz", "Antonio", "Cruz"),
    ("carmen.bautista", "Carmen", "Bautista"),
    ("pedro.lim", "Pedro", "Lim"),
    ("rosa.mendoza", "Rosa", "Mendoza"),
];

pub fn demo2_users(ctx: &SeedContext) -> Vec<UserSpec> {
    let created = ctx.days_ago(30);
    let activated = ctx.days_ago(29);
    let mut users = Vec::with_capacity(36);

    // Teachers
    for &(uname, fname, lname) in &TEACHER_DATA {
        users.push(UserSpec {
            id: uid(uname),
            username: uname.into(),
            first_name: fname.into(),
            last_name: lname.into(),
            role: "teacher".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_TEACHER, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        });
    }

    // Students
    for &(uname, fname, lname) in &STUDENT_DATA {
        users.push(UserSpec {
            id: uid(uname),
            username: uname.into(),
            first_name: fname.into(),
            last_name: lname.into(),
            role: "student".into(),
            password_hash: Some(bcrypt::hash(PASSWORD_STUDENT, 4).unwrap()),
            account_status: "active".into(),
            created_at: created,
            activated_at: Some(activated),
            deleted_at: None,
        });
    }

    users
}
