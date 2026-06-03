use uuid::Uuid;

use super::ids::*;

// ─── Users ──────────────────────────────────────────────────────────────────

pub struct UserFixture {
    pub id: Uuid,
    pub username: &'static str,
    pub full_name: &'static str,
    pub role: &'static str,
    pub password: Option<&'static str>,
    pub account_status: &'static str,
    pub deleted: bool,
}

pub fn users() -> Vec<UserFixture> {
    vec![
        UserFixture { id: ADMIN_ID, username: "admin", full_name: "System Administrator", role: "admin", password: None, account_status: "pending_activation", deleted: false },
        UserFixture { id: TEACHER_01_ID, username: "teacher_01", full_name: "Teacher One", role: "teacher", password: Some(PASSWORD_TEACHER), account_status: "active", deleted: false },
        UserFixture { id: TEACHER_02_ID, username: "teacher_02", full_name: "Teacher Two", role: "teacher", password: Some(PASSWORD_TEACHER), account_status: "active", deleted: false },
        UserFixture { id: STUDENT_01_ID, username: "student_01", full_name: "Student One", role: "student", password: Some(PASSWORD_STUDENT), account_status: "active", deleted: false },
        UserFixture { id: STUDENT_02_ID, username: "student_02", full_name: "Student Two", role: "student", password: Some(PASSWORD_STUDENT), account_status: "active", deleted: false },
        UserFixture { id: STUDENT_03_ID, username: "student_03", full_name: "Student Three", role: "student", password: Some(PASSWORD_STUDENT), account_status: "active", deleted: false },
        UserFixture { id: STUDENT_DELETED_ID, username: "student_deleted_99", full_name: "Student Deleted 99", role: "student", password: Some(PASSWORD_STUDENT), account_status: "active", deleted: true },
    ]
}

// ─── Classes ──────────────────────────────────────────────────────────────────

pub struct ClassFixture {
    pub id: Uuid,
    pub title: &'static str,
    pub grade_level: &'static str,
    pub is_advisory: bool,
    pub is_archived: bool,
    pub deleted: bool,
}

pub fn classes() -> Vec<ClassFixture> {
    vec![
        ClassFixture { id: CLASS_MATH_8A_ID, title: "Mathematics 8A", grade_level: "8", is_advisory: false, is_archived: false, deleted: false },
        ClassFixture { id: CLASS_SCI_8A_ID, title: "Science 8A", grade_level: "8", is_advisory: false, is_archived: false, deleted: false },
        ClassFixture { id: CLASS_ADVISORY_8A_ID, title: "Advisory 8A", grade_level: "8", is_advisory: true, is_archived: false, deleted: false },
        ClassFixture { id: CLASS_ARCHIVED_10A_ID, title: "Archived Class 10A", grade_level: "10", is_advisory: false, is_archived: true, deleted: false },
        ClassFixture { id: CLASS_DELETED_8_ID, title: "Deleted Science 8 (should not appear)", grade_level: "8", is_advisory: false, is_archived: false, deleted: true },
    ]
}

// ─── Enrollments ────────────────────────────────────────────────────────────

pub struct EnrollmentFixture {
    pub class_id: Uuid,
    pub user_id: Uuid,
}

pub fn teacher_enrollments() -> Vec<EnrollmentFixture> {
    vec![
        EnrollmentFixture { class_id: CLASS_MATH_8A_ID, user_id: TEACHER_01_ID },
        EnrollmentFixture { class_id: CLASS_SCI_8A_ID, user_id: TEACHER_01_ID },
        EnrollmentFixture { class_id: CLASS_ADVISORY_8A_ID, user_id: TEACHER_01_ID },
        EnrollmentFixture { class_id: CLASS_ADVISORY_8A_ID, user_id: TEACHER_02_ID },
        EnrollmentFixture { class_id: CLASS_ARCHIVED_10A_ID, user_id: TEACHER_02_ID },
    ]
}

pub fn student_enrollments() -> Vec<EnrollmentFixture> {
    vec![
        EnrollmentFixture { class_id: CLASS_MATH_8A_ID, user_id: STUDENT_01_ID },
        EnrollmentFixture { class_id: CLASS_SCI_8A_ID, user_id: STUDENT_01_ID },
        EnrollmentFixture { class_id: CLASS_ADVISORY_8A_ID, user_id: STUDENT_01_ID },
        EnrollmentFixture { class_id: CLASS_MATH_8A_ID, user_id: STUDENT_02_ID },
        EnrollmentFixture { class_id: CLASS_SCI_8A_ID, user_id: STUDENT_02_ID },
        EnrollmentFixture { class_id: CLASS_ADVISORY_8A_ID, user_id: STUDENT_02_ID },
        EnrollmentFixture { class_id: CLASS_MATH_8A_ID, user_id: STUDENT_03_ID },
        EnrollmentFixture { class_id: CLASS_ADVISORY_8A_ID, user_id: STUDENT_03_ID },
    ]
}

// ─── TOS ──────────────────────────────────────────────────────────────────────

pub struct TosFixture {
    pub id: Uuid,
    pub class_id: Uuid,
    pub period: i32,
    pub title: &'static str,
    pub template_type: &'static str,
    pub total_items: i32,
    pub time_limit_unit: &'static str,
    pub ww_percent: f64,
    pub pt_percent: f64,
    pub qa_percent: f64,
    pub easy_percent: f64,
    pub average_percent: f64,
    pub difficult_percent: f64,
    pub remembering_percent: f64,
    pub understanding_percent: f64,
    pub applying_percent: f64,
    pub analyzing_percent: f64,
    pub evaluating_percent: f64,
    pub creating_percent: f64,
}

pub fn tos_fixtures() -> Vec<TosFixture> {
    vec![
        TosFixture {
            id: TOS_MATH_8A_ID, class_id: CLASS_MATH_8A_ID, period: 1,
            title: "TOS for Mathematics 8A - Q1", template_type: "difficulty", total_items: 30, time_limit_unit: "days",
            ww_percent: 30.0, pt_percent: 50.0, qa_percent: 20.0,
            easy_percent: 15.0, average_percent: 20.0, difficult_percent: 15.0,
            remembering_percent: 15.0, understanding_percent: 15.0, applying_percent: 15.0,
            analyzing_percent: 0.0, evaluating_percent: 0.0, creating_percent: 0.0,
        },
        TosFixture {
            id: TOS_SCI_8A_ID, class_id: CLASS_SCI_8A_ID, period: 1,
            title: "TOS for Science 8A - Q1", template_type: "bloom", total_items: 30, time_limit_unit: "days",
            ww_percent: 30.0, pt_percent: 50.0, qa_percent: 20.0,
            easy_percent: 15.0, average_percent: 20.0, difficult_percent: 15.0,
            remembering_percent: 15.0, understanding_percent: 15.0, applying_percent: 15.0,
            analyzing_percent: 0.0, evaluating_percent: 0.0, creating_percent: 0.0,
        },
    ]
}

pub struct CompetencyFixture {
    pub id: Uuid,
    pub tos_id: Uuid,
    pub code: &'static str,
    pub text: &'static str,
    pub order: i32,
}

pub fn competency_fixtures() -> Vec<CompetencyFixture> {
    vec![
        CompetencyFixture { id: COMP_MATH_1_ID, tos_id: TOS_MATH_8A_ID, code: "M8NS-Ia-1", text: "Represents integers on number line", order: 0 },
        CompetencyFixture { id: COMP_MATH_2_ID, tos_id: TOS_MATH_8A_ID, code: "M8NS-Ib-2", text: "Performs operations on integers", order: 1 },
        CompetencyFixture { id: COMP_MATH_3_ID, tos_id: TOS_MATH_8A_ID, code: "M8AL-Ia-1", text: "Translates verbal phrases to mathematical expressions", order: 2 },
        CompetencyFixture { id: COMP_SCI_1_ID, tos_id: TOS_SCI_8A_ID, code: "S8MT-Ia-1", text: "Describes the distribution of active volcanoes", order: 0 },
        CompetencyFixture { id: COMP_SCI_2_ID, tos_id: TOS_SCI_8A_ID, code: "S8MT-Ib-2", text: "Explains how energy from volcanoes may be tapped", order: 1 },
        CompetencyFixture { id: COMP_SCI_3_ID, tos_id: TOS_SCI_8A_ID, code: "S8ES-Ia-1", text: "Describes the different layers of the Earth", order: 2 },
    ]
}

// ─── Assessments ──────────────────────────────────────────────────────────────

pub struct AssessFixture {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: &'static str,
    pub open_offset: i64,
    pub close_offset: i64,
    pub show_results: bool,
    pub results_released: bool,
    pub component: &'static str,
    pub tos_id: Uuid,
    pub questions: super::ids::QuestionSet,
    pub deleted: bool,
}

pub fn assessment_fixtures() -> Vec<AssessFixture> {
    vec![
        AssessFixture {
            id: ASSESS_MATH_QUIZ1_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Math Quiz 1 (Closed)",
            open_offset: -7,
            close_offset: -1,
            show_results: true,
            results_released: true,
            component: "written_work",
            tos_id: TOS_MATH_8A_ID,
            questions: math_q1_questions(),
            deleted: false,
        },
        AssessFixture {
            id: ASSESS_MATH_QUIZ2_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Math Quiz 2 (Open)",
            open_offset: -1,
            close_offset: 7,
            show_results: false,
            results_released: false,
            component: "performance_task",
            tos_id: TOS_MATH_8A_ID,
            questions: math_q2_questions(),
            deleted: false,
        },
        AssessFixture {
            id: ASSESS_SCI_TEST1_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Science Test 1 (Closed)",
            open_offset: -10,
            close_offset: -2,
            show_results: true,
            results_released: true,
            component: "quarterly_assessment",
            tos_id: TOS_SCI_8A_ID,
            questions: sci_t1_questions(),
            deleted: false,
        },
        AssessFixture {
            id: ASSESS_SCI_TEST2_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Science Test 2 (Open)",
            open_offset: 1,
            close_offset: 14,
            show_results: false,
            results_released: false,
            component: "written_work",
            tos_id: TOS_SCI_8A_ID,
            questions: sci_t2_questions(),
            deleted: false,
        },
        AssessFixture {
            id: ASSESS_DELETED_MATH_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "[DELETED] Review Test - Math 8A",
            open_offset: -8,
            close_offset: -4,
            show_results: false,
            results_released: false,
            component: "written_work",
            tos_id: TOS_MATH_8A_ID,
            questions: deleted_questions(),
            deleted: true,
        },
    ]
}

// ─── Assignments ──────────────────────────────────────────────────────────────

pub struct AssignFixture {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: &'static str,
    pub due_offset: i64,
    pub total_points: i32,
    pub component: &'static str,
    pub deleted: bool,
}

pub fn assignment_fixtures() -> Vec<AssignFixture> {
    vec![
        AssignFixture { id: ASSIGN_MATH_HW1_ID, class_id: CLASS_MATH_8A_ID, title: "Math Homework 1 (Past Due)", due_offset: -5, total_points: 50, component: "written_work", deleted: false },
        AssignFixture { id: ASSIGN_SCI_LAB_ID, class_id: CLASS_SCI_8A_ID, title: "Science Lab Report (Due Soon)", due_offset: 2, total_points: 100, component: "performance_task", deleted: false },
        AssignFixture { id: ASSIGN_MATH_PROJECT_ID, class_id: CLASS_MATH_8A_ID, title: "Math Project (Future)", due_offset: 14, total_points: 200, component: "performance_task", deleted: false },
        AssignFixture { id: ASSIGN_DELETED_ID, class_id: CLASS_SCI_8A_ID, title: "[DELETED] Extra Credit", due_offset: -3, total_points: 50, component: "written_work", deleted: true },
    ]
}

// ─── Assessment Submissions ──────────────────────────────────────────────────

pub struct AssessSubFixture {
    pub sub_id: Uuid,
    pub assessment_id: Uuid,
    pub student_id: Uuid,
    pub started_offset: i64,
}

pub fn assessment_submission_fixtures() -> Vec<AssessSubFixture> {
    vec![
        AssessSubFixture { sub_id: SUB_ASSESS_S01_MQ1, assessment_id: ASSESS_MATH_QUIZ1_ID, student_id: STUDENT_01_ID, started_offset: -6 },
        AssessSubFixture { sub_id: SUB_ASSESS_S02_MQ1, assessment_id: ASSESS_MATH_QUIZ1_ID, student_id: STUDENT_02_ID, started_offset: -6 },
        AssessSubFixture { sub_id: SUB_ASSESS_S03_MQ1, assessment_id: ASSESS_MATH_QUIZ1_ID, student_id: STUDENT_03_ID, started_offset: -5 },
        AssessSubFixture { sub_id: SUB_ASSESS_S01_ST1, assessment_id: ASSESS_SCI_TEST1_ID, student_id: STUDENT_01_ID, started_offset: -9 },
        AssessSubFixture { sub_id: SUB_ASSESS_S02_ST1, assessment_id: ASSESS_SCI_TEST1_ID, student_id: STUDENT_02_ID, started_offset: -9 },
    ]
}

pub fn assessment_question_sets() -> Vec<(Uuid, &'static [Uuid])> {
    vec![
        (ASSESS_MATH_QUIZ1_ID, &[Q_MATH_Q1_1, Q_MATH_Q1_2, Q_MATH_Q1_3, Q_MATH_Q1_4, Q_MATH_Q1_5]),
        (ASSESS_SCI_TEST1_ID, &[Q_SCI_T1_1, Q_SCI_T1_2, Q_SCI_T1_3, Q_SCI_T1_4, Q_SCI_T1_5]),
    ]
}

// ─── Assignment Submissions ────────────────────────────────────────────────────

pub struct AssignSubFixture {
    pub sub_id: Uuid,
    pub assignment_id: Uuid,
    pub student_id: Uuid,
    pub text: Option<&'static str>,
    pub status: &'static str,
    pub grade: Option<i32>,
    pub feedback: Option<&'static str>,
    pub graded_by: Option<Uuid>,
    pub submitted_offset: i64,
    pub graded_offset: Option<i64>,
}

pub fn assignment_submission_fixtures() -> Vec<AssignSubFixture> {
    vec![
        AssignSubFixture {
            sub_id: SUB_ASSIGN_S01_HW1,
            assignment_id: ASSIGN_MATH_HW1_ID,
            student_id: STUDENT_01_ID,
            text: Some("My completed homework."),
            status: "submitted",
            grade: Some(45),
            feedback: Some("Good work, minor deductions."),
            graded_by: Some(TEACHER_01_ID),
            submitted_offset: -4,
            graded_offset: Some(-3),
        },
        AssignSubFixture {
            sub_id: SUB_ASSIGN_S02_HW1,
            assignment_id: ASSIGN_MATH_HW1_ID,
            student_id: STUDENT_02_ID,
            text: Some("My homework attempt."),
            status: "submitted",
            grade: None,
            feedback: None,
            graded_by: None,
            submitted_offset: -4,
            graded_offset: None,
        },
        AssignSubFixture {
            sub_id: SUB_ASSIGN_S01_LAB,
            assignment_id: ASSIGN_SCI_LAB_ID,
            student_id: STUDENT_01_ID,
            text: Some("My lab report."),
            status: "submitted",
            grade: None,
            feedback: None,
            graded_by: None,
            submitted_offset: -4,
            graded_offset: None,
        },
    ]
}

// ─── Learning Materials ───────────────────────────────────────────────────────

pub struct MaterialFixture {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: &'static str,
    pub content: &'static str,
}

pub fn material_fixtures() -> Vec<MaterialFixture> {
    vec![
        MaterialFixture {
            id: MAT_MATH_ID,
            class_id: CLASS_MATH_8A_ID,
            title: "Unit 1: Integer Operations",
            content: "## Integer Operations\n\nIntegers are whole numbers that can be positive, negative, or zero.\n\nOperations on integers follow specific rules for signs.\n\nPractice with number lines helps build intuition.",
        },
        MaterialFixture {
            id: MAT_SCI_ID,
            class_id: CLASS_SCI_8A_ID,
            title: "Unit 1: Volcanoes",
            content: "## Volcanoes\n\nVolcanoes are openings in the Earth's crust where magma reaches the surface.\n\nThe Philippines lies on the Pacific Ring of Fire.\n\nGeothermal energy can be harnessed from volcanic activity.",
        },
        MaterialFixture {
            id: MAT_ADVISORY_ID,
            class_id: CLASS_ADVISORY_8A_ID,
            title: "Advisory Guidelines",
            content: "## Advisory Class Guidelines\n\nThis advisory class covers homeroom activities and student welfare.\n\nAttendance and punctuality are expected.",
        },
        MaterialFixture {
            id: MAT_ARCHIVED_ID,
            class_id: CLASS_ARCHIVED_10A_ID,
            title: "Old Reference Material",
            content: "## Old Reference\n\nThis material is from a previous term.\n\nPlease refer to updated resources.",
        },
    ]
}

// ─── Grading ──────────────────────────────────────────────────────────────────

pub struct GradeScoreFixture {
    pub source_id: Uuid,
    pub source_type: &'static str,
    pub students: &'static [Uuid],
}

pub fn assessment_grade_scores() -> Vec<GradeScoreFixture> {
    vec![
        GradeScoreFixture { source_id: ASSESS_MATH_QUIZ1_ID, source_type: "assessment", students: &[STUDENT_01_ID, STUDENT_02_ID, STUDENT_03_ID] },
        GradeScoreFixture { source_id: ASSESS_MATH_QUIZ2_ID, source_type: "assessment", students: &[STUDENT_01_ID, STUDENT_02_ID, STUDENT_03_ID] },
        GradeScoreFixture { source_id: ASSESS_SCI_TEST1_ID, source_type: "assessment", students: &[STUDENT_01_ID, STUDENT_02_ID] },
        GradeScoreFixture { source_id: ASSESS_SCI_TEST2_ID, source_type: "assessment", students: &[STUDENT_01_ID, STUDENT_02_ID] },
    ]
}

pub fn assignment_grade_scores() -> Vec<GradeScoreFixture> {
    vec![
        GradeScoreFixture { source_id: ASSIGN_MATH_HW1_ID, source_type: "assignment", students: &[STUDENT_01_ID, STUDENT_02_ID, STUDENT_03_ID] },
        GradeScoreFixture { source_id: ASSIGN_SCI_LAB_ID, source_type: "assignment", students: &[STUDENT_01_ID, STUDENT_02_ID] },
        GradeScoreFixture { source_id: ASSIGN_MATH_PROJECT_ID, source_type: "assignment", students: &[STUDENT_01_ID, STUDENT_02_ID, STUDENT_03_ID] },
    ]
}

pub fn period_grade_fixtures() -> Vec<(Uuid, Uuid, f64)> {
    vec![
        (CLASS_MATH_8A_ID, STUDENT_01_ID, 85.0),
        (CLASS_MATH_8A_ID, STUDENT_02_ID, 72.0),
        (CLASS_MATH_8A_ID, STUDENT_03_ID, 65.0),
        (CLASS_SCI_8A_ID, STUDENT_01_ID, 88.0),
        (CLASS_SCI_8A_ID, STUDENT_02_ID, 70.0),
    ]
}

// ─── Score helpers ────────────────────────────────────────────────────────────

pub fn get_student_assess_score(student_id: Uuid, _assessment_id: Uuid) -> f64 {
    if student_id == STUDENT_01_ID {
        6.0
    } else if student_id == STUDENT_02_ID {
        1.0
    } else {
        0.0
    }
}

pub fn get_student_assign_score(student_id: Uuid, assignment_id: Uuid) -> f64 {
    if assignment_id == ASSIGN_MATH_HW1_ID {
        if student_id == STUDENT_01_ID {
            45.0
        } else {
            0.0
        }
    } else {
        0.0
    }
}
