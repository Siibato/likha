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

        let class = self.class_repo.find_by_id(assessment.class_id).await?
            .ok_or_else(|| AppError::NotFound("Class not found".to_string()))?;

        if !self.class_repo.is_teacher_of_class(teacher_id, assessment.class_id).await? {
            return Err(AppError::Forbidden("Access denied".to_string()));
        }

        let submissions = self.submission_repo
            .find_by_assessment_id(assessment_id).await?;

        let submitted: Vec<_> = submissions.iter().filter(|s| s.is_submitted).collect();
        let submission_count = submitted.len();

        let scores: Vec<f64> = submitted.iter().map(|s| s.final_score).collect();

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

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        let mut question_stats = Vec::new();
        for q in questions {
            let mut correct_count = 0;
            let mut incorrect_count = 0;

            for s in &submitted {
                let answers = self.submission_repo
                    .find_answers_by_submission_id(s.id).await?;
                if let Some(a) = answers.iter().find(|a| a.question_id == q.id) {
                    let is_correct = a.is_override_correct.or(a.is_auto_correct).unwrap_or(false);
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
                question_text: q.question_text,
                question_type: q.question_type,
                points: q.points,
                correct_count,
                incorrect_count,
                correct_percentage,
            });
        }

        Ok(AssessmentStatisticsResponse {
            assessment_id: assessment.id,
            title: assessment.title,
            total_points: assessment.total_points,
            submission_count,
            class_statistics,
            question_statistics: question_stats,
        })
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

        let total = total_points as f64;
        let distribution = if total > 0.0 {
            let buckets = vec![
                ("0-20%", 0.0, 0.2),
                ("21-40%", 0.2, 0.4),
                ("41-60%", 0.4, 0.6),
                ("61-80%", 0.6, 0.8),
                ("81-100%", 0.8, 1.0),
            ];
            buckets.into_iter().map(|(range, low, high)| {
                let count = scores.iter().filter(|&&s| {
                    let pct = s / total;
                    pct >= low && (pct < high || (high == 1.0 && pct <= high))
                }).count();
                ScoreBucket {
                    range: range.to_string(),
                    count,
                }
            }).collect()
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