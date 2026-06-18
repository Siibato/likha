use std::collections::{HashMap, HashSet};
use uuid::Uuid;
use crate::utils::AppResult;
use crate::modules::assessment::schema::*;
use super::helpers::{get_difficulty_label, get_discrimination_label, get_verdict};

impl crate::modules::assessment::service::AssessmentService {
    pub(super) async fn compute_item_analysis(
        &self,
        questions: &[entity::assessment_questions::Model],
        submitted: &[entity::assessment_submissions::Model],
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

        // Batch-load all choices for MC questions in a single query
        let mc_question_ids: Vec<Uuid> = questions
            .iter()
            .filter(|q| q.question_type == "multiple_choice")
            .map(|q| q.id)
            .collect();

        let mut question_choices: HashMap<Uuid, Vec<(Uuid, String, bool)>> =
            HashMap::with_capacity(mc_question_ids.len());
        if !mc_question_ids.is_empty() {
            let all_choices = self.assessment_repo.find_choices_by_question_ids(&mc_question_ids).await?;
            for c in all_choices {
                question_choices
                    .entry(c.question_id)
                    .or_default()
                    .push((c.id, c.choice_text, c.is_correct));
            }
        }

        // Pre-compute correct counts per question for upper/lower groups
        let mut upper_correct: HashMap<Uuid, usize> = HashMap::with_capacity(questions.len());
        let mut lower_correct: HashMap<Uuid, usize> = HashMap::with_capacity(questions.len());
        for ((student_id, question_id), is_correct) in student_question_correct {
            if !is_correct {
                continue;
            }
            if upper_group.contains(student_id) {
                *upper_correct.entry(*question_id).or_insert(0) += 1;
            }
            if lower_group.contains(student_id) {
                *lower_correct.entry(*question_id).or_insert(0) += 1;
            }
        }

        // Pre-compute distractor selection counts: (question_id, choice_id) -> (total, upper, lower)
        let mut choice_selections: HashMap<(Uuid, Uuid), (usize, usize, usize)> = HashMap::new();
        for ((student_id, question_id), selections) in student_question_choices {
            for (choice_id_opt, _) in selections {
                if let Some(choice_id) = choice_id_opt {
                    let (total, upper, lower) = choice_selections
                        .entry((*question_id, *choice_id))
                        .or_insert((0, 0, 0));
                    *total += 1;
                    if upper_group.contains(student_id) { *upper += 1; }
                    if lower_group.contains(student_id) { *lower += 1; }
                }
            }
        }

        let mut item_analyses = Vec::with_capacity(questions.len());
        let mut total_p = 0.0;
        let mut total_d = 0.0;
        let mut retain_count = 0;
        let mut revise_count = 0;
        let mut discard_count = 0;

        for q in questions {
            let ru = upper_correct.get(&q.id).copied().unwrap_or(0);
            let rl = lower_correct.get(&q.id).copied().unwrap_or(0);

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
                    let mut distractor_results = Vec::with_capacity(choices.len());

                    for (choice_id, choice_text, is_correct) in choices {
                        let (total_selected, upper_count, lower_count) = choice_selections
                            .get(&(q.id, *choice_id))
                            .copied()
                            .unwrap_or((0, 0, 0));

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
            // KR-20 reliability coefficient
            let kr20 = {
                let n_students = submission_count as f64;
                let k = total_items as f64;

                if k > 1.0 && n_students > 1.0 {
                    // Per-item proportion correct across ALL students
                    let mut all_correct: HashMap<Uuid, usize> = HashMap::new();
                    for ((_, question_id), is_correct) in student_question_correct {
                        if *is_correct {
                            *all_correct.entry(*question_id).or_insert(0) += 1;
                        }
                    }

                    let mut pq_sum = 0.0;
                    for q in questions {
                        let correct = all_correct.get(&q.id).copied().unwrap_or(0) as f64;
                        let p_i = correct / n_students;
                        pq_sum += p_i * (1.0 - p_i);
                    }

                    // Variance of correct-item counts per student
                    let mut student_correct: HashMap<Uuid, usize> = HashMap::new();
                    for ((student_id, _), is_correct) in student_question_correct {
                        if *is_correct {
                            *student_correct.entry(*student_id).or_insert(0) += 1;
                        }
                    }
                    let correct_counts: Vec<f64> = submitted.iter()
                        .map(|s| student_correct.get(&s.user_id).copied().unwrap_or(0) as f64)
                        .collect();
                    let mean_correct = correct_counts.iter().sum::<f64>() / n_students;
                    let variance = correct_counts.iter()
                        .map(|&c| { let d = c - mean_correct; d * d })
                        .sum::<f64>() / n_students;

                    if variance > 0.0 {
                        Some((k / (k - 1.0)) * (1.0 - pq_sum / variance))
                    } else {
                        None
                    }
                } else {
                    None
                }
            };

            Some(TestSummary {
                mean_difficulty: total_p / total_items as f64,
                mean_discrimination: total_d / total_items as f64,
                retain_count,
                revise_count,
                discard_count,
                total_items_analyzed: total_items,
                upper_group_size: upper_group.len(),
                lower_group_size: lower_group.len(),
                kr20,
            })
        } else { None };

        Ok((item_analyses, test_summary))
    }
}
