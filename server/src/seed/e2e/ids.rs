use chrono::{Duration, NaiveDateTime, Utc};
use uuid::{uuid, Uuid};

// ─── User UUIDs ──────────────────────────────────────────────────────────────

pub const ADMIN_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000001");
pub const TEACHER_01_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000002");
pub const TEACHER_02_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000003");
pub const STUDENT_01_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000010");
pub const STUDENT_02_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000011");
pub const STUDENT_03_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000012");
pub const STUDENT_DELETED_ID: Uuid = uuid!("a1b2c3d4-1111-2222-3333-000000000099");

// ─── Class UUIDs ─────────────────────────────────────────────────────────────

pub const CLASS_MATH_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000001");
pub const CLASS_SCI_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000002");
pub const CLASS_ADVISORY_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000003");
pub const CLASS_ARCHIVED_10A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000004");
pub const CLASS_DELETED_8_ID: Uuid = uuid!("a1b2c3d4-1111-2222-4444-000000000099");

// ─── TOS UUIDs ───────────────────────────────────────────────────────────────

pub const TOS_MATH_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-5555-000000000001");
pub const TOS_SCI_8A_ID: Uuid = uuid!("a1b2c3d4-1111-2222-5555-000000000002");

// ─── TOS Competency UUIDs ────────────────────────────────────────────────────

pub const COMP_MATH_1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000001");
pub const COMP_MATH_2_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000002");
pub const COMP_MATH_3_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000003");
pub const COMP_SCI_1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000004");
pub const COMP_SCI_2_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000005");
pub const COMP_SCI_3_ID: Uuid = uuid!("a1b2c3d4-1111-2222-6666-000000000006");

// ─── Assessment UUIDs ────────────────────────────────────────────────────────

pub const ASSESS_MATH_QUIZ1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000001");
pub const ASSESS_MATH_QUIZ2_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000002");
pub const ASSESS_SCI_TEST1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000003");
pub const ASSESS_SCI_TEST2_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000004");
pub const ASSESS_DELETED_MATH_ID: Uuid = uuid!("a1b2c3d4-1111-2222-7777-000000000099");

// ─── Assessment Question UUIDs (5 per assessment) ────────────────────────────

pub const Q_MATH_Q1_1: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000001");
pub const Q_MATH_Q1_2: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000002");
pub const Q_MATH_Q1_3: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000003");
pub const Q_MATH_Q1_4: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000004");
pub const Q_MATH_Q1_5: Uuid = uuid!("a1b2c3d4-1111-2222-8801-000000000005");

pub const Q_MATH_Q2_1: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000001");
pub const Q_MATH_Q2_2: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000002");
pub const Q_MATH_Q2_3: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000003");
pub const Q_MATH_Q2_4: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000004");
pub const Q_MATH_Q2_5: Uuid = uuid!("a1b2c3d4-1111-2222-8802-000000000005");

pub const Q_SCI_T1_1: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000001");
pub const Q_SCI_T1_2: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000002");
pub const Q_SCI_T1_3: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000003");
pub const Q_SCI_T1_4: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000004");
pub const Q_SCI_T1_5: Uuid = uuid!("a1b2c3d4-1111-2222-8803-000000000005");

pub const Q_SCI_T2_1: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000001");
pub const Q_SCI_T2_2: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000002");
pub const Q_SCI_T2_3: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000003");
pub const Q_SCI_T2_4: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000004");
pub const Q_SCI_T2_5: Uuid = uuid!("a1b2c3d4-1111-2222-8804-000000000005");

pub const Q_DELETED_1: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000001");
pub const Q_DELETED_2: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000002");
pub const Q_DELETED_3: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000003");
pub const Q_DELETED_4: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000004");
pub const Q_DELETED_5: Uuid = uuid!("a1b2c3d4-1111-2222-8809-000000000005");

// ─── Assignment UUIDs ────────────────────────────────────────────────────────

pub const ASSIGN_MATH_HW1_ID: Uuid = uuid!("a1b2c3d4-1111-2222-9999-000000000001");
pub const ASSIGN_SCI_LAB_ID: Uuid = uuid!("a1b2c3d4-1111-2222-9999-000000000002");
pub const ASSIGN_MATH_PROJECT_ID: Uuid = uuid!("a1b2c3d4-1111-2222-9999-000000000003");
pub const ASSIGN_DELETED_ID: Uuid = uuid!("a1b2c3d4-1111-2222-9999-000000000099");

// ─── Assessment Submission UUIDs ─────────────────────────────────────────────

pub const SUB_ASSESS_S01_MQ1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000001");
pub const SUB_ASSESS_S02_MQ1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000002");
pub const SUB_ASSESS_S03_MQ1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000003");
pub const SUB_ASSESS_S01_ST1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000004");
pub const SUB_ASSESS_S02_ST1: Uuid = uuid!("a1b2c3d4-1111-2222-aaaa-000000000005");

// ─── Assignment Submission UUIDs ─────────────────────────────────────────────

pub const SUB_ASSIGN_S01_HW1: Uuid = uuid!("a1b2c3d4-1111-2222-bbbb-000000000001");
pub const SUB_ASSIGN_S02_HW1: Uuid = uuid!("a1b2c3d4-1111-2222-bbbb-000000000002");
pub const SUB_ASSIGN_S01_LAB: Uuid = uuid!("a1b2c3d4-1111-2222-bbbb-000000000003");

// ─── Learning Material UUIDs ─────────────────────────────────────────────────

pub const MAT_MATH_ID: Uuid = uuid!("a1b2c3d4-1111-2222-cccc-000000000001");
pub const MAT_SCI_ID: Uuid = uuid!("a1b2c3d4-1111-2222-cccc-000000000002");
pub const MAT_ADVISORY_ID: Uuid = uuid!("a1b2c3d4-1111-2222-cccc-000000000003");
pub const MAT_ARCHIVED_ID: Uuid = uuid!("a1b2c3d4-1111-2222-cccc-000000000004");

// ─── Passwords ───────────────────────────────────────────────────────────────

pub const PASSWORD_TEACHER: &str = "teacher123";
pub const PASSWORD_STUDENT: &str = "student123";

// ─── Relative Date Anchor ────────────────────────────────────────────────────

pub fn now() -> NaiveDateTime {
    Utc::now().naive_utc()
}

pub fn days_ago(n: u64) -> NaiveDateTime {
    now() - Duration::days(n as i64)
}

pub fn days_from_now(n: u64) -> NaiveDateTime {
    now() + Duration::days(n as i64)
}

// ─── Question layout helpers ─────────────────────────────────────────────────

pub struct QuestionSet {
    pub q1: Uuid,
    pub q2: Uuid,
    pub q3: Uuid,
    pub q4: Uuid,
    pub q5: Uuid,
    pub comps: [Uuid; 3],
}

pub fn math_q1_questions() -> QuestionSet {
    QuestionSet {
        q1: Q_MATH_Q1_1,
        q2: Q_MATH_Q1_2,
        q3: Q_MATH_Q1_3,
        q4: Q_MATH_Q1_4,
        q5: Q_MATH_Q1_5,
        comps: [COMP_MATH_1_ID, COMP_MATH_2_ID, COMP_MATH_3_ID],
    }
}

pub fn math_q2_questions() -> QuestionSet {
    QuestionSet {
        q1: Q_MATH_Q2_1,
        q2: Q_MATH_Q2_2,
        q3: Q_MATH_Q2_3,
        q4: Q_MATH_Q2_4,
        q5: Q_MATH_Q2_5,
        comps: [COMP_MATH_1_ID, COMP_MATH_2_ID, COMP_MATH_3_ID],
    }
}

pub fn sci_t1_questions() -> QuestionSet {
    QuestionSet {
        q1: Q_SCI_T1_1,
        q2: Q_SCI_T1_2,
        q3: Q_SCI_T1_3,
        q4: Q_SCI_T1_4,
        q5: Q_SCI_T1_5,
        comps: [COMP_SCI_1_ID, COMP_SCI_2_ID, COMP_SCI_3_ID],
    }
}

pub fn sci_t2_questions() -> QuestionSet {
    QuestionSet {
        q1: Q_SCI_T2_1,
        q2: Q_SCI_T2_2,
        q3: Q_SCI_T2_3,
        q4: Q_SCI_T2_4,
        q5: Q_SCI_T2_5,
        comps: [COMP_SCI_1_ID, COMP_SCI_2_ID, COMP_SCI_3_ID],
    }
}

pub fn deleted_questions() -> QuestionSet {
    QuestionSet {
        q1: Q_DELETED_1,
        q2: Q_DELETED_2,
        q3: Q_DELETED_3,
        q4: Q_DELETED_4,
        q5: Q_DELETED_5,
        comps: [COMP_MATH_1_ID, COMP_MATH_2_ID, COMP_MATH_3_ID],
    }
}
