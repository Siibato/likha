use sea_orm::DatabaseConnection;
use uuid::Uuid;

use super::create_competency::create_competency;
use crate::utils::AppResult;
use ::entity::tos_competencies;

pub async fn bulk_create_competencies(
    db: &DatabaseConnection,
    tos_id: Uuid,
    competencies: Vec<(
        Option<Uuid>,
        Option<String>,
        String,
        i32,
        i32,
        Option<i32>,
        Option<i32>,
        Option<i32>,
        Option<i32>,
        Option<i32>,
        Option<i32>,
        Option<i32>,
        Option<i32>,
        Option<i32>,
    )>,
) -> AppResult<Vec<tos_competencies::Model>> {
    let mut results = Vec::new();
    for (id, code, text, units, order, easy, medium, hard, rem, und, app, ana, eva, cre) in
        competencies
    {
        let comp = create_competency(
            db,
            id.unwrap_or_else(Uuid::new_v4),
            tos_id,
            code.as_deref(),
            &text,
            units,
            order,
            easy,
            medium,
            hard,
            rem,
            und,
            app,
            ana,
            eva,
            cre,
        )
        .await?;
        results.push(comp);
    }
    Ok(results)
}
