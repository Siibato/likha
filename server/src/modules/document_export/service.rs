use std::sync::Arc;

use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;
use crate::modules::student_records::service::StudentRecordsService;

pub struct DocumentExportService {
    pub grade_service: Arc<GradeComputationService>,
    pub setup_service: Arc<SetupService>,
    pub student_records_service: Arc<StudentRecordsService>,
}

impl DocumentExportService {
    pub fn new(
        grade_service: Arc<GradeComputationService>,
        setup_service: Arc<SetupService>,
        student_records_service: Arc<StudentRecordsService>,
    ) -> Self {
        Self {
            grade_service,
            setup_service,
            student_records_service,
        }
    }
}
