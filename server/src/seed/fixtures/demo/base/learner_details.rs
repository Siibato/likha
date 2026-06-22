//! Demo learner details for 30 students.

use uuid::Uuid;
use crate::seed::specs::LearnerDetailsSpec;
use crate::seed::tools::seed_id;
use super::super::uid;

fn lid(name: &str) -> Uuid { seed_id("learner_details", name) }

pub fn demo_learner_details() -> Vec<LearnerDetailsSpec> {
    let mut details = Vec::with_capacity(30);

    let data: [(&str, &str, i32, &str, &str, &str); 30] = [
        ("juan.delacruz",      "136-1234-001", 16, "Male",   "STEM",          "K to 12"),
        ("maria.santos",        "136-1234-002", 15, "Female", "STEM",          "K to 12"),
        ("antonio.garcia",      "136-1234-003", 16, "Male",   "ABM",           "K to 12"),
        ("carmen.bautista",     "136-1234-004", 15, "Female", "ABM",           "K to 12"),
        ("pedro.lim",           "136-1234-005", 16, "Male",   "STEM",          "K to 12"),
        ("rosa.mendoza",        "136-1234-006", 17, "Female", "HUMSS",         "K to 12"),
        ("miguel.fernandez",    "136-1234-007", 16, "Male",   "STEM",          "K to 12"),
        ("lucia.tan",           "136-1234-008", 15, "Female", "ABM",           "K to 12"),
        ("francisco.ramos",     "136-1234-009", 16, "Male",   "HUMSS",         "K to 12"),
        ("teresa.villanueva",   "136-1234-010", 15, "Female", "STEM",          "K to 12"),
        ("carlos.navarro",      "136-1234-011", 17, "Male",   "ABM",           "K to 12"),
        ("dolores.castillo",    "136-1234-012", 16, "Female", "HUMSS",         "K to 12"),
        ("manuel.flores",       "136-1234-013", 15, "Male",   "STEM",          "K to 12"),
        ("esperanza.morales",   "136-1234-014", 16, "Female", "ABM",           "K to 12"),
        ("rafael.santiago",     "136-1234-015", 17, "Male",   "STEM",          "K to 12"),
        ("consuelo.delrosario", "136-1234-016", 15, "Female", "HUMSS",         "K to 12"),
        ("andres.deleon",       "136-1234-017", 16, "Male",   "ABM",           "K to 12"),
        ("mercedes.reyes",      "136-1234-018", 15, "Female", "STEM",          "K to 12"),
        ("gabriel.aguilar",     "136-1234-019", 16, "Male",   "HUMSS",         "K to 12"),
        ("remedios.silva",      "136-1234-020", 17, "Female", "ABM",           "K to 12"),
        ("diego.alvarez",       "136-1234-021", 15, "Male",   "STEM",          "K to 12"),
        ("milagros.pascual",    "136-1234-022", 16, "Female", "HUMSS",         "K to 12"),
        ("lorenzo.gonzalez",    "136-1234-023", 17, "Male",   "ABM",           "K to 12"),
        ("trinidad.soriano",    "136-1234-024", 15, "Female", "STEM",          "K to 12"),
        ("ramon.rivera",        "136-1234-025", 16, "Male",   "HUMSS",         "K to 12"),
        ("pilar.delacruz",      "136-1234-026", 15, "Female", "ABM",           "K to 12"),
        ("ernesto.bautista",    "136-1234-027", 17, "Male",   "STEM",          "K to 12"),
        ("soledad.ortega",      "136-1234-028", 16, "Female", "HUMSS",         "K to 12"),
        ("eduardo.martinez",    "136-1234-029", 15, "Male",   "ABM",           "K to 12"),
        ("cristina.domingo",    "136-1234-030", 16, "Female", "STEM",          "K to 12"),
    ];

    for (uname, lrn, age, sex, track, curriculum) in &data {
        details.push(LearnerDetailsSpec {
            id: lid(uname),
            user_id: uid(uname),
            lrn: Some((*lrn).into()),
            age: Some(*age),
            sex: Some((*sex).into()),
            track_strand: Some((*track).into()),
            curriculum: Some((*curriculum).into()),
            birthdate: None,
            birthplace: None,
            home_address: None,
            father_name: None,
            father_contact: None,
            mother_name: None,
            mother_contact: None,
            guardian_name: None,
            guardian_contact: None,
            date_admitted: None,
        });
    }

    details
}
