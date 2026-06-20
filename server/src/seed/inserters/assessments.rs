use sea_orm::{ActiveModelTrait, DatabaseConnection, EntityTrait, Set};
use uuid::Uuid;

use crate::utils::AppError;
use crate::modules::assessment::repository::AssessmentRepository;
use crate::seed::specs::{AssessmentSpec, QuestionSpec};
use ::entity::{answer_key_acceptable_answers, answer_keys, assessment_questions};

pub async fn insert_assessment_with_questions(
    db: &DatabaseConnection,
    spec: &AssessmentSpec,
) -> Result<(), AppError> {
    let repo = AssessmentRepository::new(db.clone());
    let created_at = spec.created_at;

    repo.create_assessment(
        spec.class_id,
        spec.title.clone(),
        spec.description.clone(),
        spec.time_limit_minutes,
        spec.open_at,
        spec.close_at,
        spec.show_results_immediately,
        spec.total_points,
        Some(spec.id),
        false, // allow_retake
        Some(spec.term_number),
        Some(spec.component.clone()),
        Some(spec.tos_id.to_string()),
    )
    .await?;

    let assessment = ::entity::assessments::Entity::find_by_id(spec.id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?
        .ok_or_else(|| AppError::NotFound(format!("Assessment {} not found", spec.id)))?;
    let mut am: ::entity::assessments::ActiveModel = assessment.into();
    am.created_at = Set(created_at);
    am.updated_at = Set(created_at);
    am.update(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

    for q_spec in &spec.questions {
        insert_question_with_choices_and_key(db, spec.id, q_spec).await?;
    }

    if spec.is_published && spec.deleted_at.is_none() {
        repo.update_total_points(spec.id).await?;
        repo.publish_assessment(spec.id).await?;

        if spec.results_released {
            repo.release_results(spec.id).await?;
        }
    }

    if let Some(deleted_at) = spec.deleted_at {
        let assessment = ::entity::assessments::Entity::find_by_id(spec.id)
            .one(db)
            .await
            .map_err(|e| AppError::InternalServerError(e.to_string()))?
            .ok_or_else(|| AppError::NotFound(format!("Assessment {} not found", spec.id)))?;
        let mut am: ::entity::assessments::ActiveModel = assessment.into();
        am.deleted_at = Set(Some(deleted_at));
        am.update(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
    }

    Ok(())
}

async fn insert_question_with_choices_and_key(
    db: &DatabaseConnection,
    assessment_id: Uuid,
    spec: &QuestionSpec,
) -> Result<(), AppError> {
    let repo = AssessmentRepository::new(db.clone());

    repo.add_question(
        assessment_id,
        spec.question_type.clone(),
        spec.text.clone(),
        spec.points,
        spec.order,
        spec.is_multi_select,
        Some(spec.id),
    )
    .await?;

    let question = assessment_questions::Entity::find_by_id(spec.id)
        .one(db)
        .await
        .map_err(|e| AppError::InternalServerError(e.to_string()))?
        .ok_or_else(|| AppError::NotFound(format!("Question {} not found", spec.id)))?;

    let mut qam: assessment_questions::ActiveModel = question.into();
    qam.tos_competency_id = Set(spec.tos_competency_id);
    qam.difficulty = Set(spec.difficulty.clone());
    qam.cognitive_level = Set(spec.cognitive_level.clone());
    qam.update(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

    if spec.question_type == "multiple_choice" {
        for choice in &spec.choices {
            repo.add_choice(spec.id, choice.text.clone(), choice.is_correct, choice.order, Some(choice.id))
                .await?;
        }
    }

    if !spec.answer_key.acceptable_answers.is_empty() || spec.question_type == "essay" {
        let ak = answer_keys::ActiveModel {
            id: Set(Uuid::new_v4()),
            question_id: Set(spec.id),
        };
        let inserted_ak = ak.insert(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;

        for answer_text in &spec.answer_key.acceptable_answers {
            let acc = answer_key_acceptable_answers::ActiveModel {
                id: Set(Uuid::new_v4()),
                answer_key_id: Set(inserted_ak.id),
                answer_text: Set(answer_text.clone()),
            };
            acc.insert(db).await.map_err(|e| AppError::InternalServerError(e.to_string()))?;
        }
    }

    Ok(())
}
