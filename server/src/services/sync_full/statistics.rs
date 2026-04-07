use serde_json::{json, Value};
use std::collections::HashMap;

/// Computes per-assessment statistics (mean, median, high/low, score distribution).
/// Teacher/admin only — not called for students.
pub fn compute_assessment_statistics(
    assessments: &[Value],
    enriched_submissions: &[Value],
) -> Vec<Value> {
    let mut stats = Vec::new();

    // Build submission map: assessment_id -> submissions
    let mut submissions_by_assessment: HashMap<String, Vec<&Value>> = HashMap::new();
    for sub in enriched_submissions {
        if let Some(ass_id) = sub.get("assessment_id").and_then(|v| v.as_str()) {
            submissions_by_assessment.entry(ass_id.to_string()).or_insert_with(Vec::new).push(sub);
        }
    }

    for assessment in assessments {
        let assessment_id = assessment.get("id").and_then(|v| v.as_str()).unwrap_or("");
        let title = assessment.get("title").and_then(|v| v.as_str()).unwrap_or("");
        let total_points = assessment.get("total_points").and_then(|v| v.as_i64()).unwrap_or(0) as f64;

        let empty_vec = vec![];
        let submissions = submissions_by_assessment.get(assessment_id).unwrap_or(&empty_vec);

        // Filter submitted submissions
        let submitted: Vec<&Value> = submissions.iter()
            .filter(|s| s.get("is_submitted").and_then(|v| v.as_u64()).unwrap_or(0) == 1)
            .copied()
            .collect();

        if submitted.is_empty() {
            continue; // Skip if no submitted submissions
        }

        // Extract scores
        let mut scores: Vec<f64> = submitted.iter()
            .filter_map(|s| {
                s.get("final_score")
                    .and_then(|v| v.as_f64())
                    .or_else(|| s.get("auto_score").and_then(|v| v.as_f64()))
            })
            .collect();
        scores.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));

        // Compute statistics
        let mean = scores.iter().sum::<f64>() / scores.len() as f64;
        let median = if scores.len() % 2 == 0 {
            (scores[scores.len() / 2 - 1] + scores[scores.len() / 2]) / 2.0
        } else {
            scores[scores.len() / 2]
        };
        let highest = scores.last().copied().unwrap_or(0.0);
        let lowest = scores.first().copied().unwrap_or(0.0);

        // Score distribution by individual point values
        let mut score_map: std::collections::HashMap<i64, usize> = std::collections::HashMap::new();
        for score in &scores {
            *score_map.entry(score.floor() as i64).or_insert(0) += 1;
        }
        let mut distribution: Vec<(i64, usize)> = score_map.into_iter().collect();
        distribution.sort_by_key(|b| b.0);

        stats.push(json!({
            "assessment_id": assessment_id,
            "title": title,
            "total_points": total_points as i64,
            "submission_count": submitted.len(),
            "class_statistics": {
                "mean": mean,
                "median": median,
                "highest": highest,
                "lowest": lowest,
                "score_distribution": distribution.iter().map(|(score, count)| {
                    json!({"score": score, "count": count})
                }).collect::<Vec<_>>()
            },
            "question_statistics": []
        }));
    }

    stats
}

/// Formats submission results for student view.
/// Student only — not called for teachers/admins.
pub fn format_student_results(
    enriched_submissions: &[Value],
    assessments: &[Value],
) -> Vec<Value> {
    let mut results = Vec::new();

    // Build assessment map: assessment_id -> total_points
    let mut assessment_map: HashMap<String, i64> = HashMap::new();
    for assessment in assessments {
        if let Some(ass_id) = assessment.get("id").and_then(|v| v.as_str()) {
            let total_points = assessment.get("total_points").and_then(|v| v.as_i64()).unwrap_or(0);
            assessment_map.insert(ass_id.to_string(), total_points);
        }
    }

    for submission in enriched_submissions {
        if submission.get("is_submitted").and_then(|v| v.as_u64()).unwrap_or(0) != 1 {
            continue; // Skip unsubmitted
        }

        let submission_id = submission.get("id").and_then(|v| v.as_str()).unwrap_or("");
        let assessment_id = submission.get("assessment_id").and_then(|v| v.as_str()).unwrap_or("");
        let total_points = assessment_map.get(assessment_id).copied().unwrap_or(0);
        let auto_score = submission.get("auto_score").and_then(|v| v.as_f64()).unwrap_or(0.0);
        let _final_score = submission.get("final_score").and_then(|v| v.as_f64()).unwrap_or(auto_score);
        let submitted_at = submission.get("submitted_at").and_then(|v| v.as_str()).unwrap_or("");

        // Transform answers: convert selected_choices from [object] to [string]
        let mut answers_json = Vec::new();
        if let Some(answers) = submission.get("answers").and_then(|v| v.as_array()) {
            for answer in answers {
                let mut ans_obj = answer.clone();

                // Extract choice_text from selected_choices objects
                if let Some(choices) = ans_obj.get("selected_choices").and_then(|v| v.as_array()) {
                    let choice_texts: Vec<Value> = choices.iter()
                        .filter_map(|c| c.get("choice_text").cloned())
                        .collect();
                    ans_obj["selected_choices"] = json!(choice_texts);
                }

                // Ensure correct_answers is an empty array if not present
                if !ans_obj.get("correct_answers").is_some() {
                    ans_obj["correct_answers"] = json!([]);
                }

                answers_json.push(ans_obj);
            }
        }

        results.push(json!({
            "submission_id": submission_id,
            "total_earned": auto_score,
            "total_possible": total_points,
            "submitted_at": submitted_at,
            "answers": answers_json
        }));
    }

    results
}
