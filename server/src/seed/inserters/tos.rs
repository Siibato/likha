use sea_orm::DatabaseConnection;

use crate::modules::tos::repository::TosRepository;
use crate::seed::specs::{CompetencySpec, TosSpec};
use crate::utils::AppError;

pub async fn insert_tos(db: &DatabaseConnection, specs: &[TosSpec]) -> Result<(), AppError> {
    let repo = TosRepository::new(db.clone());

    for spec in specs {
        repo.create_tos(
            spec.id,
            spec.class_id,
            spec.term_number,
            &spec.title,
            &spec.template_type,
            spec.total_items,
            &spec.time_limit_unit,
            spec.easy_percent,
            spec.average_percent,
            spec.difficult_percent,
            spec.remembering_percent,
            spec.understanding_percent,
            spec.applying_percent,
            spec.analyzing_percent,
            spec.evaluating_percent,
            spec.creating_percent,
        )
        .await?;
    }

    Ok(())
}

pub async fn insert_competencies(
    db: &DatabaseConnection,
    specs: &[CompetencySpec],
) -> Result<(), AppError> {
    let repo = TosRepository::new(db.clone());

    for spec in specs {
        repo.create_competency(
            spec.id,
            spec.tos_id,
            spec.code.as_deref(),
            &spec.text,
            spec.time_units_taught,
            spec.order,
            None, // easy_count
            None, // medium_count
            None, // hard_count
            None, // remembering_count
            None, // understanding_count
            None, // applying_count
            None, // analyzing_count
            None, // evaluating_count
            None, // creating_count
        )
        .await?;
    }

    Ok(())
}
