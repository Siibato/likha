//! Demo TOS: 4 terms for Science 10 and Advisory 10.

use crate::seed::specs::TosSpec;
use super::super::{cid, tid};

pub fn demo_tos() -> Vec<TosSpec> {
    vec![
        // Science 10 - T1–T4 (bloom template)
        TosSpec {
            id: tid("sci10_tos_t1"), class_id: cid("sci10"), term_number: 1,
            title: "TOS for Science 10 - T1".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("sci10_tos_t2"), class_id: cid("sci10"), term_number: 2,
            title: "TOS for Science 10 - T2".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("sci10_tos_t3"), class_id: cid("sci10"), term_number: 3,
            title: "TOS for Science 10 - T3".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        TosSpec {
            id: tid("sci10_tos_t4"), class_id: cid("sci10"), term_number: 4,
            title: "TOS for Science 10 - T4".into(), template_type: "bloom".into(),
            total_items: 50, time_limit_unit: "days".into(),
            ww_percent: 40.0, pt_percent: 40.0, qa_percent: 20.0,
            easy_percent: 30.0, average_percent: 50.0, difficult_percent: 20.0,
            remembering_percent: 20.0, understanding_percent: 20.0, applying_percent: 20.0,
            analyzing_percent: 15.0, evaluating_percent: 15.0, creating_percent: 10.0,
        },
        // Advisory 10 - T1–T4 (difficulty template)
        TosSpec {
            id: tid("adv10_tos_t1"), class_id: cid("adv10"), term_number: 1,
            title: "TOS for Advisory 10 - T1".into(), template_type: "difficulty".into(),
            total_items: 20, time_limit_unit: "days".into(),
            ww_percent: 50.0, pt_percent: 30.0, qa_percent: 20.0,
            easy_percent: 40.0, average_percent: 40.0, difficult_percent: 20.0,
            remembering_percent: 25.0, understanding_percent: 25.0, applying_percent: 25.0,
            analyzing_percent: 10.0, evaluating_percent: 10.0, creating_percent: 5.0,
        },
        TosSpec {
            id: tid("adv10_tos_t2"), class_id: cid("adv10"), term_number: 2,
            title: "TOS for Advisory 10 - T2".into(), template_type: "difficulty".into(),
            total_items: 20, time_limit_unit: "days".into(),
            ww_percent: 50.0, pt_percent: 30.0, qa_percent: 20.0,
            easy_percent: 40.0, average_percent: 40.0, difficult_percent: 20.0,
            remembering_percent: 25.0, understanding_percent: 25.0, applying_percent: 25.0,
            analyzing_percent: 10.0, evaluating_percent: 10.0, creating_percent: 5.0,
        },
        TosSpec {
            id: tid("adv10_tos_t3"), class_id: cid("adv10"), term_number: 3,
            title: "TOS for Advisory 10 - T3".into(), template_type: "difficulty".into(),
            total_items: 20, time_limit_unit: "days".into(),
            ww_percent: 50.0, pt_percent: 30.0, qa_percent: 20.0,
            easy_percent: 40.0, average_percent: 40.0, difficult_percent: 20.0,
            remembering_percent: 25.0, understanding_percent: 25.0, applying_percent: 25.0,
            analyzing_percent: 10.0, evaluating_percent: 10.0, creating_percent: 5.0,
        },
        TosSpec {
            id: tid("adv10_tos_t4"), class_id: cid("adv10"), term_number: 4,
            title: "TOS for Advisory 10 - T4".into(), template_type: "difficulty".into(),
            total_items: 20, time_limit_unit: "days".into(),
            ww_percent: 50.0, pt_percent: 30.0, qa_percent: 20.0,
            easy_percent: 40.0, average_percent: 40.0, difficult_percent: 20.0,
            remembering_percent: 25.0, understanding_percent: 25.0, applying_percent: 25.0,
            analyzing_percent: 10.0, evaluating_percent: 10.0, creating_percent: 5.0,
        },
    ]
}
