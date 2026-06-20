//! Advisory learner details: full details for all 30 students.

use uuid::Uuid;
use chrono::NaiveDate;
use crate::seed::specs::LearnerDetailsSpec;
use crate::seed::tools::seed_id;
use super::users::uid;

fn lid(name: &str) -> Uuid {
    seed_id("learner_details", name)
}

struct StudentDetail {
    uname: &'static str,
    lrn: &'static str,
    age: i32,
    sex: &'static str,
    track: &'static str,
    birthdate: &'static str,
    birthplace: &'static str,
    address: &'static str,
    father: &'static str,
    mother: &'static str,
    guardian: &'static str,
    guardian_contact: &'static str,
}

const DETAILS: [StudentDetail; 30] = [
    StudentDetail { uname: "juan.delacruz", lrn: "136-1234-001", age: 16, sex: "Male", track: "STEM", birthdate: "2009-03-15", birthplace: "Manila", address: "123 Mabini St, Quezon City", father: "Jose Dela Cruz", mother: "Maria Dela Cruz", guardian: "Jose Dela Cruz", guardian_contact: "0917-123-4567" },
    StudentDetail { uname: "maria.santos", lrn: "136-1234-002", age: 15, sex: "Female", track: "STEM", birthdate: "2009-07-22", birthplace: "Pasig", address: "45 Rizal Ave, Pasig City", father: "Antonio Santos", mother: "Carmen Santos", guardian: "Carmen Santos", guardian_contact: "0918-234-5678" },
    StudentDetail { uname: "antonio.garcia", lrn: "136-1234-003", age: 16, sex: "Male", track: "ABM", birthdate: "2009-01-10", birthplace: "Makati", address: "78 Bonifacio Dr, Makati City", father: "Ricardo Garcia", mother: "Teresa Garcia", guardian: "Ricardo Garcia", guardian_contact: "0919-345-6789" },
    StudentDetail { uname: "carmen.bautista", lrn: "136-1234-004", age: 15, sex: "Female", track: "ABM", birthdate: "2009-05-18", birthplace: "Manila", address: "12 Aguinaldo Blvd, Manila", father: "Manuel Bautista", mother: "Rosa Bautista", guardian: "Rosa Bautista", guardian_contact: "0920-456-7890" },
    StudentDetail { uname: "pedro.lim", lrn: "136-1234-005", age: 16, sex: "Male", track: "STEM", birthdate: "2009-09-03", birthplace: "Quezon City", address: "34 Katipunan Ave, Quezon City", father: "Roberto Lim", mother: "Linda Lim", guardian: "Roberto Lim", guardian_contact: "0921-567-8901" },
    StudentDetail { uname: "rosa.mendoza", lrn: "136-1234-006", age: 17, sex: "Female", track: "HUMSS", birthdate: "2008-11-12", birthplace: "Taguig", address: "56 Bayani Rd, Taguig City", father: "Eduardo Mendoza", mother: "Pilar Mendoza", guardian: "Pilar Mendoza", guardian_contact: "0922-678-9012" },
    StudentDetail { uname: "miguel.fernandez", lrn: "136-1234-007", age: 16, sex: "Male", track: "STEM", birthdate: "2009-04-25", birthplace: "Manila", address: "90 Luna St, Manila", father: "Carlos Fernandez", mother: "Dolores Fernandez", guardian: "Carlos Fernandez", guardian_contact: "0923-789-0123" },
    StudentDetail { uname: "lucia.tan", lrn: "136-1234-008", age: 15, sex: "Female", track: "ABM", birthdate: "2009-08-14", birthplace: "Pasay", address: "23 Taft Ave, Pasay City", father: "Fernando Tan", mother: "Esperanza Tan", guardian: "Esperanza Tan", guardian_contact: "0924-890-1234" },
    StudentDetail { uname: "francisco.ramos", lrn: "136-1234-009", age: 16, sex: "Male", track: "HUMSS", birthdate: "2009-02-28", birthplace: "Quezon City", address: "67 Commonwealth Ave, Quezon City", father: "Rafael Ramos", mother: "Consuelo Ramos", guardian: "Rafael Ramos", guardian_contact: "0925-901-2345" },
    StudentDetail { uname: "teresa.villanueva", lrn: "136-1234-010", age: 15, sex: "Female", track: "STEM", birthdate: "2009-06-05", birthplace: "Mandaluyong", address: "89 Shaw Blvd, Mandaluyong City", father: "Andres Villanueva", mother: "Mercedes Villanueva", guardian: "Mercedes Villanueva", guardian_contact: "0926-012-3456" },
    StudentDetail { uname: "carlos.navarro", lrn: "136-1234-011", age: 17, sex: "Male", track: "ABM", birthdate: "2008-12-20", birthplace: "Manila", address: "11 Roxas Blvd, Manila", father: "Gabriel Navarro", mother: "Remedios Navarro", guardian: "Gabriel Navarro", guardian_contact: "0927-123-4567" },
    StudentDetail { uname: "dolores.castillo", lrn: "136-1234-012", age: 16, sex: "Female", track: "HUMSS", birthdate: "2009-03-08", birthplace: "Marikina", address: "45 Bayan St, Marikina City", father: "Diego Castillo", mother: "Milagros Castillo", guardian: "Diego Castillo", guardian_contact: "0928-234-5678" },
    StudentDetail { uname: "manuel.flores", lrn: "136-1234-013", age: 15, sex: "Male", track: "STEM", birthdate: "2009-07-30", birthplace: "Quezon City", address: "78 Aurora Blvd, Quezon City", father: "Lorenzo Flores", mother: "Trinidad Flores", guardian: "Lorenzo Flores", guardian_contact: "0929-345-6789" },
    StudentDetail { uname: "esperanza.morales", lrn: "136-1234-014", age: 16, sex: "Female", track: "ABM", birthdate: "2009-01-17", birthplace: "Pasig", address: "22 Ortigas Ave, Pasig City", father: "Ramon Morales", mother: "Pilar Morales", guardian: "Pilar Morales", guardian_contact: "0930-456-7890" },
    StudentDetail { uname: "rafael.santiago", lrn: "136-1234-015", age: 17, sex: "Male", track: "STEM", birthdate: "2008-10-11", birthplace: "Makati", address: "56 Ayala Ave, Makati City", father: "Ernesto Santiago", mother: "Soledad Santiago", guardian: "Ernesto Santiago", guardian_contact: "0931-567-8901" },
    StudentDetail { uname: "consuelo.delrosario", lrn: "136-1234-016", age: 15, sex: "Female", track: "HUMSS", birthdate: "2009-05-22", birthplace: "Manila", address: "90 Del Pilar St, Manila", father: "Eduardo Del Rosario", mother: "Cristina Del Rosario", guardian: "Cristina Del Rosario", guardian_contact: "0932-678-9012" },
    StudentDetail { uname: "andres.deleon", lrn: "136-1234-017", age: 16, sex: "Male", track: "ABM", birthdate: "2009-09-14", birthplace: "Taguig", address: "34 McKinley Rd, Taguig City", father: "Francisco De Leon", mother: "Teresa De Leon", guardian: "Francisco De Leon", guardian_contact: "0933-789-0123" },
    StudentDetail { uname: "mercedes.reyes", lrn: "136-1234-018", age: 15, sex: "Female", track: "STEM", birthdate: "2009-04-03", birthplace: "Quezon City", address: "67 Scout St, Quezon City", father: "Antonio Reyes", mother: "Rosa Reyes", guardian: "Antonio Reyes", guardian_contact: "0934-890-1234" },
    StudentDetail { uname: "gabriel.aguilar", lrn: "136-1234-019", age: 16, sex: "Male", track: "HUMSS", birthdate: "2009-08-19", birthplace: "Manila", address: "12 Quirino Ave, Manila", father: "Manuel Aguilar", mother: "Carmen Aguilar", guardian: "Manuel Aguilar", guardian_contact: "0935-901-2345" },
    StudentDetail { uname: "remedios.silva", lrn: "136-1234-020", age: 17, sex: "Female", track: "ABM", birthdate: "2008-11-25", birthplace: "Pasay", address: "45 Tramo St, Pasay City", father: "Pedro Silva", mother: "Lucia Silva", guardian: "Pedro Silva", guardian_contact: "0936-012-3456" },
    StudentDetail { uname: "diego.alvarez", lrn: "136-1234-021", age: 15, sex: "Male", track: "STEM", birthdate: "2009-02-10", birthplace: "Mandaluyong", address: "78 Pinatubo St, Mandaluyong City", father: "Miguel Alvarez", mother: "Dolores Alvarez", guardian: "Miguel Alvarez", guardian_contact: "0937-123-4567" },
    StudentDetail { uname: "milagros.pascual", lrn: "136-1234-022", age: 16, sex: "Female", track: "HUMSS", birthdate: "2009-06-28", birthplace: "Marikina", address: "23 Sumulong Hwy, Marikina City", father: "Rafael Pascual", mother: "Esperanza Pascual", guardian: "Esperanza Pascual", guardian_contact: "0938-234-5678" },
    StudentDetail { uname: "lorenzo.gonzalez", lrn: "136-1234-023", age: 17, sex: "Male", track: "ABM", birthdate: "2008-12-05", birthplace: "Quezon City", address: "56 Gilmore St, Quezon City", father: "Carlos Gonzalez", mother: "Mercedes Gonzalez", guardian: "Carlos Gonzalez", guardian_contact: "0939-345-6789" },
    StudentDetail { uname: "trinidad.soriano", lrn: "136-1234-024", age: 15, sex: "Female", track: "STEM", birthdate: "2009-03-20", birthplace: "Manila", address: "89 UN Ave, Manila", father: "Andres Soriano", mother: "Remedios Soriano", guardian: "Andres Soriano", guardian_contact: "0940-456-7890" },
    StudentDetail { uname: "ramon.rivera", lrn: "136-1234-025", age: 16, sex: "Male", track: "HUMSS", birthdate: "2009-07-12", birthplace: "Pasig", address: "12 C. Raymundo Ave, Pasig City", father: "Gabriel Rivera", mother: "Consuelo Rivera", guardian: "Gabriel Rivera", guardian_contact: "0941-567-8901" },
    StudentDetail { uname: "pilar.delacruz", lrn: "136-1234-026", age: 15, sex: "Female", track: "ABM", birthdate: "2009-01-28", birthplace: "Makati", address: "45 Kalayaan Ave, Makati City", father: "Diego Dela Cruz", mother: "Milagros Dela Cruz", guardian: "Milagros Dela Cruz", guardian_contact: "0942-678-9012" },
    StudentDetail { uname: "ernesto.bautista", lrn: "136-1234-027", age: 17, sex: "Male", track: "STEM", birthdate: "2008-10-15", birthplace: "Taguig", address: "78 Lakeview St, Taguig City", father: "Lorenzo Bautista", mother: "Trinidad Bautista", guardian: "Lorenzo Bautista", guardian_contact: "0943-789-0123" },
    StudentDetail { uname: "soledad.ortega", lrn: "136-1234-028", age: 16, sex: "Female", track: "HUMSS", birthdate: "2009-05-10", birthplace: "Manila", address: "23 Singalong St, Manila", father: "Ramon Ortega", mother: "Pilar Ortega", guardian: "Ramon Ortega", guardian_contact: "0944-890-1234" },
    StudentDetail { uname: "eduardo.martinez", lrn: "136-1234-029", age: 15, sex: "Male", track: "ABM", birthdate: "2009-09-22", birthplace: "Quezon City", address: "56 Tandang Sora Ave, Quezon City", father: "Ernesto Martinez", mother: "Soledad Martinez", guardian: "Ernesto Martinez", guardian_contact: "0945-901-2345" },
    StudentDetail { uname: "cristina.domingo", lrn: "136-1234-030", age: 16, sex: "Female", track: "STEM", birthdate: "2009-04-08", birthplace: "Pasay", address: "89 F.B. Harrison St, Pasay City", father: "Eduardo Domingo", mother: "Cristina Domingo", guardian: "Eduardo Domingo", guardian_contact: "0946-012-3456" },
];

pub fn advisory_learner_details() -> Vec<LearnerDetailsSpec> {
    let mut details = Vec::with_capacity(30);

    for d in &DETAILS {
        details.push(LearnerDetailsSpec {
            id: lid(d.uname),
            user_id: uid(d.uname),
            lrn: Some(d.lrn.into()),
            age: Some(d.age),
            sex: Some(d.sex.into()),
            track_strand: Some(d.track.into()),
            curriculum: Some("K to 12".into()),
            birthdate: Some(NaiveDate::parse_from_str(d.birthdate, "%Y-%m-%d").unwrap()),
            birthplace: Some(d.birthplace.into()),
            home_address: Some(d.address.into()),
            father_name: Some(d.father.into()),
            father_contact: None,
            mother_name: Some(d.mother.into()),
            mother_contact: None,
            guardian_name: Some(d.guardian.into()),
            guardian_contact: Some(d.guardian_contact.into()),
            date_admitted: Some(NaiveDate::from_ymd_opt(2025, 6, 15).unwrap()),
        });
    }

    details
}
