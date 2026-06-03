use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
    pub(super) fn calculate_class_statistics(scores: &[f64], total_points: i32) -> ClassStatistics {
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
