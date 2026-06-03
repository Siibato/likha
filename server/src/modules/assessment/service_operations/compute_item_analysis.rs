use std::collections::{HashMap, HashSet};
use uuid::Uuid;
use crate::utils::AppResult;
use crate::modules::assessment::schema::*;
use super::helpers::{get_difficulty_label, get_discrimination_label, get_verdict};

impl crate::modules::assessment::service::AssessmentService {
    pub(super) async fn compute_item_analysis(
        &self,
        questions: &[entity::assessment_questions::Model],
        submitted: &[&entity::assessment_submissions::Model],
        student_question_correct: &HashMap<(Uuid, Uuid), bool>,
        student_question_choices: &HashMap<(Uuid, Uuid), Vec<(Option<Uuid>, bool)>>,
        submission_count: usize,
    ) -> AppResult<(Vec<ItemAnalysis>, Option<TestSummary>)> {
        let mut sorted_students: Vec<_> = submitted.iter().map(|s| (s.user_id, s.total_points)).collect();
        sorted_students.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

        let n = (0.27 * submission_count as f64).ceil() as usize;
        let group_size = n.max(3);

        let upper_group: HashSet<Uuid> = sorted_students.iter().take(group_size).map(|(id, _)| *id).collect();
        let lower_group: HashSet<Uuid> = sorted_students.iter().rev().take(group_size).map(|(id, _)| *id).collect();

        let upper_size = upper_group.len() as f64;
        let lower_size = lower_group.len() as f64;

        let mut question_choices: HashMap<Uuid, Vec<(Uuid, String, bool)>> = HashMap::new();
        for q in questions {
            if q.question_type == "multiple_choice" {
                let choices = self.assessment_repo.find_choices_by_question_id(q.id).await?;
                question_choices.insert(
                    q.id,
                    choices.into_iter().map(|c| (c.id, c.choice_text, c.is_correct)).collect(),
                );
            }
        }

        let mut item_analyses = Vec::new();
        let mut total_p = 0.0;
        let mut total_d = 0.0;
        let mut retain_count = 0;
        let mut revise_count = 0;
        let mut discard_count = 0;

        for q in questions {
            let mut ru = 0usize;
            let mut rl = 0usize;

            for &uid in &upper_group {
                let key = (uid, q.id);
                if let Some(&correct) = student_question_correct.get(&key) {
                    if correct { ru += 1; }
                }
            }
            for &uid in &lower_group {
                let key = (uid, q.id);
                if let Some(&correct) = student_question_correct.get(&key) {
                    if correct { rl += 1; }
                }
            }

            let p = if upper_size + lower_size > 0.0 {
                (ru + rl) as f64 / (upper_size + lower_size)
            } else { 0.0 };

            let d = if upper_size > 0.0 && lower_size > 0.0 {
                (ru as f64 / upper_size) - (rl as f64 / lower_size)
            } else { 0.0 };

            let difficulty_label = get_difficulty_label(p);
            let discrimination_label = get_discrimination_label(d);
            let verdict = get_verdict(p, d);

            total_p += p;
            total_d += d;
            match verdict.as_str() {
                "retain" => retain_count += 1,
                "revise" => revise_count += 1,
                "discard" => discard_count += 1,
                _ => {}
            }

            let distractors = if q.question_type == "multiple_choice" {
                if let Some(choices) = question_choices.get(&q.id) {
                    let total_students = submission_count;
                    let mut distractor_results = Vec::new();

                    for (choice_id, choice_text, is_correct) in choices {
                        let mut upper_count = 0usize;
                        let mut lower_count = 0usize;
                        let mut total_selected = 0usize;

                        for s in submitted.iter() {
                            let key = (s.user_id, q.id);
                            if let Some(selections) = student_question_choices.get(&key) {
                                for (sel_choice_id, _) in selections {
                                    if sel_choice_id.as_ref() == Some(choice_id) {
                                        total_selected += 1;
                                        if upper_group.contains(&s.user_id) { upper_count += 1; }
                                        if lower_group.contains(&s.user_id) { lower_count += 1; }
                                    }
                                }
                            }
                        }

                        let total_percentage = if total_students > 0 {
                            (total_selected as f64 / total_students as f64) * 100.0
                        } else { 0.0 };

                        let is_effective = if *is_correct { true } else { lower_count > upper_count };

                        distractor_results.push(DistractorAnalysis {
                            choice_id: *choice_id,
                            choice_text: choice_text.clone(),
                            is_correct: *is_correct,
                            upper_count,
                            lower_count,
                            total_percentage,
                            is_effective,
                        });
                    }

                    Some(distractor_results)
                } else { None }
            } else { None };

            item_analyses.push(ItemAnalysis {
                question_id: q.id,
                question_text: q.question_text.clone(),
                question_type: q.question_type.clone(),
                points: q.points,
                difficulty_index: p,
                difficulty_label,
                discrimination_index: d,
                discrimination_label,
                verdict,
                distractors,
            });
        }

        let total_items = item_analyses.len();
        let test_summary = if total_items > 0 {
            Some(TestSummary {
                mean_difficulty: total_p / total_items as f64,
                mean_discrimination: total_d / total_items as f64,
                retain_count,
                revise_count,
                discard_count,
                total_items_analyzed: total_items,
                upper_group_size: upper_group.len(),
                lower_group_size: lower_group.len(),
            })
        } else { None };

        Ok((item_analyses, test_summary))
    }
}
