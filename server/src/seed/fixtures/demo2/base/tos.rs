//! Demo-2 TOS: 3 terms for 3 classes (1 Advisory + 2 subjects: Science, Math).

use super::super::{cid, tid};
use crate::seed::specs::TosSpec;

pub fn demo2_tos() -> Vec<TosSpec> {
    let mut tos_list = Vec::with_capacity(9);

    // Advisory Mahogany - T1–T3 (difficulty template, no assessments)
    for term in 1..=3 {
        tos_list.push(TosSpec {
            id: tid(&format!("adv_mahogany_tos_t{}", term)),
            class_id: cid("adv_mahogany"),
            term_number: term,
            title: format!("TOS for Advisory Mahogany - T{}", term),
            template_type: "difficulty".into(),
            total_items: 20,
            time_limit_unit: "days".into(),
            ww_percent: 50.0,
            pt_percent: 30.0,
            qa_percent: 20.0,
            easy_percent: 40.0,
            average_percent: 40.0,
            difficult_percent: 20.0,
            remembering_percent: 25.0,
            understanding_percent: 25.0,
            applying_percent: 25.0,
            analyzing_percent: 10.0,
            evaluating_percent: 10.0,
            creating_percent: 5.0,
        });
    }

    // Science 10 - T1–T3 (bloom template, WW 40%, PT 40%, QA 20%)
    for term in 1..=3 {
        tos_list.push(TosSpec {
            id: tid(&format!("sci10_tos_t{}", term)),
            class_id: cid("sci10"),
            term_number: term,
            title: format!("TOS for Science 10 - T{}", term),
            template_type: "bloom".into(),
            total_items: 50,
            time_limit_unit: "days".into(),
            ww_percent: 40.0,
            pt_percent: 40.0,
            qa_percent: 20.0,
            easy_percent: 30.0,
            average_percent: 50.0,
            difficult_percent: 20.0,
            remembering_percent: 20.0,
            understanding_percent: 20.0,
            applying_percent: 20.0,
            analyzing_percent: 15.0,
            evaluating_percent: 15.0,
            creating_percent: 10.0,
        });
    }

    // English 10 - T1–T3 (disconnected from seed)
    // for term in 1..=3 {
    //     tos_list.push(TosSpec {
    //         id: tid(&format!("eng10_tos_t{}", term)),
    //         class_id: cid("eng10"),
    //         term_number: term,
    //         title: format!("TOS for English 10 - T{}", term),
    //         template_type: "bloom".into(),
    //         total_items: 50,
    //         time_limit_unit: "days".into(),
    //         ww_percent: 50.0,
    //         pt_percent: 30.0,
    //         qa_percent: 20.0,
    //         easy_percent: 30.0,
    //         average_percent: 50.0,
    //         difficult_percent: 20.0,
    //         remembering_percent: 20.0,
    //         understanding_percent: 20.0,
    //         applying_percent: 20.0,
    //         analyzing_percent: 15.0,
    //         evaluating_percent: 15.0,
    //         creating_percent: 10.0,
    //     });
    // }

    // Math 10 - T1–T3 (bloom template, WW 50%, PT 30%, QA 20%)
    for term in 1..=3 {
        tos_list.push(TosSpec {
            id: tid(&format!("math10_tos_t{}", term)),
            class_id: cid("math10"),
            term_number: term,
            title: format!("TOS for Mathematics 10 - T{}", term),
            template_type: "bloom".into(),
            total_items: 50,
            time_limit_unit: "days".into(),
            ww_percent: 50.0,
            pt_percent: 30.0,
            qa_percent: 20.0,
            easy_percent: 30.0,
            average_percent: 50.0,
            difficult_percent: 20.0,
            remembering_percent: 20.0,
            understanding_percent: 20.0,
            applying_percent: 20.0,
            analyzing_percent: 15.0,
            evaluating_percent: 15.0,
            creating_percent: 10.0,
        });
    }

    // AP 10 - T1–T3 (disconnected from seed)
    // for term in 1..=3 {
    //     tos_list.push(TosSpec {
    //         id: tid(&format!("ap10_tos_t{}", term)),
    //         class_id: cid("ap10"),
    //         term_number: term,
    //         title: format!("TOS for Araling Panlipunan 10 - T{}", term),
    //         template_type: "bloom".into(),
    //         total_items: 50,
    //         time_limit_unit: "days".into(),
    //         ww_percent: 50.0,
    //         pt_percent: 30.0,
    //         qa_percent: 20.0,
    //         easy_percent: 30.0,
    //         average_percent: 50.0,
    //         difficult_percent: 20.0,
    //         remembering_percent: 20.0,
    //         understanding_percent: 20.0,
    //         applying_percent: 20.0,
    //         analyzing_percent: 15.0,
    //         evaluating_percent: 15.0,
    //         creating_percent: 10.0,
    //     });
    // }

    // Filipino 10 - T1–T3 (disconnected from seed)
    // for term in 1..=3 {
    //     tos_list.push(TosSpec {
    //         id: tid(&format!("fil10_tos_t{}", term)),
    //         class_id: cid("fil10"),
    //         term_number: term,
    //         title: format!("TOS for Filipino 10 - T{}", term),
    //         template_type: "bloom".into(),
    //         total_items: 50,
    //         time_limit_unit: "days".into(),
    //         ww_percent: 50.0,
    //         pt_percent: 30.0,
    //         qa_percent: 20.0,
    //         easy_percent: 30.0,
    //         average_percent: 50.0,
    //         difficult_percent: 20.0,
    //         remembering_percent: 20.0,
    //         understanding_percent: 20.0,
    //         applying_percent: 20.0,
    //         analyzing_percent: 15.0,
    //         evaluating_percent: 15.0,
    //         creating_percent: 10.0,
    //     });
    // }

    // TLE 10 - T1–T3 (disconnected from seed)
    // for term in 1..=3 {
    //     tos_list.push(TosSpec {
    //         id: tid(&format!("tle10_tos_t{}", term)),
    //         class_id: cid("tle10"),
    //         term_number: term,
    //         title: format!("TOS for TLE 10 - T{}", term),
    //         template_type: "bloom".into(),
    //         total_items: 50,
    //         time_limit_unit: "days".into(),
    //         ww_percent: 50.0,
    //         pt_percent: 30.0,
    //         qa_percent: 20.0,
    //         easy_percent: 30.0,
    //         average_percent: 50.0,
    //         difficult_percent: 20.0,
    //         remembering_percent: 20.0,
    //         understanding_percent: 20.0,
    //         applying_percent: 20.0,
    //         analyzing_percent: 15.0,
    //         evaluating_percent: 15.0,
    //         creating_percent: 10.0,
    //     });
    // }

    tos_list
}
