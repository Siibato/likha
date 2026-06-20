//! Demo enrollments: teacher + 30 students in both classes.

use crate::seed::specs::EnrollmentSpec;
use super::super::{cid, uid};
use super::users::STUDENT_DATA;

pub fn demo_enrollments() -> Vec<EnrollmentSpec> {
    let mut enrollments = Vec::with_capacity(62);

    // Teacher enrollments
    enrollments.push(EnrollmentSpec { class_id: cid("sci10"), user_id: uid("rodrigo.santos") });
    enrollments.push(EnrollmentSpec { class_id: cid("adv10"), user_id: uid("rodrigo.santos") });

    // All 30 students in both classes
    for &(uname, _) in &STUDENT_DATA {
        let sid = uid(uname);
        enrollments.push(EnrollmentSpec { class_id: cid("sci10"), user_id: sid });
        enrollments.push(EnrollmentSpec { class_id: cid("adv10"), user_id: sid });
    }

    enrollments
}
