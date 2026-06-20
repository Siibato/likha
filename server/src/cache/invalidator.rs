use std::sync::Arc;
use uuid::Uuid;

use super::redis::RedisCache;
use super::keys::CacheKey;

#[derive(Clone)]
pub struct CacheInvalidator {
    cache: Arc<RedisCache>,
}

impl CacheInvalidator {
    pub fn new(cache: Arc<RedisCache>) -> Self {
        Self { cache }
    }

    pub async fn invalidate_class(&self, class_id: Uuid) {
        let keys = vec![
            CacheKey::ClassDetail(class_id).as_str(),
            CacheKey::ClassMetadata(class_id, "teacher".to_string()).as_str(),
            CacheKey::ClassMetadata(class_id, "student".to_string()).as_str(),
        ];
        self.cache.del_keys(keys).await;
    }

    pub async fn invalidate_student_classes(&self, student_id: Uuid) {
        self.cache.del(&CacheKey::ClassListStudent(student_id).as_str()).await;
        self.cache.del(&CacheKey::ClassMetadata(student_id, "student".to_string()).as_str()).await;
    }

    pub async fn invalidate_teacher_classes(&self, teacher_id: Uuid) {
        self.cache.del(&CacheKey::ClassListTeacher(teacher_id).as_str()).await;
        self.cache.del(&CacheKey::ClassMetadata(teacher_id, "teacher".to_string()).as_str()).await;
    }

    pub async fn invalidate_student_assignments(&self, student_id: Uuid) {
        self.cache.del(&CacheKey::AssignmentListStudent(student_id).as_str()).await;
    }

    pub async fn invalidate_teacher_assignments(&self, teacher_id: Uuid) {
        self.cache.del(&CacheKey::AssignmentListTeacher(teacher_id).as_str()).await;
    }

    pub async fn invalidate_assessments(&self, user_id: Uuid, class_id: Uuid) {
        self.cache.del(&CacheKey::AssessmentList(user_id, class_id).as_str()).await;
    }

    pub async fn invalidate_assignment_detail(&self, assignment_id: Uuid) {
        let keys = vec![
            CacheKey::AssignmentDetailStudent(assignment_id).as_str(),
            CacheKey::AssignmentDetailTeacher(assignment_id).as_str(),
        ];
        self.cache.del_keys(keys).await;
    }

    pub async fn invalidate_class_participants(&self, class_id: Uuid) {
        self.cache.del(&CacheKey::ClassParticipants(class_id).as_str()).await;
    }

    pub async fn invalidate_class_and_enrolled(&self, class_id: Uuid) {
        self.invalidate_class(class_id).await;
        self.invalidate_class_participants(class_id).await;
    }

    // ─── Grading ──────────────────────────────────────────────────────────────

    pub async fn invalidate_class_grades(&self, class_id: Uuid, period: i32) {
        let keys = vec![
            CacheKey::GradeItems(class_id, period).as_str(),
            CacheKey::PeriodGrades(class_id, period).as_str(),
            CacheKey::GradeSummary(class_id, period).as_str(),
        ];
        self.cache.del_keys(keys).await;
    }

    pub async fn invalidate_student_grades(&self, class_id: Uuid, student_id: Uuid, period: i32) {
        let keys = vec![
            CacheKey::StudentPeriodGrade(class_id, student_id, period).as_str(),
            CacheKey::StudentAllGrades(class_id, student_id).as_str(),
            CacheKey::FinalGrade(class_id, student_id).as_str(),
            CacheKey::SF9(class_id, student_id).as_str(),
        ];
        self.cache.del_keys(keys).await;
    }

    pub async fn invalidate_all_class_grades(&self, class_id: Uuid) {
        let keys = vec![
            CacheKey::GeneralAverages(class_id).as_str(),
        ];
        self.cache.del_keys(keys).await;
    }

    pub async fn invalidate_item_scores(&self, item_id: Uuid) {
        self.cache.del(&CacheKey::ItemScores(item_id).as_str()).await;
    }

    // ─── Assessment ───────────────────────────────────────────────────────────

    pub async fn invalidate_assessment_detail(&self, assessment_id: Uuid) {
        let keys = vec![
            CacheKey::AssessmentDetail(assessment_id, "teacher".to_string()).as_str(),
            CacheKey::AssessmentDetail(assessment_id, "student".to_string()).as_str(),
        ];
        self.cache.del_keys(keys).await;
    }

    pub async fn invalidate_assessment_submissions(&self, assessment_id: Uuid) {
        self.cache.del(&CacheKey::AssessmentSubmissions(assessment_id).as_str()).await;
    }

    pub async fn invalidate_assessment_submission_detail(&self, submission_id: Uuid) {
        self.cache.del(&CacheKey::AssessmentSubmissionDetail(submission_id).as_str()).await;
    }

    pub async fn invalidate_student_results(&self, submission_id: Uuid) {
        self.cache.del(&CacheKey::StudentResults(submission_id).as_str()).await;
    }

    pub async fn invalidate_assessment_student_submission(&self, assessment_id: Uuid, student_id: Uuid) {
        self.cache.del(&CacheKey::AssessmentStudentSubmission(assessment_id, student_id).as_str()).await;
    }

    pub async fn invalidate_student_assessment_submissions(&self, class_id: Uuid, student_id: Uuid) {
        self.cache.del(&CacheKey::StudentAssessmentSubmissions(class_id, student_id).as_str()).await;
    }

    // ─── Assignment ────────────────────────────────────────────────────────────

    pub async fn invalidate_class_assignments(&self, _class_id: Uuid) {
        // AssignmentListByClass uses a composite key; we can't efficiently wildcard-delete.
        // For now, rely on TTL eviction. If needed, implement Redis KEYS scan in the future.
    }

    // ─── Auth ─────────────────────────────────────────────────────────────────

    pub async fn invalidate_user_profile(&self, user_id: Uuid) {
        self.cache.del(&CacheKey::UserProfile(user_id).as_str()).await;
    }

    // ─── TOS ────────────────────────────────────────────────────────────────────

    pub async fn invalidate_tos_list(&self, class_id: Uuid) {
        self.cache.del(&CacheKey::TosList(class_id).as_str()).await;
    }

    pub async fn invalidate_tos_detail(&self, tos_id: Uuid) {
        self.cache.del(&CacheKey::TosDetail(tos_id).as_str()).await;
    }

    // ─── Learning Material ──────────────────────────────────────────────────────

    pub async fn invalidate_material_list(&self, class_id: Uuid) {
        self.cache.del(&CacheKey::MaterialList(class_id).as_str()).await;
    }

    pub async fn invalidate_material_detail(&self, material_id: Uuid) {
        self.cache.del(&CacheKey::MaterialDetail(material_id).as_str()).await;
    }

    // ─── Setup ─────────────────────────────────────────────────────────────────

    pub async fn invalidate_school_info(&self) {
        self.cache.del(&CacheKey::SchoolInfo.as_str()).await;
    }

    pub async fn invalidate_school_details(&self) {
        self.cache.del(&CacheKey::SchoolDetails.as_str()).await;
    }

    pub async fn invalidate_school_code(&self) {
        self.cache.del(&CacheKey::SchoolCode.as_str()).await;
    }
}
