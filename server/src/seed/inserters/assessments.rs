use sea_orm::{DatabaseConnection, EntityTrait, Set};
use uuid::Uuid;

use crate::seed::specs::AssessmentSpec;
use crate::utils::AppError;
use ::entity::{
    answer_key_acceptable_answers, answer_keys, assessment_questions, assessments,
    question_choices,
};

const CHUNK_SIZE: usize = 100;

pub async fn insert_assessments_with_questions(
    db: &DatabaseConnection,
    specs: &[AssessmentSpec],
) -> Result<(), AppError> {
    if specs.is_empty() {
        return Ok(());
    }

    let now = chrono::Utc::now().naive_utc();

    let mut assessment_models: Vec<assessments::ActiveModel> = Vec::new();
    let mut question_models: Vec<assessment_questions::ActiveModel> = Vec::new();
    let mut choice_models: Vec<question_choices::ActiveModel> = Vec::new();
    let mut answer_key_models: Vec<answer_keys::ActiveModel> = Vec::new();
    let mut acceptable_answer_models: Vec<answer_key_acceptable_answers::ActiveModel> =
        Vec::new();

    for spec in specs {
        let total_points: i32 = spec.questions.iter().map(|q| q.points).sum();

        assessment_models.push(assessments::ActiveModel {
            id: Set(spec.id),
            class_id: Set(spec.class_id),
            title: Set(spec.title.clone()),
            description: Set(spec.description.clone()),
            time_limit_minutes: Set(spec.time_limit_minutes),
            open_at: Set(spec.open_at),
            close_at: Set(spec.close_at),
            show_results_immediately: Set(spec.show_results_immediately),
            results_released: Set(spec.results_released && spec.is_published && spec.deleted_at.is_none()),
            is_published: Set(spec.is_published && spec.deleted_at.is_none()),
            order_index: Set(spec.total_points),
            total_points: Set(total_points),
            created_at: Set(spec.created_at),
            updated_at: Set(spec.created_at),
            deleted_at: Set(spec.deleted_at),
            term_number: Set(Some(spec.term_number)),
            component: Set(Some(spec.component.clone())),
            tos_id: Set(Some(spec.tos_id)),
        });

        for q_spec in &spec.questions {
            question_models.push(assessment_questions::ActiveModel {
                id: Set(q_spec.id),
                assessment_id: Set(spec.id),
                question_type: Set(q_spec.question_type.clone()),
                question_text: Set(q_spec.text.clone()),
                points: Set(q_spec.points),
                order_index: Set(q_spec.order),
                is_multi_select: Set(q_spec.is_multi_select),
                created_at: Set(now),
                updated_at: Set(now),
                deleted_at: Set(None),
                tos_competency_id: Set(q_spec.tos_competency_id),
                cognitive_level: Set(q_spec.cognitive_level.clone()),
                difficulty: Set(q_spec.difficulty.clone()),
            });

            if q_spec.question_type == "multiple_choice" {
                for choice in &q_spec.choices {
                    choice_models.push(question_choices::ActiveModel {
                        id: Set(choice.id),
                        question_id: Set(q_spec.id),
                        choice_text: Set(choice.text.clone()),
                        is_correct: Set(choice.is_correct),
                        order_index: Set(choice.order),
                        updated_at: Set(now),
                    });
                }
            }

            if !q_spec.answer_key.acceptable_answers.is_empty() || q_spec.question_type == "essay" {
                let ak_id = Uuid::new_v4();
                answer_key_models.push(answer_keys::ActiveModel {
                    id: Set(ak_id),
                    question_id: Set(q_spec.id),
                    updated_at: Set(now),
                });

                for answer_text in &q_spec.answer_key.acceptable_answers {
                    acceptable_answer_models.push(answer_key_acceptable_answers::ActiveModel {
                        id: Set(Uuid::new_v4()),
                        answer_key_id: Set(ak_id),
                        answer_text: Set(answer_text.clone()),
                    });
                }
            }
        }
    }

    for chunk in assessment_models.chunks(CHUNK_SIZE) {
        assessments::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    for chunk in question_models.chunks(CHUNK_SIZE) {
        assessment_questions::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    for chunk in choice_models.chunks(CHUNK_SIZE) {
        question_choices::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    for chunk in answer_key_models.chunks(CHUNK_SIZE) {
        answer_keys::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    for chunk in acceptable_answer_models.chunks(CHUNK_SIZE) {
        answer_key_acceptable_answers::Entity::insert_many(chunk.iter().cloned())
            .exec(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}
