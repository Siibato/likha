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
            .find_submissions_by_assessment_id(assessment_id).await?;

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

        let all_details = self.assessment_repo
            .get_all_answer_details_for_assessment(assessment_id)
            .await?;

        let questions = self.assessment_repo
            .find_questions_by_assessment_id(assessment_id).await?;

        let mut student_question_correct: HashMap<(Uuid, Uuid), bool> = HashMap::new();
        let mut student_question_choices: HashMap<(Uuid, Uuid), Vec<(Option<Uuid>, bool)>> = HashMap::new();

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

        let mut question_stats = Vec::new();
        for q in &questions {
            let mut correct_count = 0;
            let mut incorrect_count = 0;

            for s in &submitted {
                let key = (s.user_id, q.id);
                if let Some(&is_correct) = student_question_correct.get(&key) {
                    if is_correct { correct_count += 1; } else { incorrect_count += 1; }
                }
            }

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
}
