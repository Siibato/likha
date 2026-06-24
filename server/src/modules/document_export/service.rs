use std::sync::Arc;

use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;
use crate::modules::student_records::service::StudentRecordsService;
use crate::modules::tos::service::TosService;

pub struct DocumentExportService {
    pub grade_service: Arc<GradeComputationService>,
    pub setup_service: Arc<SetupService>,
    pub student_records_service: Arc<StudentRecordsService>,
    pub tos_service: Arc<TosService>,
}

impl DocumentExportService {
    pub fn new(
        grade_service: Arc<GradeComputationService>,
        setup_service: Arc<SetupService>,
        student_records_service: Arc<StudentRecordsService>,
        tos_service: Arc<TosService>,
    ) -> Self {
        Self {
            grade_service,
            setup_service,
            student_records_service,
            tos_service,
        }
    }
}
