use std::sync::Arc;

use crate::modules::grading::service::GradeComputationService;
use crate::modules::setup::service::SetupService;

pub struct DocumentExportService {
    pub grade_service: Arc<GradeComputationService>,
    pub setup_service: Arc<SetupService>,
}

impl DocumentExportService {
    pub fn new(
        grade_service: Arc<GradeComputationService>,
        setup_service: Arc<SetupService>,
    ) -> Self {
        Self {
            grade_service,
            setup_service,
        }
    }
}
