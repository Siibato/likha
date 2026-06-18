use std::collections::HashMap;
use uuid::Uuid;
use crate::utils::error::{AppError, AppResult};
use crate::modules::assessment::schema::*;

impl crate::modules::assessment::service::AssessmentService {
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

        let submissions = self.assessment_repo
            .find_submitted_submissions_by_assessment_id(assessment_id).await?;
        let submission_count = submissions.len();

        let scores: Vec<f64> = submissions.iter().map(|s| s.total_points).collect();

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

        let all_details = self.assessment_repo
            .get_all_answer_details_for_assessment(assessment_id)
            .await?;

        tracing::debug!(
            assessment_id = %assessment_id,
            submissions_count = submission_count,
            all_details_len = all_details.len(),
            sample_answer_points = ?all_details.first().map(|d| d.answer_points),
            "get_statistics: fetched answer details"
        );

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        let mut student_question_correct: HashMap<(Uuid, Uuid), bool> =
            HashMap::with_capacity(all_details.len());
        let mut student_question_choices: HashMap<(Uuid, Uuid), Vec<(Option<Uuid>, bool)>> =
            HashMap::with_capacity(all_details.len());

        for detail in &all_details {
            let key = (detail.student_id, detail.question_id);
            student_question_correct
                .entry(key)
                .or_insert(detail.answer_points > 0.0);
            if let Some(choice_id) = detail.choice_id {
                student_question_choices
                    .entry(key)
                    .or_default()
                    .push((Some(choice_id), detail.item_is_correct));
            }
        }

        // Pre-aggregate correct/incorrect counts per question in O(details) instead of O(Q × S)
        let mut correct_counts: HashMap<Uuid, usize> = HashMap::with_capacity(questions.len());
        let mut incorrect_counts: HashMap<Uuid, usize> = HashMap::with_capacity(questions.len());
        for ((_, question_id), is_correct) in &student_question_correct {
            if *is_correct {
                *correct_counts.entry(*question_id).or_insert(0) += 1;
            } else {
                *incorrect_counts.entry(*question_id).or_insert(0) += 1;
            }
        }

        let mut question_stats = Vec::with_capacity(questions.len());
        for q in &questions {
            let correct_count = correct_counts.get(&q.id).copied().unwrap_or(0);
            let incorrect_count = incorrect_counts.get(&q.id).copied().unwrap_or(0);
            let total_answered = correct_count + incorrect_count;
            let correct_percentage = if total_answered > 0 {
                (correct_count as f64 / total_answered as f64) * 100.0
            } else { 0.0 };

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

        let (item_analysis, test_summary) = if submission_count >= 10 {
            self.compute_item_analysis(
                &questions,
                &submissions,
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
}
