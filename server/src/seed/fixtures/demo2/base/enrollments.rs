//! Demo-2 enrollments: 1 teacher + 30 students in 3 classes (1 advisory + 2 subjects).

use super::super::{cid, uid};
use super::users::STUDENT_DATA;
use crate::seed::specs::EnrollmentSpec;

pub fn demo2_enrollments() -> Vec<EnrollmentSpec> {
    let mut enrollments = Vec::with_capacity(93);

    // Teacher enrollments — single teacher for all classes
    enrollments.push(EnrollmentSpec {
        class_id: cid("adv_mahogany"),
        user_id: uid("rodrigo.santos"),
    });
    enrollments.push(EnrollmentSpec {
        class_id: cid("sci10"),
        user_id: uid("rodrigo.santos"),
    });
    // enrollments.push(EnrollmentSpec {
    //     class_id: cid("eng10"),
    //     user_id: uid("rodrigo.santos"),
    // });
    enrollments.push(EnrollmentSpec {
        class_id: cid("math10"),
        user_id: uid("rodrigo.santos"),
    });
    // enrollments.push(EnrollmentSpec {
    //     class_id: cid("ap10"),
    //     user_id: uid("rodrigo.santos"),
    // });
    // enrollments.push(EnrollmentSpec {
    //     class_id: cid("fil10"),
    //     user_id: uid("rodrigo.santos"),
    // });
    // enrollments.push(EnrollmentSpec {
    //     class_id: cid("tle10"),
    //     user_id: uid("rodrigo.santos"),
    // });

    // All 30 students in 3 classes
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
        // enrollments.push(EnrollmentSpec {
        //     class_id: cid("eng10"),
        //     user_id: sid,
        // });
        enrollments.push(EnrollmentSpec {
            class_id: cid("math10"),
            user_id: sid,
        });
        // enrollments.push(EnrollmentSpec {
        //     class_id: cid("ap10"),
        //     user_id: sid,
        // });
        // enrollments.push(EnrollmentSpec {
        //     class_id: cid("fil10"),
        //     user_id: sid,
        // });
        // enrollments.push(EnrollmentSpec {
        //     class_id: cid("tle10"),
        //     user_id: sid,
        // });
    }

    enrollments
}
