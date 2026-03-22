use std::collections::{HashMap, HashSet};
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::schema::assessment_schema::*;

impl super::AssessmentService {
    pub async fn get_statistics(
        &self,
        assessment_id: Uuid,
        teacher_id: Uuid,
    ) -> AppResult<AssessmentStatisticsResponse> {
        let assessment = self.assessment_repo.find_by_id(assessment_id).await?
            .ok_or_else(|| AppError::NotFound("Assessment not found".to_string()))?;

        let _class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submissions = self.submission_repo
            .find_by_assessment_id(assessment_id).await?;

        let submitted: Vec<_> = submissions.iter().filter(|s| s.submitted_at.is_some()).collect();
        let submission_count = submitted.len();

        let scores: Vec<f64> = submitted.iter().map(|s| s.total_points as f64).collect();

        let class_statistics = if scores.is_empty() {
            ClassStatistics {
                mean: 0.0,
                median: 0.0,
                highest: 0.0,
                lowest: 0.0,
                score_distribution: Vec::new(),
            }
        } else {
            Self::calculate_class_statistics(&scores, assessment.total_points)
        };

        // Fetch all answer details in a single batch query
        let all_details = self.submission_repo
            .get_all_answer_details_for_assessment(assessment_id)
            .await?;

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        // Build per-student-per-question data from batch results
        let mut student_question_correct: HashMap<(Uuid, Uuid), bool> = HashMap::new();
        let mut student_question_choices: HashMap<(Uuid, Uuid), Vec<(Option<Uuid>, bool)>> = HashMap::new();

        for detail in &all_details {
            let key = (detail.student_id, detail.question_id);
            // A question is correct if answer_points > 0
            student_question_correct
                .entry(key)
                .or_insert(detail.answer_points > 0.0);
            // Track choice selections for distractor analysis
            if let Some(choice_id) = detail.choice_id {
                student_question_choices
                    .entry(key)
                    .or_default()
                    .push((Some(choice_id), detail.item_is_correct));
            }
        }

        // Compute basic question stats from batch data
        let mut question_stats = Vec::new();
        for q in &questions {
            let mut correct_count = 0;
            let mut incorrect_count = 0;

            for s in &submitted {
                let key = (s.user_id, q.id);
                if let Some(&is_correct) = student_question_correct.get(&key) {
                    if is_correct {
                        correct_count += 1;
                    } else {
                        incorrect_count += 1;
                    }
                }
            }

            let total_answered = correct_count + incorrect_count;
            let correct_percentage = if total_answered > 0 {
                (correct_count as f64 / total_answered as f64) * 100.0
            } else {
                0.0
            };

            question_stats.push(QuestionStatistics {
                question_id: q.id,
                question_text: q.question_text.clone(),
                question_type: q.question_type.clone(),
                points: q.points,
                correct_count,
                incorrect_count,
                correct_percentage,
            });
        }

        // === ITEM ANALYSIS ===
        let (item_analysis, test_summary) = if submission_count >= 10 {
            self.compute_item_analysis(
                &questions,
                &submitted,
                &student_question_correct,
                &student_question_choices,
                submission_count,
            ).await?
        } else {
            (vec![], None)
        };

        Ok(AssessmentStatisticsResponse {
            assessment_id: assessment.id,
            title: assessment.title,
            total_points: assessment.total_points,
            submission_count,
            class_statistics,
            question_statistics: question_stats,
            item_analysis,
            test_summary,
        })
    }

    /// Compute item analysis using DepEd upper/lower 27% method.
    async fn compute_item_analysis(
        &self,
        questions: &[::entity::assessment_questions::Model],
        submitted: &[&::entity::assessment_submissions::Model],
        student_question_correct: &HashMap<(Uuid, Uuid), bool>,
        student_question_choices: &HashMap<(Uuid, Uuid), Vec<(Option<Uuid>, bool)>>,
        submission_count: usize,
    ) -> AppResult<(Vec<ItemAnalysis>, Option<TestSummary>)> {
        // Sort students by total_points descending
        let mut sorted_students: Vec<_> = submitted.iter().map(|s| (s.user_id, s.total_points)).collect();
        sorted_students.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

        // Compute group size: ceil(27% * N), minimum 3
        let n = (0.27 * submission_count as f64).ceil() as usize;
        let group_size = n.max(3);

        let upper_group: HashSet<Uuid> = sorted_students.iter().take(group_size).map(|(id, _)| *id).collect();
        let lower_group: HashSet<Uuid> = sorted_students.iter().rev().take(group_size).map(|(id, _)| *id).collect();

        let upper_size = upper_group.len() as f64;
        let lower_size = lower_group.len() as f64;

        // Fetch choices for MC questions (for distractor analysis)
        let mut question_choices: HashMap<Uuid, Vec<(Uuid, String, bool)>> = HashMap::new();
        for q in questions {
            if q.question_type == "multiple_choice" {
                let choices = self.assessment_repo
                    .find_choices_by_question_id(q.id).await?;
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
            // Count correct in upper and lower groups
            let mut ru = 0usize; // correct in upper
            let mut rl = 0usize; // correct in lower

            for &uid in &upper_group {
                let key = (uid, q.id);
                if let Some(&correct) = student_question_correct.get(&key) {
                    if correct {
                        ru += 1;
                    }
                }
            }
            for &uid in &lower_group {
                let key = (uid, q.id);
                if let Some(&correct) = student_question_correct.get(&key) {
                    if correct {
                        rl += 1;
                    }
                }
            }

            // Difficulty Index (p)
            let p = if upper_size + lower_size > 0.0 {
                (ru + rl) as f64 / (upper_size + lower_size)
            } else {
                0.0
            };

            // Discrimination Index (D)
            let d = if upper_size > 0.0 && lower_size > 0.0 {
                (ru as f64 / upper_size) - (rl as f64 / lower_size)
            } else {
                0.0
            };

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

            // Distractor analysis for MC questions
            let distractors = if q.question_type == "multiple_choice" {
                if let Some(choices) = question_choices.get(&q.id) {
                    let total_students = submission_count;
                    let mut distractor_results = Vec::new();

                    for (choice_id, choice_text, is_correct) in choices {
                        let mut upper_count = 0usize;
                        let mut lower_count = 0usize;
                        let mut total_selected = 0usize;

                        // Count selections across all students
                        for s in submitted.iter() {
                            let key = (s.user_id, q.id);
                            if let Some(selections) = student_question_choices.get(&key) {
                                for (sel_choice_id, _) in selections {
                                    if sel_choice_id.as_ref() == Some(choice_id) {
                                        total_selected += 1;
                                        if upper_group.contains(&s.user_id) {
                                            upper_count += 1;
                                        }
                                        if lower_group.contains(&s.user_id) {
                                            lower_count += 1;
                                        }
                                    }
                                }
                            }
                        }

                        let total_percentage = if total_students > 0 {
                            (total_selected as f64 / total_students as f64) * 100.0
                        } else {
                            0.0
                        };

                        // Effective: for incorrect choices, lower_count > upper_count
                        let is_effective = if *is_correct {
                            true // correct answer is always "effective"
                        } else {
                            lower_count > upper_count
                        };

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
                } else {
                    None
                }
            } else {
                None
            };

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
        } else {
            None
        };

        Ok((item_analyses, test_summary))
    }

    fn calculate_class_statistics(scores: &[f64], total_points: i32) -> ClassStatistics {
        let mut sorted_scores = scores.to_vec();
        sorted_scores.sort_by(|a, b| a.partial_cmp(b).unwrap());

        let mean = scores.iter().sum::<f64>() / scores.len() as f64;
        let median = if sorted_scores.len() % 2 == 0 {
            let mid = sorted_scores.len() / 2;
            (sorted_scores[mid - 1] + sorted_scores[mid]) / 2.0
        } else {
            sorted_scores[sorted_scores.len() / 2]
        };
        let highest = *sorted_scores.last().unwrap();
        let lowest = *sorted_scores.first().unwrap();

        let distribution = if total_points > 0 {
            use std::collections::HashMap;
            let mut score_map: HashMap<i32, usize> = HashMap::new();
            for &s in scores {
                *score_map.entry(s.floor() as i32).or_insert(0) += 1;
            }
            let mut buckets: Vec<ScoreBucket> = score_map.into_iter()
                .map(|(score, count)| ScoreBucket { score, count })
                .collect();
            buckets.sort_by_key(|b| b.score);
            buckets
        } else {
            Vec::new()
        };

        ClassStatistics {
            mean,
            median,
            highest,
            lowest,
            score_distribution: distribution,
        }
    }
}

// ===== ITEM ANALYSIS HELPERS =====

/// DepEd difficulty index labels
fn get_difficulty_label(p: f64) -> String {
    match p {
        p if p >= 0.80 => "Very Easy".to_string(),
        p if p >= 0.60 => "Easy".to_string(),
        p if p >= 0.40 => "Average".to_string(),
        p if p >= 0.20 => "Difficult".to_string(),
        _ => "Very Difficult".to_string(),
    }
}

/// DepEd discrimination index labels
fn get_discrimination_label(d: f64) -> String {
    match d {
        d if d >= 0.40 => "Very Good".to_string(),
        d if d >= 0.30 => "Good".to_string(),
        d if d >= 0.20 => "Needs Revision".to_string(),
        _ => "Discard".to_string(),
    }
}

/// DepEd verdict based on difficulty and discrimination
fn get_verdict(p: f64, d: f64) -> String {
    let p_in_range = p >= 0.20 && p <= 0.80;
    let d_good = d >= 0.30;

    if p_in_range && d_good {
        "retain".to_string()
    } else {
        // Check if slightly outside range (±0.03 tolerance)
        let p_near = p >= 0.17 && p <= 0.83;
        let d_near = d >= 0.27;

        if p_near && d_near {
            "revise".to_string()
        } else {
            "discard".to_string()
        }
    }
}
