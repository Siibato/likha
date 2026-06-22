//! Advisory enrollments: teacher + 30 students in all 4 classes.

use crate::seed::specs::EnrollmentSpec;
use super::users::{uid, STUDENT_DATA};
use super::classes::cid;

pub fn advisory_enrollments() -> Vec<EnrollmentSpec> {
    let mut enrollments = Vec::with_capacity(124);

    let class_ids = [cid("eng10"), cid("math10"), cid("sci10"), cid("adv10")];

    for &class_id in &class_ids {
        enrollments.push(EnrollmentSpec {
            class_id,
            user_id: uid("rodrigo.santos"),
        });
    }

    for &(uname, _, _) in &STUDENT_DATA {
        let sid = uid(uname);
        for &class_id in &class_ids {
            enrollments.push(EnrollmentSpec {
                class_id,
                user_id: sid,
            });
        }
    }

    enrollments
}
