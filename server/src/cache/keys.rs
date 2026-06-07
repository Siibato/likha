use uuid::Uuid;

pub enum CacheKey {
    ClassListStudent(Uuid),
    ClassListTeacher(Uuid),
    ClassDetail(Uuid),
    AssignmentListStudent(Uuid),
    AssignmentListTeacher(Uuid),
    AssignmentDetailStudent(Uuid),
    AssignmentDetailTeacher(Uuid),
    AssessmentList(Uuid, Uuid),
    ClassMetadata(Uuid, String),
    DepedPresets,
}

impl CacheKey {
    pub fn as_str(&self) -> String {
        match self {
            CacheKey::ClassListStudent(id) => format!("class:list:student:{}", id),
            CacheKey::ClassListTeacher(id) => format!("class:list:teacher:{}", id),
            CacheKey::ClassDetail(id) => format!("class:detail:{}", id),
            CacheKey::AssignmentListStudent(id) => format!("assignment:list:student:{}", id),
            CacheKey::AssignmentListTeacher(id) => format!("assignment:list:teacher:{}", id),
            CacheKey::AssignmentDetailStudent(id) => format!("assignment:detail:{}:student", id),
            CacheKey::AssignmentDetailTeacher(id) => format!("assignment:detail:{}:teacher", id),
            CacheKey::AssessmentList(user_id, class_id) => format!("assessment:list:{}:{}", user_id, class_id),
            CacheKey::ClassMetadata(id, role) => format!("metadata:classes:{}:{}", id, role),
            CacheKey::DepedPresets => "config:deped_presets".to_string(),
        }
    }
}
