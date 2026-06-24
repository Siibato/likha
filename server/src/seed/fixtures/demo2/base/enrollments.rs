//! Demo-2 enrollments: 6 teachers + 30 students in all 7 classes.

use super::super::{cid, uid};
use super::users::STUDENT_DATA;
use crate::seed::specs::EnrollmentSpec;

pub fn demo2_enrollments() -> Vec<EnrollmentSpec> {
    let mut enrollments = Vec::with_capacity(217);

    // Teacher enrollments
    // Rodrigo Santos: Advisory + Science
    enrollments.push(EnrollmentSpec {
        class_id: cid("adv_mahogany"),
        user_id: uid("rodrigo.santos"),
    });
    enrollments.push(EnrollmentSpec {
        class_id: cid("sci10"),
        user_id: uid("rodrigo.santos"),
    });
    // Maria Reyes: English
    enrollments.push(EnrollmentSpec {
        class_id: cid("eng10"),
        user_id: uid("maria.reyes"),
    });
    // Antonio Cruz: Math
    enrollments.push(EnrollmentSpec {
        class_id: cid("math10"),
        user_id: uid("antonio.cruz"),
    });
    // Carmen Bautista: AP
    enrollments.push(EnrollmentSpec {
        class_id: cid("ap10"),
        user_id: uid("carmen.bautista"),
    });
    // Pedro Lim: Filipino
    enrollments.push(EnrollmentSpec {
        class_id: cid("fil10"),
        user_id: uid("pedro.lim"),
    });
    // Rosa Mendoza: TLE
    enrollments.push(EnrollmentSpec {
        class_id: cid("tle10"),
        user_id: uid("rosa.mendoza"),
    });

    // All 30 students in all 7 classes
    for &(uname, _, _) in &STUDENT_DATA {
        let sid = uid(uname);
        enrollments.push(EnrollmentSpec {
            class_id: cid("adv_mahogany"),
            user_id: sid,
        });
        enrollments.push(EnrollmentSpec {
            class_id: cid("sci10"),
            user_id: sid,
        });
        enrollments.push(EnrollmentSpec {
            class_id: cid("eng10"),
            user_id: sid,
        });
        enrollments.push(EnrollmentSpec {
            class_id: cid("math10"),
            user_id: sid,
        });
        enrollments.push(EnrollmentSpec {
            class_id: cid("ap10"),
            user_id: sid,
        });
        enrollments.push(EnrollmentSpec {
            class_id: cid("fil10"),
            user_id: sid,
        });
        enrollments.push(EnrollmentSpec {
            class_id: cid("tle10"),
            user_id: sid,
        });
    }

    enrollments
}
