use serde::Serialize;
use uuid::Uuid;

use crate::seed::specs::{AssessmentSpec, AssignmentSpec, ClassSpec, UserSpec};

#[derive(Debug, Serialize)]
pub struct ManifestUser {
    pub id: Uuid,
    pub username: String,
    pub role: String,
    pub full_name: String,
}

#[derive(Debug, Serialize)]
pub struct ManifestClass {
    pub id: Uuid,
    pub title: String,
    pub grade_level: Option<String>,
    pub is_deleted: bool,
}

#[derive(Debug, Serialize)]
pub struct ManifestAssessment {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub total_points: i32,
    pub is_published: bool,
    pub grading_period_number: i32,
    pub question_ids: Vec<Uuid>,
}

#[derive(Debug, Serialize)]
pub struct ManifestAssignment {
    pub id: Uuid,
    pub class_id: Uuid,
    pub title: String,
    pub total_points: i32,
    pub is_published: bool,
    pub grading_period_number: i32,
}

#[derive(Debug, Serialize)]
pub struct SeedManifest {
    pub users: Vec<ManifestUser>,
    pub classes: Vec<ManifestClass>,
    pub assessments: Vec<ManifestAssessment>,
    pub assignments: Vec<ManifestAssignment>,
}

pub fn build_manifest(
    users: &[UserSpec],
    classes: &[ClassSpec],
    assessments: &[AssessmentSpec],
    assignments: &[AssignmentSpec],
) -> SeedManifest {
    SeedManifest {
        users: users
            .iter()
            .filter(|u| u.deleted_at.is_none())
            .map(|u| ManifestUser {
                id: u.id,
                username: u.username.clone(),
                role: u.role.clone(),
                full_name: u.full_name.clone(),
            })
            .collect(),

        classes: classes
            .iter()
            .map(|c| ManifestClass {
                id: c.id,
                title: c.title.clone(),
                grade_level: c.grade_level.clone(),
                is_deleted: c.deleted_at.is_some(),
            })
            .collect(),

        assessments: assessments
            .iter()
            .filter(|a| a.deleted_at.is_none())
            .map(|a| ManifestAssessment {
                id: a.id,
                class_id: a.class_id,
                title: a.title.clone(),
                total_points: a.total_points,
                is_published: a.is_published,
                grading_period_number: a.grading_period_number,
                question_ids: a.questions.iter().map(|q| q.id).collect(),
            })
            .collect(),

        assignments: assignments
            .iter()
            .filter(|a| a.deleted_at.is_none())
            .map(|a| ManifestAssignment {
                id: a.id,
                class_id: a.class_id,
                title: a.title.clone(),
                total_points: a.total_points,
                is_published: a.is_published,
                grading_period_number: a.grading_period_number,
            })
            .collect(),
    }
}

pub fn export_manifest(manifest: &SeedManifest, path: &str) -> Result<(), Box<dyn std::error::Error>> {
    let json = serde_json::to_string_pretty(manifest)?;
    std::fs::write(path, json)?;
    println!("Seed manifest exported to: {}", path);
    Ok(())
}
