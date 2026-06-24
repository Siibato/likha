//! Shared helpers for fixture generation.
//!
//! Name generators and patterns used by both E2E and manual fixtures.

use crate::seed::tools::seed_id;
use uuid::Uuid;

pub const PASSWORD_TEACHER: &str = "teacher123";

pub const PASSWORD_STUDENT: &str = "student123";

pub fn user_id(name: &str) -> Uuid {
    seed_id("users", name)
}

pub fn class_id(name: &str) -> Uuid {
    seed_id("classes", name)
}

pub fn tos_id(name: &str) -> Uuid {
    seed_id("tos", name)
}

pub fn competency_id(name: &str) -> Uuid {
    seed_id("competencies", name)
}

pub fn assessment_id(name: &str) -> Uuid {
    seed_id("assessments", name)
}

pub fn question_id(assessment_name: &str, question_num: u32) -> Uuid {
    seed_id("questions", &format!("{assessment_name}_q{question_num}"))
}

pub fn assignment_id(name: &str) -> Uuid {
    seed_id("assignments", name)
}

pub fn material_id(name: &str) -> Uuid {
    seed_id("materials", name)
}

pub fn choice_id(question_id: &str, choice_order: u32) -> Uuid {
    seed_id("choices", &format!("{question_id}_c{choice_order}"))
}

pub fn submission_id(prefix: &str, student_name: &str, assessment_name: &str) -> Uuid {
    seed_id(
        "submissions",
        &format!("{prefix}_{student_name}_{assessment_name}"),
    )
}

pub fn number_to_word(n: u32) -> &'static str {
    match n {
        1 => "One",
        2 => "Two",
        3 => "Three",
        4 => "Four",
        5 => "Five",
        6 => "Six",
        7 => "Seven",
        8 => "Eight",
        9 => "Nine",
        10 => "Ten",
        11 => "Eleven",
        12 => "Twelve",
        13 => "Thirteen",
        14 => "Fourteen",
        15 => "Fifteen",
        16 => "Sixteen",
        17 => "Seventeen",
        18 => "Eighteen",
        19 => "Nineteen",
        20 => "Twenty",
        21 => "TwentyOne",
        22 => "TwentyTwo",
        23 => "TwentyThree",
        24 => "TwentyFour",
        25 => "TwentyFive",
        26 => "TwentySix",
        27 => "TwentySeven",
        28 => "TwentyEight",
        29 => "TwentyNine",
        30 => "Thirty",
        31 => "ThirtyOne",
        32 => "ThirtyTwo",
        33 => "ThirtyThree",
        34 => "ThirtyFour",
        35 => "ThirtyFive",
        36 => "ThirtySix",
        37 => "ThirtySeven",
        38 => "ThirtyEight",
        39 => "ThirtyNine",
        40 => "Forty",
        41 => "FortyOne",
        42 => "FortyTwo",
        43 => "FortyThree",
        44 => "FortyFour",
        45 => "FortyFive",
        46 => "FortySix",
        47 => "FortySeven",
        48 => "FortyEight",
        49 => "FortyNine",
        50 => "Fifty",
        51 => "FiftyOne",
        52 => "FiftyTwo",
        53 => "FiftyThree",
        54 => "FiftyFour",
        55 => "FiftyFive",
        56 => "FiftySix",
        57 => "FiftySeven",
        58 => "FiftyEight",
        59 => "FiftyNine",
        60 => "Sixty",
        61 => "SixtyOne",
        62 => "SixtyTwo",
        63 => "SixtyThree",
        64 => "SixtyFour",
        65 => "SixtyFive",
        66 => "SixtySix",
        67 => "SixtySeven",
        68 => "SixtyEight",
        69 => "SixtyNine",
        70 => "Seventy",
        _ => "Unknown",
    }
}

pub fn student_username(n: u32) -> String {
    format!("student_{n:02}")
}

pub fn student_first_name(_n: u32) -> String {
    "Student".to_string()
}

pub fn student_last_name(n: u32) -> String {
    number_to_word(n).to_string()
}

pub fn teacher_username(n: u32) -> String {
    format!("teacher_{n:02}")
}

pub fn teacher_first_name(_n: u32) -> String {
    "Teacher".to_string()
}

pub fn teacher_last_name(n: u32) -> String {
    number_to_word(n).to_string()
}
